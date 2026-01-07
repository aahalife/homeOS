import { EventEmitter } from 'node:events';
import { createServer, type Server } from 'node:http';
import { WebSocketServer, type WebSocket } from 'ws';
import { readFile, watch } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { SessionManager } from './sessions.js';

interface GatewayConfig {
  wsPort: number;
  bridgePort: number;
  canvasPort: number;
  configPath: string;
}

interface RuntimeConfig {
  gateway?: {
    reload?: {
      mode?: 'hybrid' | 'full';
    };
  };
  allowlists?: {
    dms?: string[];
    groups?: string[];
  };
  activation?: {
    groups?: 'mention' | 'always';
  };
}

export class GatewayManager extends EventEmitter {
  private config: GatewayConfig;
  private runtimeConfig: RuntimeConfig = {};
  private wsServer: WebSocketServer | null = null;
  private bridgeServer: Server | null = null;
  private canvasServer: Server | null = null;
  private sessionManager: SessionManager;
  private configWatcher: AbortController | null = null;

  constructor(config: GatewayConfig) {
    super();
    this.config = config;
    this.sessionManager = new SessionManager();
  }

  async start(): Promise<void> {
    // Load initial config
    await this.loadConfig();

    // Start WebSocket server (loopback control plane)
    this.wsServer = new WebSocketServer({
      port: this.config.wsPort,
      host: '127.0.0.1',
    });

    this.wsServer.on('connection', this.handleWsConnection.bind(this));

    // Start Bridge TCP server (for client/node subset methods)
    this.bridgeServer = createServer(this.handleBridgeRequest.bind(this));
    this.bridgeServer.listen(this.config.bridgePort, '0.0.0.0');

    // Start Canvas HTTP server
    this.canvasServer = createServer(this.handleCanvasRequest.bind(this));
    this.canvasServer.listen(this.config.canvasPort);

    // Watch config file for changes
    this.watchConfig();
  }

  async stop(): Promise<void> {
    this.configWatcher?.abort();

    if (this.wsServer) {
      this.wsServer.close();
    }
    if (this.bridgeServer) {
      this.bridgeServer.close();
    }
    if (this.canvasServer) {
      this.canvasServer.close();
    }

    this.sessionManager.closeAll();
  }

  async reload(): Promise<void> {
    const oldConfig = { ...this.runtimeConfig };
    await this.loadConfig();

    const mode = this.runtimeConfig.gateway?.reload?.mode ?? 'hybrid';

    if (mode === 'hybrid') {
      // Apply safe changes without restart
      this.emit('config:updated', {
        previous: oldConfig,
        current: this.runtimeConfig,
      });
    } else {
      // Full restart required for critical changes
      this.emit('config:restart-required');
    }
  }

  private async loadConfig(): Promise<void> {
    const configPath = this.config.configPath.replace('~', homedir());

    try {
      const content = await readFile(configPath, 'utf-8');
      this.runtimeConfig = JSON.parse(content);
    } catch {
      // Use defaults if config doesn't exist
      this.runtimeConfig = {};
    }
  }

  private async watchConfig(): Promise<void> {
    const configPath = this.config.configPath.replace('~', homedir());
    this.configWatcher = new AbortController();

    try {
      const watcher = watch(configPath, { signal: this.configWatcher.signal });
      for await (const event of watcher) {
        if (event.eventType === 'change') {
          await this.reload();
        }
      }
    } catch (err) {
      if ((err as NodeJS.ErrnoException).name !== 'AbortError') {
        console.error('Config watcher error:', err);
      }
    }
  }

  private handleWsConnection(ws: WebSocket): void {
    ws.on('message', async (data) => {
      try {
        const message = JSON.parse(data.toString());
        await this.handleGatewayMessage(ws, message);
      } catch (err) {
        ws.send(JSON.stringify({ error: 'Invalid message format' }));
      }
    });
  }

  private async handleGatewayMessage(
    ws: WebSocket,
    message: { type: string; payload?: unknown }
  ): Promise<void> {
    switch (message.type) {
      case 'session.create':
        const session = this.sessionManager.create(
          (message.payload as { workspaceId: string; userId: string })?.workspaceId,
          (message.payload as { userId: string })?.userId
        );
        ws.send(JSON.stringify({ type: 'session.created', payload: session }));
        break;

      case 'session.get':
        const existing = this.sessionManager.get(
          (message.payload as { sessionId: string })?.sessionId
        );
        ws.send(JSON.stringify({ type: 'session.info', payload: existing }));
        break;

      case 'config.get':
        ws.send(JSON.stringify({ type: 'config.current', payload: this.runtimeConfig }));
        break;

      case 'config.reload':
        await this.reload();
        ws.send(JSON.stringify({ type: 'config.reloaded' }));
        break;

      default:
        ws.send(JSON.stringify({ error: `Unknown message type: ${message.type}` }));
    }
  }

  private handleBridgeRequest(
    req: import('http').IncomingMessage,
    res: import('http').ServerResponse
  ): void {
    // Bridge endpoints for client/node subset methods
    res.setHeader('Content-Type', 'application/json');

    if (req.url === '/health') {
      res.end(JSON.stringify({ status: 'ok' }));
      return;
    }

    res.statusCode = 404;
    res.end(JSON.stringify({ error: 'Not found' }));
  }

  private handleCanvasRequest(
    req: import('http').IncomingMessage,
    res: import('http').ServerResponse
  ): void {
    // Canvas endpoint (live visual workspace)
    if (req.url?.startsWith('/__homeos__/canvas/')) {
      res.setHeader('Content-Type', 'text/html');
      res.end(`
        <!DOCTYPE html>
        <html>
          <head>
            <title>HomeOS Canvas</title>
            <style>
              body { margin: 0; font-family: system-ui; background: #1a1a2e; color: white; }
              .canvas { width: 100vw; height: 100vh; display: flex; align-items: center; justify-content: center; }
            </style>
          </head>
          <body>
            <div class="canvas">
              <h1>HomeOS Canvas</h1>
            </div>
          </body>
        </html>
      `);
      return;
    }

    res.statusCode = 404;
    res.end('Not found');
  }

  getSession(sessionId: string) {
    return this.sessionManager.get(sessionId);
  }

  getAllowlists() {
    return this.runtimeConfig.allowlists ?? { dms: [], groups: [] };
  }

  getActivationMode(): 'mention' | 'always' {
    return this.runtimeConfig.activation?.groups ?? 'mention';
  }
}
