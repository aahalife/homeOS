import { createNotification, getNotificationPreferences } from './controlPlane.js';
import { isWithinQuietHours, nextQuietHoursEnd } from '../utils/quietHours.js';

export interface EventNotificationOverride {
  title: string;
  body: string;
  priority?: 'normal' | 'urgent';
}

export interface QueueNotificationInput {
  workspaceId: string;
  userId?: string;
  eventType: string;
  payload: Record<string, unknown>;
  notification?: EventNotificationOverride;
}

export async function queueNotificationForEvent(
  input: QueueNotificationInput
): Promise<{ id: string; status: string } | null> {
  const notification = buildNotification(input);
  if (!notification) {
    return null;
  }

  const preferences = await getNotificationPreferences(input.workspaceId);
  const now = new Date();
  let deliverAt: string | undefined;

  if (preferences?.quietHoursEnabled && !notification.isUrgent) {
    const window = {
      start: preferences.quietHoursStart,
      end: preferences.quietHoursEnd,
    };
    if (isWithinQuietHours(now, window)) {
      deliverAt = nextQuietHoursEnd(now, window).toISOString();
    }
  }

  return createNotification({
    workspaceId: input.workspaceId,
    userId: input.userId,
    type: input.eventType,
    title: notification.title,
    body: notification.body,
    deliverAt,
    metadata: {
      eventType: input.eventType,
    },
  });
}

function buildNotification(input: QueueNotificationInput): {
  title: string;
  body: string;
  isUrgent: boolean;
} | null {
  if (input.notification) {
    return {
      title: input.notification.title,
      body: input.notification.body,
      isUrgent: input.notification.priority === 'urgent',
    };
  }

  const eventType = input.eventType;
  const payload = input.payload ?? {};
  const priority = (payload['priority'] as string | undefined) ?? 'normal';
  const isUrgent = priority === 'urgent';

  if (eventType.startsWith('approval')) {
    return {
      title: 'Approval needed',
      body: (payload['message'] as string) ?? (payload['title'] as string) ?? 'An approval is waiting.',
      isUrgent,
    };
  }

  if (eventType.startsWith('task')) {
    return {
      title: 'Task update',
      body: (payload['title'] as string) ?? 'A task needs attention.',
      isUrgent,
    };
  }

  if (eventType.startsWith('chat')) {
    return {
      title: 'Oi update',
      body: (payload['content'] as string) ?? (payload['message'] as string) ?? 'Oi sent a message.',
      isUrgent,
    };
  }

  if (eventType.startsWith('family')) {
    return {
      title: 'Family update',
      body: (payload['message'] as string) ?? 'A family update is ready.',
      isUrgent,
    };
  }

  return {
    title: 'Oi update',
    body: (payload['message'] as string) ?? 'There is a new update.',
    isUrgent,
  };
}
