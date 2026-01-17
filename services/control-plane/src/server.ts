import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import jwt from '@fastify/jwt';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import { authRoutes } from './routes/auth.js';
import { workspacesRoutes } from './routes/workspaces.js';
import { devicesRoutes } from './routes/devices.js';
import { secretsRoutes } from './routes/secrets.js';
import { runtimeRoutes } from './routes/runtime.js';
import { preferencesRoutes } from './routes/preferences.js';
import { twilioRoutes } from './routes/twilio.js';
import { integrationsRoutes } from './routes/integrations.js';
import { onboardingRoutes } from './routes/onboarding.js';
import { internalRoutes } from './routes/internal.js';
import { notificationsRoutes } from './routes/notifications.js';
import { usageRoutes } from './routes/usage.js';
import { workflowsRoutes } from './routes/workflows.js';
import { runMigrations } from './db.js';

const PORT = parseInt(process.env['PORT'] ?? '3001', 10);
const HOST = process.env['HOST'] ?? '0.0.0.0';
const JWT_SECRET = process.env['JWT_SECRET'] ?? 'dev-jwt-secret-change-in-production';

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

  await app.register(swagger, {
    openapi: {
      info: {
        title: 'HomeOS Control Plane API',
        description: 'Authentication, workspaces, devices, and BYOK secrets management',
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

  app.get('/health', async () => ({ status: 'ok', service: 'control-plane' }));

  await app.register(authRoutes, { prefix: '/v1/auth' });
  await app.register(workspacesRoutes, { prefix: '/v1/workspaces' });
  await app.register(devicesRoutes, { prefix: '/v1/devices' });
  await app.register(secretsRoutes, { prefix: '/v1/workspaces' });
  await app.register(runtimeRoutes, { prefix: '/v1/runtime' });
  await app.register(preferencesRoutes, { prefix: '/v1/preferences' });
  await app.register(twilioRoutes, { prefix: '/v1/twilio' });
  await app.register(integrationsRoutes, { prefix: '/v1/integrations' });
  await app.register(onboardingRoutes, { prefix: '/v1/onboarding' });
  await app.register(internalRoutes, { prefix: '/v1/internal' });
  await app.register(notificationsRoutes, { prefix: '/v1/notifications' });
  await app.register(usageRoutes, { prefix: '/v1/usage' });
  await app.register(workflowsRoutes, { prefix: '/v1/workflows' });

  return app;
}

async function start() {
  const app = await buildApp();

  try {
    // Run database migrations
    app.log.info('Running database migrations...');
    await runMigrations();

    await app.listen({ port: PORT, host: HOST });
    app.log.info(`Control plane listening on ${HOST}:${PORT}`);
    app.log.info(`API docs available at http://localhost:${PORT}/docs`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}

start();

export { buildApp };
