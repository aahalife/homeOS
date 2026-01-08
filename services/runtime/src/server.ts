import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import jwt from '@fastify/jwt';
import websocket from '@fastify/websocket';
import multipart from '@fastify/multipart';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import { chatRoutes } from './routes/chat.js';
import { tasksRoutes } from './routes/tasks.js';
import { approvalsRoutes } from './routes/approvals.js';
import { ingestRoutes } from './routes/ingest.js';
import { voiceRoutes } from './routes/voice.js';
import { telegramRoutes } from './routes/telegram.js';
import { whatsappRoutes } from './routes/whatsapp.js';
import { streamHandler } from './ws/stream.js';
import { GatewayManager } from './gateway/manager.js';

const PORT = parseInt(process.env['PORT'] ?? '3002', 10);
const HOST = process.env['HOST'] ?? '0.0.0.0';
const JWT_SECRET = process.env['JWT_SECRET'] ?? 'dev-jwt-secret-change-in-production';

// Gateway ports (clawdbot-inspired)
const GATEWAY_WS_PORT = parseInt(process.env['GATEWAY_WS_PORT'] ?? '18789', 10);
const BRIDGE_TCP_PORT = parseInt(process.env['BRIDGE_TCP_PORT'] ?? '18790', 10);
const CANVAS_PORT = parseInt(process.env['CANVAS_PORT'] ?? '18793', 10);

async function buildApp() {
  const app = Fastify({
    logger: {
      level: process.env['LOG_LEVEL'] ?? 'info',
      transport:
        process.env['NODE_ENV'] === 'development'
          ? { target: 'pino-pretty' }
          : undefined,
    },
  });

  await app.register(cors, {
    origin: process.env['CORS_ORIGIN'] ?? true,
    credentials: true,
  });

  await app.register(helmet);

  await app.register(jwt, {
    secret: JWT_SECRET,
  });

  await app.register(websocket);

  await app.register(multipart, {
    limits: {
      fileSize: 10 * 1024 * 1024, // 10MB max file size
    },
  });

  await app.register(swagger, {
    openapi: {
      info: {
        title: 'HomeOS Runtime API',
        description: 'Chat, tasks, approvals, and real-time streaming',
        version: '0.1.0',
      },
      servers: [
        { url: `http://localhost:${PORT}`, description: 'Local development' },
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT',
          },
        },
      },
    },
  });

  await app.register(swaggerUi, {
    routePrefix: '/docs',
  });

  // Health check
  app.get('/health', async () => ({ status: 'ok', service: 'runtime' }));

  // API routes
  await app.register(chatRoutes, { prefix: '/v1/chat' });
  await app.register(tasksRoutes, { prefix: '/v1/tasks' });
  await app.register(approvalsRoutes, { prefix: '/v1/approvals' });
  await app.register(ingestRoutes, { prefix: '/v1/ingest' });
  await app.register(voiceRoutes, { prefix: '/v1/voice' });
  await app.register(telegramRoutes, { prefix: '/v1/telegram' });
  await app.register(whatsappRoutes, { prefix: '/v1/whatsapp' });

  // WebSocket stream
  app.register(async (fastify) => {
    fastify.get('/v1/stream', { websocket: true }, streamHandler);
  });

  return app;
}

async function start() {
  const app = await buildApp();

  // Initialize gateway manager (clawdbot-inspired control plane)
  const gateway = new GatewayManager({
    wsPort: GATEWAY_WS_PORT,
    bridgePort: BRIDGE_TCP_PORT,
    canvasPort: CANVAS_PORT,
    configPath: process.env['CONFIG_PATH'] ?? '~/.homeos/config.json',
  });

  try {
    await app.listen({ port: PORT, host: HOST });
    app.log.info(`Runtime listening on ${HOST}:${PORT}`);
    app.log.info(`WebSocket stream at ws://localhost:${PORT}/v1/stream`);
    app.log.info(`API docs available at http://localhost:${PORT}/docs`);

    // Start gateway services
    await gateway.start();
    app.log.info(`Gateway WS on port ${GATEWAY_WS_PORT}`);
    app.log.info(`Bridge TCP on port ${BRIDGE_TCP_PORT}`);
    app.log.info(`Canvas on port ${CANVAS_PORT}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }

  // Handle signals for graceful shutdown
  const shutdown = async () => {
    app.log.info('Shutting down...');
    await gateway.stop();
    await app.close();
    process.exit(0);
  };

  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
  process.on('SIGUSR1', async () => {
    app.log.info('Received SIGUSR1, reloading config...');
    await gateway.reload();
  });
}

start();

export { buildApp };
