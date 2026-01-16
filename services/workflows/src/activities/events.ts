export interface EmitTaskEventInput {
  workspaceId: string;
  eventType: string;
  payload: Record<string, unknown>;
  notification?: {
    title: string;
    body: string;
    priority?: 'normal' | 'urgent';
  };
}

export async function emitTaskEvent(
  workspaceId: string,
  eventType: string,
  payload: Record<string, unknown>,
  notification?: EmitTaskEventInput['notification']
): Promise<void> {
  // TODO: Emit event to runtime WebSocket connections
  const RUNTIME_URL = process.env['RUNTIME_URL'] ?? 'http://localhost:3002';
  const SERVICE_TOKEN = process.env['RUNTIME_SERVICE_TOKEN'];

  try {
    if (!SERVICE_TOKEN) {
      console.warn('[Events] Missing RUNTIME_SERVICE_TOKEN');
      return;
    }
    await fetch(`${RUNTIME_URL}/internal/events`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-service-token': SERVICE_TOKEN,
      },
      body: JSON.stringify({
        workspaceId,
        type: eventType,
        payload,
        notification,
      }),
    });
  } catch (error) {
    console.error('Failed to emit task event:', error);
  }
}
