export interface EmitTaskEventInput {
  workspaceId: string;
  eventType: string;
  payload: Record<string, unknown>;
}

export async function emitTaskEvent(
  workspaceId: string,
  eventType: string,
  payload: Record<string, unknown>
): Promise<void> {
  // TODO: Emit event to runtime WebSocket connections
  const RUNTIME_URL = process.env['RUNTIME_URL'] ?? 'http://localhost:3002';

  try {
    await fetch(`${RUNTIME_URL}/internal/events`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        workspaceId,
        type: eventType,
        payload,
      }),
    });
  } catch (error) {
    console.error('Failed to emit task event:', error);
  }
}
