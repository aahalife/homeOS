/**
 * Composio Unified Integration Provider
 *
 * Consolidates all third-party OAuth and API integrations through Composio's
 * unified platform. Handles 500+ integrations with a single authentication flow.
 *
 * Supported categories:
 * - Productivity: Google Calendar, Gmail, Notion, Slack
 * - Health & Fitness: Apple Health, Fitbit, Withings
 * - Entertainment: Spotify, Netflix, YouTube
 * - Shopping: Instacart, Amazon, Walmart
 * - Transportation: Uber, Lyft, Google Maps
 * - Education: Google Classroom, Canvas
 * - Finance: Plaid, Stripe
 * - Smart Home: SmartThings, Home Assistant, Philips Hue
 */

import { getRedis } from '../utils/redis.js';

// Composio API configuration
const COMPOSIO_API_URL = process.env.COMPOSIO_API_URL || 'https://backend.composio.dev/api/v3';
const COMPOSIO_API_KEY = process.env.COMPOSIO_API_KEY;

// Supported app integrations grouped by category
export const SUPPORTED_INTEGRATIONS = {
  productivity: [
    { id: 'google_calendar', name: 'Google Calendar', icon: 'calendar', scopes: ['calendar.readonly', 'calendar.events'] },
    { id: 'gmail', name: 'Gmail', icon: 'mail', scopes: ['gmail.readonly', 'gmail.send'] },
    { id: 'notion', name: 'Notion', icon: 'file-text', scopes: ['read', 'write'] },
    { id: 'slack', name: 'Slack', icon: 'message-square', scopes: ['channels:read', 'chat:write'] },
    { id: 'todoist', name: 'Todoist', icon: 'check-square', scopes: ['data:read_write'] },
  ],
  health: [
    { id: 'apple_health', name: 'Apple Health', icon: 'heart', scopes: ['read'] },
    { id: 'fitbit', name: 'Fitbit', icon: 'activity', scopes: ['activity', 'sleep', 'heartrate'] },
    { id: 'withings', name: 'Withings', icon: 'thermometer', scopes: ['user.metrics'] },
    { id: 'oura', name: 'Oura Ring', icon: 'circle', scopes: ['daily', 'sleep'] },
  ],
  entertainment: [
    { id: 'spotify', name: 'Spotify', icon: 'music', scopes: ['user-read-playback-state', 'user-modify-playback-state'] },
    { id: 'youtube', name: 'YouTube', icon: 'play-circle', scopes: ['youtube.readonly'] },
  ],
  shopping: [
    { id: 'instacart', name: 'Instacart', icon: 'shopping-cart', scopes: ['orders', 'lists'] },
    { id: 'amazon', name: 'Amazon', icon: 'package', scopes: ['orders'] },
  ],
  transportation: [
    { id: 'uber', name: 'Uber', icon: 'car', scopes: ['ride.request', 'ride.status'] },
    { id: 'lyft', name: 'Lyft', icon: 'navigation', scopes: ['rides.request', 'rides.read'] },
    { id: 'google_maps', name: 'Google Maps', icon: 'map', scopes: ['directions', 'places'] },
  ],
  education: [
    { id: 'google_classroom', name: 'Google Classroom', icon: 'book-open', scopes: ['classroom.courses.readonly', 'classroom.coursework.me'] },
    { id: 'canvas', name: 'Canvas LMS', icon: 'graduation-cap', scopes: ['read', 'write'] },
  ],
  smart_home: [
    { id: 'smartthings', name: 'SmartThings', icon: 'home', scopes: ['devices', 'scenes'] },
    { id: 'philips_hue', name: 'Philips Hue', icon: 'sun', scopes: ['lights'] },
    { id: 'ecobee', name: 'Ecobee', icon: 'thermometer', scopes: ['thermostat'] },
  ],
  finance: [
    { id: 'plaid', name: 'Bank Accounts (Plaid)', icon: 'credit-card', scopes: ['transactions', 'accounts'] },
  ],
} as const;

export type IntegrationCategory = keyof typeof SUPPORTED_INTEGRATIONS;
export type IntegrationId = typeof SUPPORTED_INTEGRATIONS[IntegrationCategory][number]['id'];

interface ComposioConnection {
  id: string;
  appId: string;
  status: 'active' | 'expired' | 'revoked';
  connectedAt: string;
  expiresAt?: string;
  scopes: string[];
}

interface ComposioAuthUrl {
  authUrl: string;
  state: string;
  expiresIn: number;
}

interface ComposioToolResponse {
  success: boolean;
  data?: unknown;
  error?: string;
}

/**
 * Initialize Composio SDK for a workspace
 */
export async function initializeComposio(input: {
  workspaceId: string;
}): Promise<{ entityId: string; initialized: boolean }> {
  const { workspaceId } = input;

  if (!COMPOSIO_API_KEY) {
    console.warn('[Composio] API key not configured, using mock mode');
    return { entityId: `entity_${workspaceId}`, initialized: true };
  }

  try {
    const response = await fetch(`${COMPOSIO_API_URL}/entities`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': COMPOSIO_API_KEY,
      },
      body: JSON.stringify({
        externalId: workspaceId,
        name: `homeOS Workspace ${workspaceId}`,
      }),
    });

    if (!response.ok) {
      throw new Error(`Failed to initialize Composio: ${response.statusText}`);
    }

    const data = await response.json() as { id: string };
    return { entityId: data.id, initialized: true };
  } catch (error) {
    console.error('[Composio] Initialization error:', error);
    return { entityId: `entity_${workspaceId}`, initialized: false };
  }
}

/**
 * Get OAuth authorization URL for connecting an app
 */
export async function getAuthorizationUrl(input: {
  workspaceId: string;
  userId: string;
  appId: IntegrationId;
  redirectUrl: string;
}): Promise<ComposioAuthUrl> {
  const { workspaceId, userId, appId, redirectUrl } = input;

  if (!COMPOSIO_API_KEY) {
    // Mock mode - return a demo URL
    const state = `mock_${workspaceId}_${userId}_${appId}_${Date.now()}`;
    return {
      authUrl: `https://demo.composio.dev/auth/${appId}?state=${state}&redirect=${encodeURIComponent(redirectUrl)}`,
      state,
      expiresIn: 600,
    };
  }

  try {
    const response = await fetch(`${COMPOSIO_API_URL}/connections/initiate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': COMPOSIO_API_KEY,
      },
      body: JSON.stringify({
        entityId: `entity_${workspaceId}`,
        appName: appId,
        redirectUrl,
        integrationParams: {
          userId,
        },
      }),
    });

    if (!response.ok) {
      throw new Error(`Failed to get auth URL: ${response.statusText}`);
    }

    const data = await response.json() as { redirectUrl: string; state: string; expiresIn?: number };
    return {
      authUrl: data.redirectUrl,
      state: data.state,
      expiresIn: data.expiresIn || 600,
    };
  } catch (error) {
    console.error('[Composio] Auth URL error:', error);
    throw error;
  }
}

/**
 * Complete OAuth callback and store connection
 */
export async function completeAuthorization(input: {
  workspaceId: string;
  userId: string;
  appId: string;
  code: string;
  state: string;
}): Promise<{ success: boolean; connection?: ComposioConnection }> {
  const { workspaceId, userId, appId, code, state } = input;

  if (!COMPOSIO_API_KEY) {
    // Mock mode - simulate successful connection
    const connection: ComposioConnection = {
      id: `conn_${Date.now()}`,
      appId,
      status: 'active',
      connectedAt: new Date().toISOString(),
      scopes: ['read', 'write'],
    };

    // Store in Redis for mock mode
    const redis = getRedis();
    if (redis) {
      await redis.hSet(
        `composio:connections:${workspaceId}:${userId}`,
        appId,
        JSON.stringify(connection)
      );
    }

    return { success: true, connection };
  }

  try {
    const response = await fetch(`${COMPOSIO_API_URL}/connections/callback`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': COMPOSIO_API_KEY,
      },
      body: JSON.stringify({
        code,
        state,
      }),
    });

    if (!response.ok) {
      throw new Error(`Failed to complete auth: ${response.statusText}`);
    }

    const data = await response.json() as { connectionId: string; expiresAt?: string; scopes?: string[] };
    const connection: ComposioConnection = {
      id: data.connectionId,
      appId,
      status: 'active',
      connectedAt: new Date().toISOString(),
      expiresAt: data.expiresAt,
      scopes: data.scopes || [],
    };

    // Cache connection status
    const redis = getRedis();
    if (redis) {
      await redis.hSet(
        `composio:connections:${workspaceId}:${userId}`,
        appId,
        JSON.stringify(connection)
      );
    }

    return { success: true, connection };
  } catch (error) {
    console.error('[Composio] Complete auth error:', error);
    return { success: false };
  }
}

/**
 * Get all connected apps for a user
 */
export async function getConnectedApps(input: {
  workspaceId: string;
  userId: string;
}): Promise<ComposioConnection[]> {
  const { workspaceId, userId } = input;

  // Check cache first
  const redis = getRedis();
  if (redis) {
    const cached = await redis.hGetAll(`composio:connections:${workspaceId}:${userId}`);
    if (cached && Object.keys(cached).length > 0) {
      return Object.values(cached).map((v) => JSON.parse(v as string) as ComposioConnection);
    }
  }

  if (!COMPOSIO_API_KEY) {
    // Mock mode - return empty or demo connections
    return [];
  }

  try {
    const response = await fetch(
      `${COMPOSIO_API_URL}/connections?entityId=entity_${workspaceId}`,
      {
        headers: {
          'X-API-Key': COMPOSIO_API_KEY,
        },
      }
    );

    if (!response.ok) {
      throw new Error(`Failed to get connections: ${response.statusText}`);
    }

    const data = await response.json() as { connections: Array<{ id: string; appName: string; status: string; createdAt: string; expiresAt?: string; scopes?: string[] }> };
    return data.connections.map((c) => ({
      id: c.id,
      appId: c.appName,
      status: c.status as 'active' | 'expired' | 'revoked',
      connectedAt: c.createdAt,
      expiresAt: c.expiresAt,
      scopes: c.scopes || [],
    }));
  } catch (error) {
    console.error('[Composio] Get connections error:', error);
    return [];
  }
}

/**
 * Disconnect an app
 */
export async function disconnectApp(input: {
  workspaceId: string;
  userId: string;
  appId: string;
}): Promise<{ success: boolean }> {
  const { workspaceId, userId, appId } = input;

  // Remove from cache
  const redis = getRedis();
  if (redis) {
    await redis.hDel(`composio:connections:${workspaceId}:${userId}`, appId);
  }

  if (!COMPOSIO_API_KEY) {
    return { success: true };
  }

  try {
    const connections = await getConnectedApps({ workspaceId, userId });
    const connection = connections.find((c) => c.appId === appId);

    if (connection) {
      await fetch(`${COMPOSIO_API_URL}/connections/${connection.id}`, {
        method: 'DELETE',
        headers: {
          'X-API-Key': COMPOSIO_API_KEY,
        },
      });
    }

    return { success: true };
  } catch (error) {
    console.error('[Composio] Disconnect error:', error);
    return { success: false };
  }
}

/**
 * Execute a tool/action through Composio
 */
export async function executeAction(input: {
  workspaceId: string;
  userId: string;
  appId: string;
  action: string;
  params: Record<string, unknown>;
}): Promise<ComposioToolResponse> {
  const { workspaceId, userId, appId, action, params } = input;

  // Check if app is connected
  const connections = await getConnectedApps({ workspaceId, userId });
  const connection = connections.find((c) => c.appId === appId && c.status === 'active');

  if (!connection && COMPOSIO_API_KEY) {
    return {
      success: false,
      error: `App ${appId} is not connected. Please connect it first.`,
    };
  }

  if (!COMPOSIO_API_KEY) {
    // Mock mode - return simulated responses
    return getMockResponse(appId, action, params);
  }

  try {
    const response = await fetch(`${COMPOSIO_API_URL}/actions/execute`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': COMPOSIO_API_KEY,
      },
      body: JSON.stringify({
        entityId: `entity_${workspaceId}`,
        appName: appId,
        actionName: action,
        input: params,
        connectionId: connection?.id,
      }),
    });

    if (!response.ok) {
      throw new Error(`Action failed: ${response.statusText}`);
    }

    const data = await response.json() as { output: unknown };
    return {
      success: true,
      data: data.output,
    };
  } catch (error) {
    console.error('[Composio] Execute action error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

/**
 * Get available actions for an app
 */
export async function getAvailableActions(input: {
  appId: string;
}): Promise<{ actions: Array<{ name: string; description: string; params: Record<string, unknown> }> }> {
  const { appId } = input;

  if (!COMPOSIO_API_KEY) {
    // Return mock action definitions
    return { actions: getMockActions(appId) };
  }

  try {
    const response = await fetch(`${COMPOSIO_API_URL}/apps/${appId}/actions`, {
      headers: {
        'X-API-Key': COMPOSIO_API_KEY,
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to get actions: ${response.statusText}`);
    }

    const data = await response.json() as { actions: Array<{ name: string; description: string; params: Record<string, unknown> }> };
    return { actions: data.actions };
  } catch (error) {
    console.error('[Composio] Get actions error:', error);
    return { actions: [] };
  }
}

/**
 * List all available integrations with connection status
 */
export async function listIntegrations(input: {
  workspaceId: string;
  userId: string;
  category?: IntegrationCategory;
}): Promise<{
  integrations: Array<{
    id: string;
    name: string;
    icon: string;
    category: string;
    connected: boolean;
    status?: string;
  }>;
}> {
  const { workspaceId, userId, category } = input;

  const connections = await getConnectedApps({ workspaceId, userId });
  const connectedIds = new Set(connections.filter((c) => c.status === 'active').map((c) => c.appId));

  const integrations: Array<{
    id: string;
    name: string;
    icon: string;
    category: string;
    connected: boolean;
    status?: string;
  }> = [];

  const categories = category ? [category] : Object.keys(SUPPORTED_INTEGRATIONS) as IntegrationCategory[];

  for (const cat of categories) {
    for (const app of SUPPORTED_INTEGRATIONS[cat]) {
      const connection = connections.find((c) => c.appId === app.id);
      integrations.push({
        id: app.id,
        name: app.name,
        icon: app.icon,
        category: cat,
        connected: connectedIds.has(app.id),
        status: connection?.status,
      });
    }
  }

  return { integrations };
}

// ============================================================================
// MOCK RESPONSES FOR DEVELOPMENT
// ============================================================================

function getMockResponse(appId: string, action: string, params: Record<string, unknown>): ComposioToolResponse {
  const mockResponses: Record<string, Record<string, () => unknown>> = {
    google_calendar: {
      list_events: () => ({
        events: [
          { id: '1', title: 'Team standup', start: '2024-01-15T09:00:00Z', end: '2024-01-15T09:30:00Z' },
          { id: '2', title: 'Lunch with Sarah', start: '2024-01-15T12:00:00Z', end: '2024-01-15T13:00:00Z' },
        ],
      }),
      create_event: () => ({
        id: `event_${Date.now()}`,
        title: params.title,
        created: true,
      }),
    },
    spotify: {
      get_current_track: () => ({
        track: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        isPlaying: true,
      }),
      play: () => ({ playing: true }),
      pause: () => ({ playing: false }),
    },
    uber: {
      get_estimate: () => ({
        estimates: [
          { type: 'UberX', price: { min: 12, max: 16 }, eta: 4 },
          { type: 'UberXL', price: { min: 18, max: 24 }, eta: 7 },
        ],
      }),
      request_ride: () => ({
        rideId: `ride_${Date.now()}`,
        status: 'matching',
        eta: 5,
      }),
    },
    instacart: {
      search_products: () => ({
        products: [
          { id: '1', name: 'Organic Bananas', price: 2.99, store: 'Whole Foods' },
          { id: '2', name: 'Almond Milk', price: 4.49, store: 'Whole Foods' },
        ],
      }),
      add_to_cart: () => ({ added: true, cartTotal: 7.48 }),
    },
    fitbit: {
      get_steps: () => ({
        today: 6542,
        goal: 10000,
        weekAverage: 7234,
      }),
      get_sleep: () => ({
        lastNight: {
          duration: 7.5,
          quality: 'good',
          deepSleep: 1.5,
          remSleep: 2.0,
        },
      }),
    },
    smartthings: {
      list_devices: () => ({
        devices: [
          { id: 'd1', name: 'Living Room Light', type: 'light', status: 'on' },
          { id: 'd2', name: 'Thermostat', type: 'thermostat', status: 'heating', temp: 72 },
        ],
      }),
      control_device: () => ({ success: true }),
    },
  };

  const appMocks = mockResponses[appId];
  if (appMocks && appMocks[action]) {
    return { success: true, data: appMocks[action]() };
  }

  return {
    success: true,
    data: { message: `Mock response for ${appId}.${action}`, params },
  };
}

function getMockActions(appId: string): Array<{ name: string; description: string; params: Record<string, unknown> }> {
  const mockActions: Record<string, Array<{ name: string; description: string; params: Record<string, unknown> }>> = {
    google_calendar: [
      { name: 'list_events', description: 'List calendar events', params: { startDate: 'string', endDate: 'string' } },
      { name: 'create_event', description: 'Create a calendar event', params: { title: 'string', start: 'string', end: 'string' } },
      { name: 'delete_event', description: 'Delete a calendar event', params: { eventId: 'string' } },
    ],
    spotify: [
      { name: 'get_current_track', description: 'Get currently playing track', params: {} },
      { name: 'play', description: 'Resume playback', params: {} },
      { name: 'pause', description: 'Pause playback', params: {} },
      { name: 'search', description: 'Search for tracks', params: { query: 'string' } },
    ],
    uber: [
      { name: 'get_estimate', description: 'Get ride price estimates', params: { pickup: 'string', dropoff: 'string' } },
      { name: 'request_ride', description: 'Request a ride', params: { pickup: 'string', dropoff: 'string', type: 'string' } },
    ],
  };

  return mockActions[appId] || [];
}
