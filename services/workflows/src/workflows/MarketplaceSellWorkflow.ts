import {
  proxyActivities,
  defineSignal,
  setHandler,
  condition,
  sleep,
} from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const {
  identifyItem,
  findComparables,
  createListingDraft,
  postListing,
  checkMessageRisk,
  sendBuyerMessage,
  schedulePickup,
  emitTaskEvent,
  requestApproval,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '10 minutes',
  retry: {
    maximumAttempts: 3,
  },
});

export interface MarketplaceSellInput {
  workspaceId: string;
  userId: string;
  photos: string[];
  userDescription?: string;
}

export interface ApprovalSignal {
  envelopeId: string;
  approved: boolean;
  token?: string;
  reason?: string;
}

export interface ListingApprovalSignal {
  approved: boolean;
  modifications?: {
    price?: number;
    title?: string;
    description?: string;
  };
}

export interface BuyerMessageSignal {
  messageId: string;
  buyerId: string;
  content: string;
}

export const approvalSignal = defineSignal<[ApprovalSignal]>('approval');
export const listingApprovalSignal = defineSignal<[ListingApprovalSignal]>('listingApproval');
export const buyerMessageSignal = defineSignal<[BuyerMessageSignal]>('buyerMessage');

export async function MarketplaceSellWorkflow(input: MarketplaceSellInput): Promise<{
  success: boolean;
  listingId?: string;
  listingUrl?: string;
  soldPrice?: number;
}> {
  const { workspaceId, userId, photos, userDescription } = input;
  let pendingApproval: ApprovalSignal | null = null;
  let listingApproval: ListingApprovalSignal | null = null;
  const messageQueue: BuyerMessageSignal[] = [];

  setHandler(approvalSignal, (signal) => {
    pendingApproval = signal;
  });

  setHandler(listingApprovalSignal, (signal) => {
    listingApproval = signal;
  });

  setHandler(buyerMessageSignal, (signal) => {
    messageQueue.push(signal);
  });

  // Step 1: Identify item from photos
  await emitTaskEvent(workspaceId, 'marketplace.phase', { phase: 'identifying' });
  const itemInfo = await identifyItem({
    workspaceId,
    photos,
    userDescription,
  });

  // Step 2: Find comparables and suggest price
  await emitTaskEvent(workspaceId, 'marketplace.phase', { phase: 'pricing' });
  const comparables = await findComparables({
    workspaceId,
    itemName: itemInfo.name,
    brand: itemInfo.brand,
    condition: itemInfo.condition,
  });

  // Step 3: Create listing draft
  await emitTaskEvent(workspaceId, 'marketplace.phase', { phase: 'drafting' });
  const draft = await createListingDraft({
    workspaceId,
    itemInfo,
    comparables,
    photos,
  });

  // Step 4: Get user approval for listing (HIGH risk - public post)
  await emitTaskEvent(workspaceId, 'marketplace.draft', { draft });

  const postEnvelopeId = await requestApproval({
    workspaceId,
    userId,
    intent: `Post "${draft.title}" for $${draft.price} on Facebook Marketplace`,
    toolName: 'marketplace.post_listing',
    inputs: draft as unknown as Record<string, unknown>,
    riskLevel: 'high',
  });

  const postApproved = await condition(
    () => pendingApproval?.envelopeId === postEnvelopeId,
    '24 hours'
  );

  const postApprovalState = pendingApproval as ApprovalSignal | null;
  if (!postApproved || !postApprovalState?.approved) {
    return { success: false };
  }

  // Step 5: Post listing
  await emitTaskEvent(workspaceId, 'marketplace.phase', { phase: 'posting' });
  const listing = await postListing({
    workspaceId,
    draft,
    idempotencyKey: `listing-${workspaceId}-${Date.now()}`,
  });

  await emitTaskEvent(workspaceId, 'marketplace.listed', {
    listingId: listing.listingId,
    url: listing.url,
  });

  // Step 6: Message handling loop
  let sold = false;
  let soldPrice: number | undefined;

  while (!sold) {
    // Wait for a buyer message or timeout
    const hasMessage = await condition(
      () => messageQueue.length > 0,
      '7 days' // Listing active for 7 days
    );

    if (!hasMessage) {
      break;
    }

    const message = messageQueue.shift()!;

    // Check for scam patterns
    const riskCheck = await checkMessageRisk({
      workspaceId,
      buyerId: message.buyerId,
      content: message.content,
    });

    if (riskCheck.isScam) {
      await emitTaskEvent(workspaceId, 'marketplace.scam_detected', {
        buyerId: message.buyerId,
        reason: riskCheck.reason,
      });
      continue;
    }

    // Determine response
    if (riskCheck.intent === 'purchase') {
      // Request approval for address sharing if needed
      if (riskCheck.requiresAddressSharing) {
        const addressEnvelopeId = await requestApproval({
          workspaceId,
          userId,
          intent: `Share pickup address with buyer`,
          toolName: 'marketplace.message_buyer',
          inputs: { includeAddress: true },
          riskLevel: 'high',
        });

        pendingApproval = null;
        const addressApproved = await condition(
          () => pendingApproval?.envelopeId === addressEnvelopeId,
          '2 hours'
        );

        const addressApprovalState = pendingApproval as ApprovalSignal | null;
        if (!addressApproved || !addressApprovalState?.approved) {
          continue;
        }
      }

      // Schedule pickup
      const pickup = await schedulePickup({
        workspaceId,
        userId,
        buyerId: message.buyerId,
        proposedTimes: riskCheck.proposedTimes ?? [],
      });

      await sendBuyerMessage({
        workspaceId,
        listingId: listing.listingId,
        buyerId: message.buyerId,
        message: pickup.confirmationMessage,
        idempotencyKey: `msg-${message.messageId}`,
      });

      sold = true;
      soldPrice = draft.price;
    }
  }

  await emitTaskEvent(workspaceId, 'marketplace.complete', {
    sold,
    soldPrice,
  });

  return {
    success: sold,
    listingId: listing.listingId,
    listingUrl: listing.url,
    soldPrice,
  };
}
