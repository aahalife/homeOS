import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { UserService } from '../services/user.js';

const DEV_MODE = process.env['DEV_MODE'] === 'true';
const DEV_PASSCODE = process.env['DEV_PASSCODE'] || 'homeos2024';

const PasscodeAuthSchema = z.object({
  passcode: z.string().min(4),
  deviceId: z.string().optional(),
});

const AppleAuthSchema = z.object({
  identityToken: z.string().min(1),
  authorizationCode: z.string().min(1),
  user: z
    .object({
      email: z.string().email().optional(),
      name: z
        .object({
          firstName: z.string().optional(),
          lastName: z.string().optional(),
        })
        .optional(),
    })
    .optional(),
});

export const authRoutes: FastifyPluginAsync = async (app) => {
  const userService = new UserService();

  app.post(
    '/apple',
    {
      schema: {
        description: 'Authenticate with Apple Sign-In',
        tags: ['auth'],
        body: {
          type: 'object',
          required: ['identityToken', 'authorizationCode'],
          properties: {
            identityToken: { type: 'string' },
            authorizationCode: { type: 'string' },
            user: {
              type: 'object',
              properties: {
                email: { type: 'string' },
                name: {
                  type: 'object',
                  properties: {
                    firstName: { type: 'string' },
                    lastName: { type: 'string' },
                  },
                },
              },
            },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              token: { type: 'string' },
              user: {
                type: 'object',
                properties: {
                  id: { type: 'string' },
                  email: { type: 'string' },
                  name: { type: 'string' },
                },
              },
            },
          },
          201: {
            type: 'object',
            properties: {
              token: { type: 'string' },
              user: {
                type: 'object',
                properties: {
                  id: { type: 'string' },
                  email: { type: 'string' },
                  name: { type: 'string' },
                },
              },
            },
          },
          401: {
            type: 'object',
            properties: {
              error: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const body = AppleAuthSchema.parse(request.body);

      try {
        const { user, isNewUser } = await userService.authenticateWithApple(
          body.identityToken,
          body.authorizationCode,
          body.user
        );

        const token = app.jwt.sign(
          {
            sub: user.id,
            email: user.email,
          },
          { expiresIn: '7d' }
        );

        const statusCode = isNewUser ? 201 : 200;
        return reply.status(statusCode).send({
          token,
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
          },
        });
      } catch (error) {
        app.log.error(error, 'Apple authentication failed');
        return reply.status(401).send({ error: 'Authentication failed' });
      }
    }
  );

  // Dev passcode auth - only available in DEV_MODE
  app.post(
    '/passcode',
    {
      schema: {
        description: 'Authenticate with passcode (dev mode only)',
        tags: ['auth'],
        body: {
          type: 'object',
          required: ['passcode'],
          properties: {
            passcode: { type: 'string' },
            deviceId: { type: 'string' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              token: { type: 'string' },
              user: {
                type: 'object',
                properties: {
                  id: { type: 'string' },
                  email: { type: 'string' },
                  name: { type: 'string' },
                },
              },
            },
          },
          201: {
            type: 'object',
            properties: {
              token: { type: 'string' },
              user: {
                type: 'object',
                properties: {
                  id: { type: 'string' },
                  email: { type: 'string' },
                  name: { type: 'string' },
                },
              },
            },
          },
          401: {
            type: 'object',
            properties: {
              error: { type: 'string' },
            },
          },
          403: {
            type: 'object',
            properties: {
              error: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      // Only allow passcode auth in dev mode
      if (!DEV_MODE) {
        return reply.status(403).send({ error: 'Passcode auth not available' });
      }

      const body = PasscodeAuthSchema.parse(request.body);

      if (body.passcode !== DEV_PASSCODE) {
        return reply.status(401).send({ error: 'Invalid passcode' });
      }

      try {
        // Create or get dev user
        const { user, isNewUser } = await userService.findOrCreateDevUser(
          body.deviceId || 'dev-device'
        );

        const token = app.jwt.sign(
          {
            sub: user.id,
            email: user.email,
          },
          { expiresIn: '30d' } // Longer expiry for dev
        );

        const statusCode = isNewUser ? 201 : 200;
        return reply.status(statusCode).send({
          token,
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
          },
        });
      } catch (error) {
        app.log.error(error, 'Passcode authentication failed');
        return reply.status(401).send({ error: 'Authentication failed' });
      }
    }
  );

  // Check if passcode auth is available
  app.get(
    '/passcode/available',
    {
      schema: {
        description: 'Check if passcode auth is available',
        tags: ['auth'],
        response: {
          200: {
            type: 'object',
            properties: {
              available: { type: 'boolean' },
            },
          },
        },
      },
    },
    async () => {
      return { available: DEV_MODE };
    }
  );

  app.get(
    '/me',
    {
      schema: {
        description: 'Get current user',
        tags: ['auth'],
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              email: { type: 'string' },
              name: { type: 'string' },
              avatarUrl: { type: 'string' },
            },
          },
          401: {
            type: 'object',
            properties: {
              error: { type: 'string' },
            },
          },
          404: {
            type: 'object',
            properties: {
              error: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      try {
        await request.jwtVerify();
      } catch {
        return reply.status(401).send({ error: 'Unauthorized' });
      }

      const userId = (request.user as { sub: string }).sub;
      const user = await userService.findById(userId);

      if (!user) {
        return reply.status(404).send({ error: 'User not found' });
      }

      return {
        id: user.id,
        email: user.email,
        name: user.name,
        avatarUrl: user.avatarUrl,
      };
    }
  );
};
