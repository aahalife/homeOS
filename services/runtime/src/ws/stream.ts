import type { FastifyRequest } from 'fastify';
import type { WebSocket } from 'ws';
import { EventEmitter } from 'node:events';
import type { StreamEvent } from '@homeos/shared';

// Global event bus for streaming events to connected clients
export const streamEventBus = new EventEmitter();
streamEventBus.setMaxListeners(1000);

interface ClientConnection {
  ws: WebSocket;
  workspaceId: string;
  userId: string;
  subscriptions: Set<string>;
}

const connections = new Map<WebSocket, ClientConnection>();

export async function streamHandler(
  socket: WebSocket,
  request: FastifyRequest
): Promise<void> {
  const fastify = request.server;

  // Authenticate the connection
  const token = request.headers['authorization']?.replace('Bearer ', '') ??
    (request.query as Record<string, string>)['token'];

  if (!token) {
    socket.close(4001, 'Unauthorized');
    return;
  }

  try {
    const decoded = fastify.jwt.verify<{
      sub: string;
      workspaceId?: string;
      type?: string;
    }>(token);

    // Accept both runtime tokens and regular auth tokens
    // For regular auth tokens, workspaceId may not be in token, get from query
    const workspaceId = decoded.workspaceId ??
      (request.query as Record<string, string>)['workspaceId'] ?? '';

    const connection: ClientConnection = {
      ws: socket,
      workspaceId,
      userId: decoded.sub,
      subscriptions: new Set(['task.created', 'task.updated', 'approval.requested', 'approval.resolved', 'chat.message.delta', 'chat.message.final']),
    };

    connections.set(socket, connection);

    // Send connected confirmation
    socket.send(JSON.stringify({
      type: 'connected',
      payload: {
        workspaceId: connection.workspaceId,
        userId: connection.userId,
      },
    }));

    // Handle incoming messages (subscriptions, etc.)
    socket.on('message', (data) => {
      try {
        const message = JSON.parse(data.toString());
        handleClientMessage(connection, message);
      } catch {
        socket.send(JSON.stringify({ type: 'error', payload: { message: 'Invalid JSON' } }));
      }
    });

    // Handle disconnection
    socket.on('close', () => {
      connections.delete(socket);
    });

    // Forward events to this client
    const eventHandler = (event: StreamEvent & { workspaceId: string }) => {
      if (event.workspaceId === connection.workspaceId) {
        if (connection.subscriptions.has(event.type) || connection.subscriptions.has('*')) {
          socket.send(JSON.stringify({ type: event.type, payload: event.payload }));
        }
      }
    };

    streamEventBus.on('event', eventHandler);

    socket.on('close', () => {
      streamEventBus.off('event', eventHandler);
    });

  } catch (err) {
    fastify.log.error(err, 'WebSocket authentication failed');
    socket.close(4001, 'Unauthorized');
  }
}

function handleClientMessage(
  connection: ClientConnection,
  message: { type: string; payload?: unknown }
): void {
  switch (message.type) {
    case 'subscribe':
      const eventTypes = (message.payload as { events?: string[] })?.events ?? [];
      eventTypes.forEach((e) => connection.subscriptions.add(e));
      connection.ws.send(JSON.stringify({
        type: 'subscribed',
        payload: { events: Array.from(connection.subscriptions) },
      }));
      break;

    case 'unsubscribe':
      const unsubTypes = (message.payload as { events?: string[] })?.events ?? [];
      unsubTypes.forEach((e) => connection.subscriptions.delete(e));
      connection.ws.send(JSON.stringify({
        type: 'unsubscribed',
        payload: { events: Array.from(connection.subscriptions) },
      }));
      break;

    case 'ping':
      connection.ws.send(JSON.stringify({ type: 'pong' }));
      break;

    default:
      connection.ws.send(JSON.stringify({
        type: 'error',
        payload: { message: `Unknown message type: ${message.type}` },
      }));
  }
}

// Helper to emit events to all connected clients in a workspace
export function emitToWorkspace(workspaceId: string, event: StreamEvent): void {
  streamEventBus.emit('event', { ...event, workspaceId });
}

// Helper to emit chat streaming events
export function emitChatDelta(
  workspaceId: string,
  sessionId: string,
  delta: string
): void {
  emitToWorkspace(workspaceId, {
    type: 'chat.message.delta',
    payload: { sessionId, delta },
  });
}

export function emitChatFinal(
  workspaceId: string,
  sessionId: string,
  content: string,
  messageId: string
): void {
  emitToWorkspace(workspaceId, {
    type: 'chat.message.final',
    payload: { sessionId, content, messageId },
  });
}
