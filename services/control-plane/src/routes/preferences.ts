import type { FastifyPluginAsync, FastifyReply } from 'fastify';
import { z } from 'zod';
import { getPool } from '../db.js';

// Helper to send error responses with proper typing
function sendError(reply: FastifyReply, status: number, message: string) {
  return reply.status(status).send({ error: message });
}

const PreferenceCategorySchema = z.enum([
  'notifications',
  'privacy',
  'ai',
  'approvals',
  'general',
]);

const UpdatePreferencesSchema = z.object({
  preferences: z.record(z.unknown()),
});

// Default preferences by category
const DEFAULT_PREFERENCES: Record<string, object> = {
  notifications: {
    calls: true,
    tasks: true,
    approvals: true,
    dailyDigest: true,
    quietHoursEnabled: false,
    quietHoursStart: '22:00',
    quietHoursEnd: '07:00',
  },
  privacy: {
    dataRetentionDays: 90,
    piiMaskingLevel: 'high',
    analyticsOptOut: false,
    shareUsageData: false,
  },
  ai: {
    responseVerbosity: 'normal',
    personality: 'friendly',
    voiceProfileId: null,
    useVoiceResponses: false,
  },
  approvals: {
    autoApproveBelow: 50,
    requireApprovalFor: ['calls', 'payments', 'pii_sharing'],
    timeBasedApproval: false,
    trustedBusinesses: [],
  },
  general: {
    timezone: 'America/Los_Angeles',
    language: 'en',
    theme: 'system',
  },
};

export const preferencesRoutes: FastifyPluginAsync = async (app) => {
  const pool = getPool();

  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  // Get all preferences for a user
  app.get(
    '/',
    {
      schema: {
        description: 'Get all preferences for the current user',
        tags: ['preferences'],
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          200: {
            type: 'object',
            additionalProperties: true,
          },
        },
      },
    },
    async (request) => {
      const userId = (request.user as { sub: string }).sub;
      const { workspaceId } = request.query as { workspaceId: string };

      const result = await pool.query(
        `SELECT category, preferences FROM homeos.user_preferences
         WHERE workspace_id = $1 AND user_id = $2`,
        [workspaceId, userId]
      );

      // Merge with defaults
      const prefs: Record<string, object> = { ...DEFAULT_PREFERENCES };
      for (const row of result.rows) {
        prefs[row.category] = { ...DEFAULT_PREFERENCES[row.category], ...row.preferences };
      }

      return prefs;
    }
  );

  // Get preferences by category
  app.get(
    '/:category',
    {
      schema: {
        description: 'Get preferences for a specific category',
        tags: ['preferences'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['category'],
          properties: {
            category: { type: 'string' },
          },
        },
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          200: {
            type: 'object',
            additionalProperties: true,
          },
        },
      },
    },
    async (request, reply) => {
      const userId = (request.user as { sub: string }).sub;
      const { category } = request.params as { category: string };
      const { workspaceId } = request.query as { workspaceId: string };

      const parsed = PreferenceCategorySchema.safeParse(category);
      if (!parsed.success) {
        return sendError(reply, 400, 'Invalid category');
      }

      const result = await pool.query(
        `SELECT preferences FROM homeos.user_preferences
         WHERE workspace_id = $1 AND user_id = $2 AND category = $3`,
        [workspaceId, userId, category]
      );

      const defaults = DEFAULT_PREFERENCES[category] ?? {};
      const stored = result.rows[0]?.preferences ?? {};

      return { ...defaults, ...stored };
    }
  );

  // Update preferences by category
  app.put(
    '/:category',
    {
      schema: {
        description: 'Update preferences for a specific category',
        tags: ['preferences'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['category'],
          properties: {
            category: { type: 'string' },
          },
        },
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
          },
        },
        body: {
          type: 'object',
          required: ['preferences'],
          properties: {
            preferences: { type: 'object', additionalProperties: true },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              category: { type: 'string' },
              preferences: { type: 'object', additionalProperties: true },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const userId = (request.user as { sub: string }).sub;
      const { category } = request.params as { category: string };
      const { workspaceId } = request.query as { workspaceId: string };
      const body = UpdatePreferencesSchema.parse(request.body);

      const parsed = PreferenceCategorySchema.safeParse(category);
      if (!parsed.success) {
        return sendError(reply, 400, 'Invalid category');
      }

      // Upsert preferences
      const result = await pool.query(
        `INSERT INTO homeos.user_preferences (workspace_id, user_id, category, preferences)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (workspace_id, user_id, category)
         DO UPDATE SET preferences = homeos.user_preferences.preferences || $4, updated_at = NOW()
         RETURNING preferences`,
        [workspaceId, userId, category, JSON.stringify(body.preferences)]
      );

      const defaults = DEFAULT_PREFERENCES[category] ?? {};
      const merged = { ...defaults, ...result.rows[0].preferences };

      return {
        success: true,
        category,
        preferences: merged,
      };
    }
  );

  // Delete preferences for a category (reset to defaults)
  app.delete(
    '/:category',
    {
      schema: {
        description: 'Reset preferences for a category to defaults',
        tags: ['preferences'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['category'],
          properties: {
            category: { type: 'string' },
          },
        },
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              category: { type: 'string' },
              preferences: { type: 'object', additionalProperties: true },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const userId = (request.user as { sub: string }).sub;
      const { category } = request.params as { category: string };
      const { workspaceId } = request.query as { workspaceId: string };

      const parsed = PreferenceCategorySchema.safeParse(category);
      if (!parsed.success) {
        return sendError(reply, 400, 'Invalid category');
      }

      await pool.query(
        `DELETE FROM homeos.user_preferences
         WHERE workspace_id = $1 AND user_id = $2 AND category = $3`,
        [workspaceId, userId, category]
      );

      return {
        success: true,
        category,
        preferences: DEFAULT_PREFERENCES[category] ?? {},
      };
    }
  );
};
