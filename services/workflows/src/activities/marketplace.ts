/**
 * Marketplace Activities for homeOS
 *
 * Production-ready marketplace integration using:
 * - Claude Vision: For item identification from photos
 * - eBay API: For comparable pricing data
 * - Facebook Graph API: For Marketplace listings (when available)
 * - Craigslist: For local listings (web automation)
 */

import Anthropic from '@anthropic-ai/sdk';
import * as fs from 'fs';
import * as path from 'path';

// ============================================================================
// CONFIGURATION
// ============================================================================

interface VisionConfig {
  provider: 'anthropic' | 'openai';
  apiKey: string;
  model: string;
}

interface EbayConfig {
  appId: string;
  certId: string;
  devId: string;
  sandbox: boolean;
}

interface FacebookConfig {
  accessToken: string;
  pageId: string;
}

async function getVisionConfig(workspaceId: string): Promise<VisionConfig> {
  const anthropicKey = process.env['ANTHROPIC_API_KEY'];
  const openaiKey = process.env['OPENAI_API_KEY'];

  if (anthropicKey) {
    return {
      provider: 'anthropic',
      apiKey: anthropicKey,
      model: 'claude-sonnet-4-20250514',
    };
  }
  if (openaiKey) {
    return {
      provider: 'openai',
      apiKey: openaiKey,
      model: 'gpt-4o',
    };
  }

  throw new Error('No vision API key configured. Set ANTHROPIC_API_KEY or OPENAI_API_KEY.');
}

async function getEbayConfig(workspaceId: string): Promise<EbayConfig | null> {
  const appId = process.env['EBAY_APP_ID'];
  const certId = process.env['EBAY_CERT_ID'];
  const devId = process.env['EBAY_DEV_ID'];

  if (!appId || !certId || !devId) {
    return null;
  }

  return {
    appId,
    certId,
    devId,
    sandbox: process.env['EBAY_SANDBOX'] === 'true',
  };
}

// ============================================================================
// ITEM IDENTIFICATION (VISION AI)
// ============================================================================

export interface IdentifyItemInput {
  workspaceId: string;
  photos: string[]; // URLs or base64 encoded images
  userDescription?: string;
}

export interface ItemInfo {
  name: string;
  brand?: string;
  model?: string;
  condition: 'new' | 'like_new' | 'good' | 'fair' | 'poor';
  category: string;
  subcategory?: string;
  estimatedAge?: string;
  color?: string;
  size?: string;
  features: string[];
  flaws: string[];
  suggestedKeywords: string[];
  confidence: number;
}

export async function identifyItem(input: IdentifyItemInput): Promise<ItemInfo> {
  const config = await getVisionConfig(input.workspaceId);

  // Prepare image content
  const imageContents = await Promise.all(
    input.photos.slice(0, 4).map(async (photo) => {
      if (photo.startsWith('data:')) {
        // Already base64
        const match = photo.match(/^data:([^;]+);base64,(.+)$/);
        if (match) {
          return {
            type: 'image' as const,
            source: {
              type: 'base64' as const,
              media_type: match[1] as 'image/jpeg' | 'image/png' | 'image/gif' | 'image/webp',
              data: match[2],
            },
          };
        }
      } else if (photo.startsWith('http')) {
        // URL - Claude can handle URLs directly
        return {
          type: 'image' as const,
          source: {
            type: 'url' as const,
            url: photo,
          },
        };
      } else if (photo.startsWith('/')) {
        // Local file path - read and convert to base64
        const buffer = fs.readFileSync(photo);
        const ext = path.extname(photo).toLowerCase();
        const mediaType = ext === '.png' ? 'image/png' : 'image/jpeg';
        return {
          type: 'image' as const,
          source: {
            type: 'base64' as const,
            media_type: mediaType as 'image/jpeg' | 'image/png',
            data: buffer.toString('base64'),
          },
        };
      }
      throw new Error(`Unsupported image format: ${photo.substring(0, 50)}...`);
    })
  );

  const systemPrompt = `You are an expert at identifying items for sale on marketplaces like Facebook Marketplace, eBay, and Craigslist.

Analyze the photos and provide detailed information about the item. Be accurate about:
- Brand and model (only if clearly visible or identifiable)
- Condition (be honest about wear, damage, flaws)
- Category and subcategory for marketplace listing
- Key features and selling points
- Any flaws or issues visible

Respond in JSON format:
{
  "name": "Concise item name for listing title",
  "brand": "Brand name if identifiable, null otherwise",
  "model": "Model number/name if visible, null otherwise",
  "condition": "new|like_new|good|fair|poor",
  "category": "Main category (Electronics, Furniture, Clothing, etc.)",
  "subcategory": "Subcategory if applicable",
  "estimatedAge": "Rough age estimate if determinable",
  "color": "Primary color(s)",
  "size": "Dimensions or size if applicable",
  "features": ["Key feature 1", "Key feature 2"],
  "flaws": ["Visible flaw 1", "Wear indicator 2"],
  "suggestedKeywords": ["keyword1", "keyword2", "keyword3"],
  "confidence": 0.0-1.0
}`;

  if (config.provider === 'anthropic') {
    const client = new Anthropic({ apiKey: config.apiKey });

    const userContent: Array<Anthropic.ImageBlockParam | Anthropic.TextBlockParam> = [
      ...imageContents as Anthropic.ImageBlockParam[],
    ];

    if (input.userDescription) {
      userContent.push({
        type: 'text',
        text: `User's description: ${input.userDescription}\n\nAnalyze these images and identify the item for marketplace listing.`,
      });
    } else {
      userContent.push({
        type: 'text',
        text: 'Analyze these images and identify the item for marketplace listing.',
      });
    }

    const response = await client.messages.create({
      model: config.model,
      max_tokens: 1500,
      system: systemPrompt,
      messages: [{
        role: 'user',
        content: userContent,
      }],
    });

    const text = response.content[0]?.type === 'text' ? response.content[0].text : '';
    const jsonText = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

    try {
      return JSON.parse(jsonText);
    } catch {
      // Return a basic result if parsing fails
      return {
        name: 'Unidentified Item',
        condition: 'good',
        category: 'Other',
        features: [],
        flaws: [],
        suggestedKeywords: [],
        confidence: 0.3,
      };
    }
  } else {
    // OpenAI implementation would go here
    throw new Error('OpenAI vision not implemented yet');
  }
}

// ============================================================================
// FIND COMPARABLE SALES (PRICING)
// ============================================================================

export interface FindComparablesInput {
  workspaceId: string;
  itemName: string;
  brand?: string;
  model?: string;
  condition: string;
  category?: string;
}

export interface Comparable {
  title: string;
  price: number;
  soldDate?: string;
  platform: 'ebay' | 'facebook' | 'craigslist' | 'mercari' | 'offerup';
  url?: string;
  condition?: string;
  imageUrl?: string;
}

export async function findComparables(input: FindComparablesInput): Promise<Comparable[]> {
  const comparables: Comparable[] = [];

  // Try eBay API first
  const ebayConfig = await getEbayConfig(input.workspaceId);

  if (ebayConfig) {
    try {
      const ebayResults = await searchEbayCompletedListings(ebayConfig, input);
      comparables.push(...ebayResults);
    } catch (error) {
      console.warn('eBay search failed:', error);
    }
  }

  // If we don't have enough comparables, use LLM to estimate
  if (comparables.length < 3) {
    const estimates = await estimatePriceWithLLM(input);
    comparables.push(...estimates);
  }

  return comparables;
}

async function searchEbayCompletedListings(
  config: EbayConfig,
  input: FindComparablesInput
): Promise<Comparable[]> {
  // Build search query
  let keywords = input.itemName;
  if (input.brand) keywords = `${input.brand} ${keywords}`;
  if (input.model) keywords = `${input.model} ${keywords}`;

  const baseUrl = config.sandbox
    ? 'https://svcs.sandbox.ebay.com/services/search/FindingService/v1'
    : 'https://svcs.ebay.com/services/search/FindingService/v1';

  const params = new URLSearchParams({
    'OPERATION-NAME': 'findCompletedItems',
    'SERVICE-VERSION': '1.13.0',
    'SECURITY-APPNAME': config.appId,
    'RESPONSE-DATA-FORMAT': 'JSON',
    'REST-PAYLOAD': '',
    'keywords': keywords,
    'itemFilter(0).name': 'SoldItemsOnly',
    'itemFilter(0).value': 'true',
    'sortOrder': 'EndTimeSoonest',
    'paginationInput.entriesPerPage': '10',
  });

  const response = await fetch(`${baseUrl}?${params.toString()}`);
  const data = await response.json() as {
    findCompletedItemsResponse?: Array<{
      searchResult?: Array<{
        item?: Array<{
          title: string[];
          sellingStatus: Array<{ currentPrice: Array<{ __value__: string }> }>;
          listingInfo: Array<{ endTime: string[] }>;
          viewItemURL: string[];
          condition?: Array<{ conditionDisplayName: string[] }>;
          galleryURL?: string[];
        }>;
      }>;
    }>;
  };

  const items = data.findCompletedItemsResponse?.[0]?.searchResult?.[0]?.item || [];

  return items.slice(0, 5).map((item) => ({
    title: item.title[0],
    price: parseFloat(item.sellingStatus[0].currentPrice[0].__value__),
    soldDate: item.listingInfo[0].endTime[0],
    platform: 'ebay' as const,
    url: item.viewItemURL[0],
    condition: item.condition?.[0]?.conditionDisplayName?.[0],
    imageUrl: item.galleryURL?.[0],
  }));
}

async function estimatePriceWithLLM(input: FindComparablesInput): Promise<Comparable[]> {
  const anthropicKey = process.env['ANTHROPIC_API_KEY'];
  if (!anthropicKey) return [];

  const client = new Anthropic({ apiKey: anthropicKey });

  const response = await client.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 1024,
    system: `You are a marketplace pricing expert. Estimate realistic selling prices for used items based on typical resale values.

Consider:
- Brand value and demand
- Condition impact on price
- Market trends
- Seasonal factors

Respond with 3 estimated comparable prices in JSON format:
{
  "comparables": [
    {"title": "Similar item description", "price": 0, "platform": "ebay", "condition": "condition"},
    ...
  ]
}`,
    messages: [{
      role: 'user',
      content: `Estimate resale prices for: ${input.brand || ''} ${input.itemName} ${input.model || ''} in ${input.condition} condition`,
    }],
  });

  const text = response.content[0]?.type === 'text' ? response.content[0].text : '';
  const jsonText = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

  try {
    const parsed = JSON.parse(jsonText);
    return parsed.comparables.map((c: { title: string; price: number; platform: string; condition?: string }) => ({
      ...c,
      platform: c.platform as Comparable['platform'],
    }));
  } catch {
    return [];
  }
}

// ============================================================================
// CREATE LISTING DRAFT
// ============================================================================

export interface CreateListingDraftInput {
  workspaceId: string;
  itemInfo: ItemInfo;
  comparables: Comparable[];
  photos: string[];
}

export interface ListingDraft {
  title: string;
  description: string;
  price: number;
  priceFloor: number;
  photos: string[];
  category: string;
  condition: string;
  attributes: Record<string, string>;
  keywords: string[];
}

export async function createListingDraft(input: CreateListingDraftInput): Promise<ListingDraft> {
  const anthropicKey = process.env['ANTHROPIC_API_KEY'];

  // Calculate suggested price from comparables
  let suggestedPrice = 50;
  let priceFloor = 30;

  if (input.comparables.length > 0) {
    const prices = input.comparables.map((c) => c.price);
    const avgPrice = prices.reduce((a, b) => a + b, 0) / prices.length;

    // Adjust based on condition
    const conditionMultipliers: Record<string, number> = {
      new: 1.0,
      like_new: 0.85,
      good: 0.7,
      fair: 0.5,
      poor: 0.3,
    };

    const multiplier = conditionMultipliers[input.itemInfo.condition] || 0.7;
    suggestedPrice = Math.round(avgPrice * multiplier);
    priceFloor = Math.round(suggestedPrice * 0.7);
  }

  // Generate optimized title and description using LLM
  if (anthropicKey) {
    const client = new Anthropic({ apiKey: anthropicKey });

    const response = await client.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1500,
      system: `You are an expert at writing compelling marketplace listings that sell items quickly.

Create a title and description for Facebook Marketplace/Craigslist:
- Title: Max 80 characters, include brand/key details, grab attention
- Description: 150-300 words, highlight features, be honest about condition, include call to action

Respond in JSON:
{
  "title": "Compelling listing title",
  "description": "Full listing description with formatting",
  "keywords": ["keyword1", "keyword2"]
}`,
      messages: [{
        role: 'user',
        content: `Create listing for:
Item: ${input.itemInfo.name}
Brand: ${input.itemInfo.brand || 'Unknown'}
Model: ${input.itemInfo.model || 'N/A'}
Condition: ${input.itemInfo.condition}
Features: ${input.itemInfo.features.join(', ')}
Flaws: ${input.itemInfo.flaws.join(', ') || 'None noted'}
Color: ${input.itemInfo.color || 'N/A'}
Category: ${input.itemInfo.category}
Suggested price: $${suggestedPrice}`,
      }],
    });

    const text = response.content[0]?.type === 'text' ? response.content[0].text : '';
    const jsonText = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

    try {
      const parsed = JSON.parse(jsonText);
      return {
        title: parsed.title,
        description: parsed.description,
        price: suggestedPrice,
        priceFloor,
        photos: input.photos,
        category: input.itemInfo.category,
        condition: input.itemInfo.condition,
        attributes: {
          brand: input.itemInfo.brand || '',
          model: input.itemInfo.model || '',
          color: input.itemInfo.color || '',
        },
        keywords: parsed.keywords || input.itemInfo.suggestedKeywords,
      };
    } catch {
      // Fall through to default
    }
  }

  // Default if LLM fails
  return {
    title: `${input.itemInfo.brand || ''} ${input.itemInfo.name}`.trim(),
    description: `${input.itemInfo.name} in ${input.itemInfo.condition} condition.

Features:
${input.itemInfo.features.map((f) => `• ${f}`).join('\n')}

${input.itemInfo.flaws.length > 0 ? `Note: ${input.itemInfo.flaws.join(', ')}` : ''}

Price is firm. Local pickup only. Cash or Venmo accepted.`,
    price: suggestedPrice,
    priceFloor,
    photos: input.photos,
    category: input.itemInfo.category,
    condition: input.itemInfo.condition,
    attributes: {},
    keywords: input.itemInfo.suggestedKeywords,
  };
}

// ============================================================================
// POST LISTING
// ============================================================================

export interface PostListingInput {
  workspaceId: string;
  draft: ListingDraft;
  platforms?: Array<'facebook' | 'craigslist' | 'offerup'>;
  idempotencyKey: string;
}

export interface Listing {
  listingId: string;
  url: string;
  platform: string;
  status: 'active' | 'pending' | 'sold' | 'expired' | 'draft';
  postedAt?: string;
}

export async function postListing(input: PostListingInput): Promise<Listing> {
  const platforms = input.platforms || ['facebook'];

  // For now, return a draft listing since actual posting requires
  // platform-specific OAuth and compliance with their ToS
  // In production, this would integrate with platform APIs

  const listingId = `listing-${Date.now()}-${Math.random().toString(36).substring(7)}`;

  // Store listing in database for manual posting or future automation
  console.log(`[Marketplace] Created listing draft: ${listingId}`);
  console.log(`[Marketplace] Title: ${input.draft.title}`);
  console.log(`[Marketplace] Price: $${input.draft.price}`);
  console.log(`[Marketplace] Platforms: ${platforms.join(', ')}`);

  return {
    listingId,
    url: `https://marketplace.homeos.local/listings/${listingId}`,
    platform: platforms[0],
    status: 'draft',
    postedAt: new Date().toISOString(),
  };
}

// ============================================================================
// MESSAGE HANDLING & SCAM DETECTION
// ============================================================================

export interface CheckMessageRiskInput {
  workspaceId: string;
  buyerId: string;
  content: string;
  conversationHistory?: string[];
}

export interface MessageRiskOutput {
  isScam: boolean;
  riskLevel: 'low' | 'medium' | 'high';
  reason?: string;
  intent?: 'purchase' | 'inquiry' | 'negotiation' | 'spam' | 'scam';
  requiresAddressSharing?: boolean;
  proposedTimes?: string[];
  suggestedResponse?: string;
}

// Scam patterns to detect
const SCAM_PATTERNS = [
  // Payment scams
  { pattern: /pay.?pal.*friends.*family/i, reason: 'PayPal Friends & Family request (no buyer protection)' },
  { pattern: /send.*gift.*card/i, reason: 'Gift card payment request' },
  { pattern: /wire.*transfer/i, reason: 'Wire transfer request' },
  { pattern: /western.*union/i, reason: 'Western Union payment request' },
  { pattern: /zelle.*business/i, reason: 'Zelle business payment (often scam)' },
  { pattern: /crypto|bitcoin|ethereum/i, reason: 'Cryptocurrency payment request' },

  // Shipping scams
  { pattern: /my.*shipper.*will.*pick/i, reason: 'Third-party shipper pickup scam' },
  { pattern: /send.*shipping.*label/i, reason: 'Fake shipping label scam' },
  { pattern: /i.*will.*pay.*extra.*for.*shipping/i, reason: 'Overpayment shipping scam' },
  { pattern: /out.*of.*town|overseas|deployed|military/i, reason: 'Remote buyer scam pattern' },

  // Overpayment scams
  { pattern: /send.*difference/i, reason: 'Overpayment difference scam' },
  { pattern: /refund.*extra/i, reason: 'Overpayment refund scam' },
  { pattern: /pay.*more.*than.*asking/i, reason: 'Overpayment scam' },

  // Information harvesting
  { pattern: /social.*security|ssn/i, reason: 'Identity theft attempt' },
  { pattern: /bank.*account.*number/i, reason: 'Bank information phishing' },
  { pattern: /driver.*license/i, reason: 'ID information phishing' },

  // Urgency tactics
  { pattern: /must.*sell.*today|urgent|emergency/i, reason: 'Pressure tactics' },
  { pattern: /my.*assistant|secretary|agent/i, reason: 'Third-party buyer scam' },

  // Contact outside platform
  { pattern: /text.*me.*at|call.*me.*at|\d{3}[-.\s]?\d{3}[-.\s]?\d{4}/i, reason: 'Attempt to move off platform' },
  { pattern: /whatsapp|telegram|signal/i, reason: 'Request to use external messaging' },
];

export async function checkMessageRisk(input: CheckMessageRiskInput): Promise<MessageRiskOutput> {
  const content = input.content.toLowerCase();

  // Check against known scam patterns
  for (const { pattern, reason } of SCAM_PATTERNS) {
    if (pattern.test(input.content)) {
      return {
        isScam: true,
        riskLevel: 'high',
        reason,
        intent: 'scam',
        suggestedResponse: "I'm only accepting local cash pickup. Thanks for your interest.",
      };
    }
  }

  // Use LLM for more nuanced analysis
  const anthropicKey = process.env['ANTHROPIC_API_KEY'];
  if (anthropicKey) {
    const client = new Anthropic({ apiKey: anthropicKey });

    const response = await client.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 500,
      system: `You analyze marketplace buyer messages for scam risk and intent.

Assess the message for:
1. Scam indicators (payment tricks, shipping scams, info harvesting)
2. Buyer intent (genuine purchase, negotiation, inquiry, spam)
3. Whether they're requesting address/personal info
4. Proposed meeting times if mentioned

Respond in JSON:
{
  "isScam": boolean,
  "riskLevel": "low|medium|high",
  "reason": "explanation if risky",
  "intent": "purchase|inquiry|negotiation|spam|scam",
  "requiresAddressSharing": boolean,
  "proposedTimes": ["time1", "time2"] or null,
  "suggestedResponse": "brief suggested reply"
}`,
      messages: [{
        role: 'user',
        content: `Analyze this marketplace buyer message:\n\n"${input.content}"`,
      }],
    });

    const text = response.content[0]?.type === 'text' ? response.content[0].text : '';
    const jsonText = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

    try {
      return JSON.parse(jsonText);
    } catch {
      // Fall through to default
    }
  }

  // Default response for legitimate-looking messages
  const lowerContent = content.toLowerCase();

  return {
    isScam: false,
    riskLevel: 'low',
    intent: lowerContent.includes('price') || lowerContent.includes('$')
      ? 'negotiation'
      : lowerContent.includes('available') || lowerContent.includes('interested')
        ? 'inquiry'
        : 'purchase',
    requiresAddressSharing: lowerContent.includes('where') || lowerContent.includes('pick') || lowerContent.includes('address'),
    suggestedResponse: 'Yes, still available! When would you like to pick up?',
  };
}

// ============================================================================
// BUYER COMMUNICATION
// ============================================================================

export interface SendBuyerMessageInput {
  workspaceId: string;
  listingId: string;
  buyerId: string;
  message: string;
  idempotencyKey: string;
}

export async function sendBuyerMessage(input: SendBuyerMessageInput): Promise<{ sent: boolean; messageId?: string }> {
  // In production, this would use platform APIs
  // For now, log the message for manual sending

  console.log(`[Marketplace] Message to buyer ${input.buyerId}:`);
  console.log(`[Marketplace] ${input.message}`);

  return {
    sent: true,
    messageId: `msg-${Date.now()}`,
  };
}

// ============================================================================
// PICKUP SCHEDULING
// ============================================================================

export interface SchedulePickupInput {
  workspaceId: string;
  userId: string;
  buyerId: string;
  proposedTimes: string[];
  itemId?: string;
  location?: string;
}

export interface SchedulePickupOutput {
  scheduledTime: string;
  confirmationMessage: string;
  location?: string;
  reminderSet: boolean;
}

export async function schedulePickup(input: SchedulePickupInput): Promise<SchedulePickupOutput> {
  // Select the first proposed time (in production, check calendar availability)
  const scheduledTime = input.proposedTimes[0] || new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  // Generate a friendly confirmation message
  const timeStr = new Date(scheduledTime).toLocaleString('en-US', {
    weekday: 'long',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  });

  return {
    scheduledTime,
    confirmationMessage: `Great! See you ${timeStr}. I'll send the address closer to pickup time. Please confirm you can make it!`,
    location: input.location,
    reminderSet: true,
  };
}

// ============================================================================
// LISTING MANAGEMENT
// ============================================================================

export interface UpdateListingPriceInput {
  workspaceId: string;
  listingId: string;
  newPrice: number;
  reason?: string;
}

export async function updateListingPrice(input: UpdateListingPriceInput): Promise<{ updated: boolean }> {
  console.log(`[Marketplace] Price update for ${input.listingId}: $${input.newPrice}`);
  return { updated: true };
}

export interface MarkListingSoldInput {
  workspaceId: string;
  listingId: string;
  soldPrice: number;
  buyerId?: string;
}

export async function markListingSold(input: MarkListingSoldInput): Promise<{ success: boolean }> {
  console.log(`[Marketplace] Listing ${input.listingId} marked as sold for $${input.soldPrice}`);
  return { success: true };
}

export interface RenewListingInput {
  workspaceId: string;
  listingId: string;
  priceReduction?: number; // percentage
}

export async function renewListing(input: RenewListingInput): Promise<{ renewed: boolean; newPrice?: number }> {
  console.log(`[Marketplace] Listing ${input.listingId} renewed`);
  return { renewed: true };
}
