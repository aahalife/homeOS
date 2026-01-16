import { setTimeout as delay } from 'node:timers/promises';

export interface NotificationPreferences {
  quietHoursEnabled: boolean;
  quietHoursStart: string;
  quietHoursEnd: string;
}

export interface CreateNotificationInput {
  workspaceId: string;
  userId?: string;
  type: string;
  title: string;
  body: string;
  deliverAt?: string;
  metadata?: Record<string, unknown>;
}

const CACHE_TTL_MS = 5 * 60 * 1000;
const cache = new Map<string, { expiresAt: number; value: NotificationPreferences }>();

export async function getNotificationPreferences(
  workspaceId: string
): Promise<NotificationPreferences | null> {
  const cached = cache.get(workspaceId);
  if (cached && cached.expiresAt > Date.now()) {
    return cached.value;
  }

  const baseUrl = process.env['CONTROL_PLANE_URL'];
  const serviceToken = process.env['CONTROL_PLANE_SERVICE_TOKEN'];
  if (!baseUrl || !serviceToken) {
    return null;
  }

  try {
    const url = new URL('/v1/internal/preferences/notifications', baseUrl);
    url.searchParams.set('workspaceId', workspaceId);

    const response = await fetch(url.toString(), {
      headers: {
        'Content-Type': 'application/json',
        'x-service-token': serviceToken,
      },
    });

    if (!response.ok) {
      return null;
    }

    const payload = await response.json();
    const prefs: NotificationPreferences = {
      quietHoursEnabled: Boolean(payload.quietHoursEnabled),
      quietHoursStart: payload.quietHoursStart ?? '22:00',
      quietHoursEnd: payload.quietHoursEnd ?? '07:00',
    };

    cache.set(workspaceId, { value: prefs, expiresAt: Date.now() + CACHE_TTL_MS });
    return prefs;
  } catch {
    return null;
  }
}

export async function warmNotificationPreferences(workspaceId: string): Promise<void> {
  await delay(0);
  await getNotificationPreferences(workspaceId);
}

export async function createNotification(
  input: CreateNotificationInput
): Promise<{ id: string; status: string } | null> {
  const baseUrl = process.env['CONTROL_PLANE_URL'];
  const serviceToken = process.env['CONTROL_PLANE_SERVICE_TOKEN'];
  if (!baseUrl || !serviceToken) {
    return null;
  }

  try {
    const response = await fetch(`${baseUrl}/v1/internal/notifications`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-service-token': serviceToken,
      },
      body: JSON.stringify(input),
    });

    if (!response.ok) {
      return null;
    }

    return await response.json();
  } catch {
    return null;
  }
}
