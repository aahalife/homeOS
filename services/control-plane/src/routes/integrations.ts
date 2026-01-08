import type { FastifyPluginAsync, FastifyReply } from 'fastify';
import { z } from 'zod';
import { getPool } from '../db.js';
import { randomBytes } from 'crypto';

// Helper to send error responses with proper typing
function sendError(reply: FastifyReply, status: number, message: string) {
  return reply.status(status).send({ error: message });
}

const COMPOSIO_API_KEY = process.env['COMPOSIO_API_KEY'] ?? '';
const COMPOSIO_API_URL = process.env['COMPOSIO_API_URL'] ?? 'https://backend.composio.dev/api/v2';

// Mapping from app ID to Composio auth_config_id
const AUTH_CONFIG_IDS: Record<string, string> = {
  google_calendar: 'ac_PCvwGWaKXTW7',
  gmail: 'ac_YIGIdhQ6fNVo',
  notion: 'ac_LBD6QLpEdMnH',
  google_drive: 'ac_x64GDTbTGyEe',
  google_docs: 'ac_b7sj7rfqTf4t',
  google_maps: 'ac_DoyW5lfmd7if',
  google_meet: 'ac_BYjQy9auZZF8',
  google_tasks: 'ac_tVWgRMSfmqeF',
  google_photos: 'ac_cDmX-hgzYWpw',
  linkedin: 'ac_aLuIO0XeeJMH',
  microsoft_teams: 'ac_hwfwDFKIrWbP',
  outlook: 'ac_7yyhU36fhP3M',
  retelle: 'ac_8ckX_0TTfo7s',
  sharepoint: 'ac_ctgbgjaCQokR',
  slackbot: 'ac_GodpFnIaqA0v',
  telegram: 'ac_n0pJj1i8anp4',
  todoist: 'ac_UKjNQ-OTmr_2',
};

// Available integrations with their metadata
const AVAILABLE_INTEGRATIONS = [
  // Productivity
  {
    id: 'google_calendar',
    name: 'Google Calendar',
    category: 'productivity',
    description: 'Sync events and manage your calendar',
    icon: 'calendar',
  },
  {
    id: 'gmail',
    name: 'Gmail',
    category: 'productivity',
    description: 'Send and read emails',
    icon: 'envelope',
  },
  {
    id: 'notion',
    name: 'Notion',
    category: 'productivity',
    description: 'Manage notes and databases',
    icon: 'doc.text',
  },
  {
    id: 'todoist',
    name: 'Todoist',
    category: 'productivity',
    description: 'Manage tasks and projects',
    icon: 'checkmark.circle',
  },
  {
    id: 'slackbot',
    name: 'Slack',
    category: 'productivity',
    description: 'Team messaging and collaboration',
    icon: 'message',
  },
  // Google Workspace
  {
    id: 'google_drive',
    name: 'Google Drive',
    category: 'productivity',
    description: 'Store and share files',
    icon: 'folder',
  },
  {
    id: 'google_docs',
    name: 'Google Docs',
    category: 'productivity',
    description: 'Create and edit documents',
    icon: 'doc',
  },
  {
    id: 'google_meet',
    name: 'Google Meet',
    category: 'productivity',
    description: 'Video meetings and calls',
    icon: 'video',
  },
  {
    id: 'google_tasks',
    name: 'Google Tasks',
    category: 'productivity',
    description: 'Task management',
    icon: 'checklist',
  },
  {
    id: 'google_photos',
    name: 'Google Photos',
    category: 'productivity',
    description: 'Photo storage and sharing',
    icon: 'photo',
  },
  // Microsoft
  {
    id: 'microsoft_teams',
    name: 'Microsoft Teams',
    category: 'productivity',
    description: 'Team collaboration and meetings',
    icon: 'person.2',
  },
  {
    id: 'outlook',
    name: 'Outlook',
    category: 'productivity',
    description: 'Email and calendar',
    icon: 'envelope',
  },
  {
    id: 'sharepoint',
    name: 'SharePoint',
    category: 'productivity',
    description: 'Document management and intranet',
    icon: 'folder',
  },
  // Professional
  {
    id: 'linkedin',
    name: 'LinkedIn',
    category: 'professional',
    description: 'Professional networking',
    icon: 'briefcase',
  },
  // Messaging
  {
    id: 'telegram',
    name: 'Telegram',
    category: 'messaging',
    description: 'Secure messaging',
    icon: 'paperplane',
  },
  // Transportation
  {
    id: 'google_maps',
    name: 'Google Maps',
    category: 'transportation',
    description: 'Navigation and places',
    icon: 'map',
  },
  // Other services (without auth_config_id yet)
  {
    id: 'instacart',
    name: 'Instacart',
    category: 'shopping',
    description: 'Order groceries and household items',
    icon: 'cart',
  },
  {
    id: 'uber',
    name: 'Uber',
    category: 'transportation',
    description: 'Book rides and track trips',
    icon: 'car',
  },
  {
    id: 'lyft',
    name: 'Lyft',
    category: 'transportation',
    description: 'Book rides and track trips',
    icon: 'car',
  },
  {
    id: 'spotify',
    name: 'Spotify',
    category: 'entertainment',
    description: 'Control music playback',
    icon: 'music.note',
  },
  {
    id: 'facebook',
    name: 'Facebook',
    category: 'social',
    description: 'Post to Marketplace and manage pages',
    icon: 'person.2',
  },
  {
    id: 'smartthings',
    name: 'SmartThings',
    category: 'smart_home',
    description: 'Control smart home devices',
    icon: 'house',
  },
];

async function composioRequest(
  method: string,
  endpoint: string,
  body?: unknown
): Promise<unknown> {
  const response = await fetch(`${COMPOSIO_API_URL}${endpoint}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': COMPOSIO_API_KEY,
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Composio API error: ${response.status} - ${error}`);
  }

  return response.json();
}

export const integrationsRoutes: FastifyPluginAsync = async (app) => {
  const pool = getPool();

  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  // Check if Composio is configured
  app.get(
    '/status',
    {
      schema: {
        description: 'Check Composio configuration status',
        tags: ['integrations'],
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            type: 'object',
            properties: {
              configured: { type: 'boolean' },
            },
          },
        },
      },
    },
    async () => {
      return { configured: !!COMPOSIO_API_KEY };
    }
  );

  // List available integrations
  app.get(
    '/',
    {
      schema: {
        description: 'List available integrations',
        tags: ['integrations'],
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            category: { type: 'string' },
          },
        },
        response: {
          200: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                id: { type: 'string' },
                name: { type: 'string' },
                category: { type: 'string' },
                description: { type: 'string' },
                icon: { type: 'string' },
                connected: { type: 'boolean' },
                connectedAt: { type: 'string' },
              },
            },
          },
        },
      },
    },
    async (request) => {
      const userId = (request.user as { sub: string }).sub;
      const { workspaceId, category } = request.query as {
        workspaceId: string;
        category?: string;
      };

      // Get connected integrations
      const result = await pool.query(
        `SELECT app_id, connected_at FROM homeos.composio_connections
         WHERE workspace_id = $1 AND user_id = $2 AND status = 'active'`,
        [workspaceId, userId]
      );

      const connectedApps = new Map(
        result.rows.map((row) => [row.app_id, row.connected_at])
      );

      let integrations = AVAILABLE_INTEGRATIONS;
      if (category) {
        integrations = integrations.filter((i) => i.category === category);
      }

      return integrations.map((integration) => ({
        ...integration,
        connected: connectedApps.has(integration.id),
        connectedAt: connectedApps.get(integration.id) ?? null,
      }));
    }
  );

  // Get connected integrations
  app.get(
    '/connected',
    {
      schema: {
        description: 'List connected integrations',
        tags: ['integrations'],
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
            type: 'array',
            items: {
              type: 'object',
              properties: {
                id: { type: 'string' },
                appId: { type: 'string' },
                appName: { type: 'string' },
                status: { type: 'string' },
                scopes: { type: 'array', items: { type: 'string' } },
                accountIdentifier: { type: 'string' },
                connectedAt: { type: 'string' },
              },
            },
          },
        },
      },
    },
    async (request) => {
      const userId = (request.user as { sub: string }).sub;
      const { workspaceId } = request.query as { workspaceId: string };

      const result = await pool.query(
        `SELECT id, app_id, app_name, status, scopes, account_identifier, connected_at
         FROM homeos.composio_connections
         WHERE workspace_id = $1 AND user_id = $2
         ORDER BY connected_at DESC`,
        [workspaceId, userId]
      );

      return result.rows.map((row) => ({
        id: row.id,
        appId: row.app_id,
        appName: row.app_name,
        status: row.status,
        scopes: row.scopes,
        accountIdentifier: row.account_identifier,
        connectedAt: row.connected_at,
      }));
    }
  );

  // Get OAuth authorization URL
  app.get(
    '/:appId/auth-url',
    {
      schema: {
        description: 'Get OAuth authorization URL for an integration',
        tags: ['integrations'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['appId'],
          properties: {
            appId: { type: 'string' },
          },
        },
        querystring: {
          type: 'object',
          required: ['workspaceId', 'redirectUrl'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            redirectUrl: { type: 'string' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              authUrl: { type: 'string' },
              state: { type: 'string' },
              expiresIn: { type: 'integer' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      if (!COMPOSIO_API_KEY) {
        return sendError(reply, 503, 'Composio not configured');
      }

      const userId = (request.user as { sub: string }).sub;
      const { appId } = request.params as { appId: string };
      const { workspaceId, redirectUrl } = request.query as {
        workspaceId: string;
        redirectUrl: string;
      };

      // Generate state token
      const stateToken = randomBytes(32).toString('hex');
      const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

      // Store state token
      await pool.query(
        `INSERT INTO homeos.oauth_states (state_token, workspace_id, user_id, app_id, redirect_url, expires_at)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [stateToken, workspaceId, userId, appId, redirectUrl, expiresAt]
      );

      try {
        // Get the Composio auth_config_id for this app
        const authConfigId = AUTH_CONFIG_IDS[appId];
        if (!authConfigId) {
          app.log.warn({ appId }, 'No auth_config_id configured for app');
          return sendError(reply, 400, `Integration ${appId} is not configured for OAuth yet`);
        }

        // Get auth URL from Composio using the auth_config_id
        const result = await composioRequest('POST', '/connectedAccounts', {
          integrationId: authConfigId,
          redirectUri: `${process.env['CONTROL_PLANE_URL'] ?? 'http://localhost:3001'}/v1/integrations/callback`,
          data: { state: stateToken },
        }) as { url?: string; redirectUrl?: string };

        app.log.info({ appId, authConfigId, hasUrl: !!result.url || !!result.redirectUrl }, 'Composio auth URL response');

        const authUrl = result.url ?? result.redirectUrl;
        if (!authUrl) {
          app.log.error({ result }, 'Composio did not return auth URL');
          return sendError(reply, 500, 'Failed to get auth URL from Composio');
        }

        return {
          authUrl,
          state: stateToken,
          expiresIn: 600, // 10 minutes
        };
      } catch (error) {
        app.log.error({ err: error, appId }, 'Composio auth URL error');
        return sendError(reply, 500, 'Failed to get auth URL');
      }
    }
  );

  // OAuth callback
  app.get(
    '/callback',
    {
      schema: {
        description: 'OAuth callback handler',
        tags: ['integrations'],
        querystring: {
          type: 'object',
          properties: {
            code: { type: 'string' },
            state: { type: 'string' },
            error: { type: 'string' },
          },
        },
      },
    },
    async (request, reply) => {
      const { code, state, error } = request.query as {
        code?: string;
        state?: string;
        error?: string;
      };

      if (error) {
        return reply.redirect(`/integrations/error?message=${encodeURIComponent(error)}`);
      }

      if (!state) {
        return sendError(reply, 400, 'Missing state parameter');
      }

      // Validate state token
      const stateResult = await pool.query(
        `SELECT workspace_id, user_id, app_id, redirect_url
         FROM homeos.oauth_states
         WHERE state_token = $1 AND expires_at > NOW()`,
        [state]
      );

      if (stateResult.rows.length === 0) {
        return sendError(reply, 400, 'Invalid or expired state token');
      }

      const { workspace_id, user_id, app_id, redirect_url } = stateResult.rows[0];

      // Delete used state token
      await pool.query('DELETE FROM homeos.oauth_states WHERE state_token = $1', [state]);

      try {
        // Exchange code for connection (Composio handles this internally)
        // The connection should already be created in Composio
        const connections = await composioRequest('GET', `/connectedAccounts?integrationId=${app_id}`) as {
          items?: Array<{
            id: string;
            integrationId: string;
            status: string;
            createdAt: string;
          }>;
        };

        const connection = connections.items?.find(
          (c) => c.integrationId === app_id && c.status === 'ACTIVE'
        );

        if (!connection) {
          return reply.redirect(`${redirect_url}?error=connection_failed`);
        }

        // Get integration metadata
        const integration = AVAILABLE_INTEGRATIONS.find((i) => i.id === app_id);

        // Store connection in database
        await pool.query(
          `INSERT INTO homeos.composio_connections
           (workspace_id, user_id, app_id, app_name, connection_id, status, connected_at)
           VALUES ($1, $2, $3, $4, $5, 'active', NOW())
           ON CONFLICT (workspace_id, user_id, app_id)
           DO UPDATE SET connection_id = $5, status = 'active', connected_at = NOW()`,
          [workspace_id, user_id, app_id, integration?.name ?? app_id, connection.id]
        );

        return reply.redirect(`${redirect_url}?success=true&app=${app_id}`);
      } catch (err) {
        app.log.error({ err }, 'OAuth callback error');
        return reply.redirect(`${redirect_url}?error=callback_failed`);
      }
    }
  );

  // Disconnect an integration
  app.delete(
    '/:appId',
    {
      schema: {
        description: 'Disconnect an integration',
        tags: ['integrations'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['appId'],
          properties: {
            appId: { type: 'string' },
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
            },
          },
        },
      },
    },
    async (request, reply) => {
      const userId = (request.user as { sub: string }).sub;
      const { appId } = request.params as { appId: string };
      const { workspaceId } = request.query as { workspaceId: string };

      // Get connection ID
      const result = await pool.query(
        `SELECT connection_id FROM homeos.composio_connections
         WHERE workspace_id = $1 AND user_id = $2 AND app_id = $3`,
        [workspaceId, userId, appId]
      );

      if (result.rows.length === 0) {
        return sendError(reply, 404, 'Connection not found');
      }

      try {
        // Revoke in Composio
        if (COMPOSIO_API_KEY) {
          await composioRequest('DELETE', `/connectedAccounts/${result.rows[0].connection_id}`);
        }
      } catch {
        // Log but continue - still remove from our database
        app.log.warn('Failed to revoke Composio connection');
      }

      // Update database
      await pool.query(
        `UPDATE homeos.composio_connections
         SET status = 'revoked', updated_at = NOW()
         WHERE workspace_id = $1 AND user_id = $2 AND app_id = $3`,
        [workspaceId, userId, appId]
      );

      return { success: true };
    }
  );

  // Execute an action via integration
  app.post(
    '/:appId/action',
    {
      schema: {
        description: 'Execute an action via an integration',
        tags: ['integrations'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['appId'],
          properties: {
            appId: { type: 'string' },
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
          required: ['action'],
          properties: {
            action: { type: 'string' },
            params: { type: 'object', additionalProperties: true },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              data: { type: 'object', additionalProperties: true },
            },
          },
        },
      },
    },
    async (request, reply) => {
      if (!COMPOSIO_API_KEY) {
        return sendError(reply, 503, 'Composio not configured');
      }

      const userId = (request.user as { sub: string }).sub;
      const { appId } = request.params as { appId: string };
      const { workspaceId } = request.query as { workspaceId: string };
      const { action, params } = request.body as { action: string; params?: object };

      // Get connection
      const result = await pool.query(
        `SELECT connection_id FROM homeos.composio_connections
         WHERE workspace_id = $1 AND user_id = $2 AND app_id = $3 AND status = 'active'`,
        [workspaceId, userId, appId]
      );

      if (result.rows.length === 0) {
        return sendError(reply, 400, 'Integration not connected');
      }

      try {
        const actionResult = await composioRequest('POST', '/actions/execute', {
          connectedAccountId: result.rows[0].connection_id,
          actionName: action,
          input: params ?? {},
        });

        return {
          success: true,
          data: actionResult,
        };
      } catch (error) {
        app.log.error({ err: error }, 'Composio action error');
        return sendError(reply, 500, 'Action execution failed');
      }
    }
  );
};
