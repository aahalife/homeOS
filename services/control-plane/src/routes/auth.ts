import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { UserService } from '../services/user.js';

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
