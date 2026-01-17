/**
 * Telegram Gateway for HomeOS
 *
 * Allows users to chat with HomeOS agents via Telegram.
 * Users link their Telegram account to their HomeOS workspace,
 * then can send messages directly to the bot.
 */

import type { FastifyPluginAsync, FastifyReply } from 'fastify';
import { Connection, Client } from '@temporalio/client';
import { readFile } from 'node:fs/promises';
import { emitToWorkspace } from '../ws/stream.js';

const TEMPORAL_ADDRESS = process.env['TEMPORAL_ADDRESS'] ?? 'localhost:7233';
const TEMPORAL_NAMESPACE = process.env['TEMPORAL_NAMESPACE'] ?? 'default';
const TEMPORAL_API_KEY = process.env['TEMPORAL_API_KEY'];
const TELEGRAM_BOT_TOKEN = process.env['TELEGRAM_BOT_TOKEN'] ?? '';
const TELEGRAM_BOTS_CONFIG_PATH = process.env['TELEGRAM_BOTS_CONFIG_PATH'];
const TELEGRAM_API_URL = 'https://api.telegram.org';

// In-memory mapping for development (use database in production)
const telegramUserMappings = new Map<number, { workspaceId: string; userId: string }>();
const pendingLinkRequests = new Map<string, { telegramChatId: number; expiresAt: Date }>();

let temporalClient: Client | null = null;

async function getTemporalClient(): Promise<Client> {
  if (!temporalClient) {
    const isTemporalCloud = TEMPORAL_ADDRESS.includes('temporal.io');
    const connectionOptions: Parameters<typeof Connection.connect>[0] = {
      address: TEMPORAL_ADDRESS,
    };
    if (isTemporalCloud && TEMPORAL_API_KEY) {
      connectionOptions.tls = true;
      connectionOptions.apiKey = TEMPORAL_API_KEY;
    }
    const connection = await Connection.connect(connectionOptions);
    temporalClient = new Client({ connection, namespace: TEMPORAL_NAMESPACE });
  }
  return temporalClient;
}

function sendError(reply: FastifyReply, status: number, message: string) {
  return reply.status(status).send({ error: message });
}

interface TelegramMessage {
  message_id: number;
  from: {
    id: number;
    first_name: string;
    last_name?: string;
    username?: string;
  };
  chat: {
    id: number;
    type: 'private' | 'group' | 'supergroup' | 'channel';
    first_name?: string;
    last_name?: string;
    username?: string;
  };
  date: number;
  text?: string;
}

interface TelegramUpdate {
  update_id: number;
  message?: TelegramMessage;
}

interface TelegramBotConfig {
  id: string;
  token: string;
  username?: string;
  workspaces?: string[];
}

interface TelegramBotsConfigFile {
  defaultBotId?: string;
  bots: TelegramBotConfig[];
}

let botConfig: TelegramBotsConfigFile | null = null;

async function loadBotConfig(): Promise<TelegramBotsConfigFile | null> {
  if (!TELEGRAM_BOTS_CONFIG_PATH) {
    return null;
  }
  try {
    const raw = await readFile(TELEGRAM_BOTS_CONFIG_PATH, 'utf-8');
    return JSON.parse(raw) as TelegramBotsConfigFile;
  } catch (error) {
    console.error('[Telegram] Failed to load bot config:', error);
    return null;
  }
}

async function ensureBotConfig(): Promise<void> {
  if (!botConfig && TELEGRAM_BOTS_CONFIG_PATH) {
    botConfig = await loadBotConfig();
  }
}

async function resolveBotForWorkspace(workspaceId?: string, botId?: string): Promise<TelegramBotConfig | null> {
  await ensureBotConfig();

  if (botConfig) {
    if (botId) {
      const byId = botConfig.bots.find((bot) => bot.id === botId);
      if (byId) {
        return byId;
      }
    }

    if (workspaceId) {
      const mapped = botConfig.bots.find((bot) => bot.workspaces?.includes(workspaceId));
      if (mapped) {
        return mapped;
      }
    }

    const fallbackId = botConfig.defaultBotId;
    if (fallbackId) {
      const fallback = botConfig.bots.find((bot) => bot.id === fallbackId);
      if (fallback) {
        return fallback;
      }
    }

    if (botConfig.bots.length > 0) {
      return botConfig.bots[0]!;
    }
  }

  if (TELEGRAM_BOT_TOKEN) {
    return { id: 'default', token: TELEGRAM_BOT_TOKEN };
  }

  return null;
}

async function getBotUsername(bot: TelegramBotConfig): Promise<string> {
  if (bot.username) {
    return bot.username;
  }

  try {
    const response = await fetch(`${TELEGRAM_API_URL}/bot${bot.token}/getMe`);
    const data = await response.json() as { ok: boolean; result?: { username: string } };
    if (data.ok && data.result?.username) {
      return data.result.username;
    }
  } catch {
    // Ignore
  }

  return 'HomeOSBot';
}

async function sendTelegramMessage(
  bot: TelegramBotConfig,
  chatId: number,
  text: string,
  replyToMessageId?: number
): Promise<boolean> {
  if (!bot.token) {
    console.warn('[Telegram] Bot token not configured');
    return false;
  }

  try {
    const response = await fetch(`${TELEGRAM_API_URL}/bot${bot.token}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: chatId,
        text,
        reply_to_message_id: replyToMessageId,
        parse_mode: 'Markdown',
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('[Telegram] Send message error:', error);
      return false;
    }

    return true;
  } catch (error) {
    console.error('[Telegram] Send message failed:', error);
    return false;
  }
}

export const telegramRoutes: FastifyPluginAsync = async (app) => {
  // Webhook endpoint (no auth required - Telegram calls this directly)
  app.post(
    '/webhook',
    {
      schema: {
        description: 'Telegram webhook endpoint',
        tags: ['telegram'],
        querystring: {
          type: 'object',
          properties: {
            botId: { type: 'string' },
          },
        },
        body: {
          type: 'object',
          properties: {
            update_id: { type: 'number' },
            message: { type: 'object' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              ok: { type: 'boolean' },
            },
          },
        },
      },
    },
    async (request) => {
      const update = request.body as TelegramUpdate;
      const { botId } = request.query as { botId?: string };
      const bot = await resolveBotForWorkspace(undefined, botId);

      if (!bot) {
        return { ok: true };
      }

      if (!update.message?.text) {
        return { ok: true };
      }

      const { message } = update;
      const chatId = message.chat.id;
      const text = message.text?.trim() ?? '';
      const username = message.from.username || message.from.first_name;

      app.log.info({ chatId, username, text: text.substring(0, 50) }, 'Telegram message received');

      // Handle /start command
      if (text.startsWith('/start')) {
        const linkCode = text.split(' ')[1];

        if (linkCode && pendingLinkRequests.has(linkCode)) {
          // Complete linking process
          const linkRequest = pendingLinkRequests.get(linkCode)!;
          if (linkRequest.telegramChatId === 0 || linkRequest.telegramChatId === chatId) {
            // This is a fresh link request
            linkRequest.telegramChatId = chatId;
          }

          await sendTelegramMessage(
            bot,
            chatId,
            `*Welcome to HomeOS!* 🏠\n\nYour account is being linked. Please complete the setup in the HomeOS app.`
          );
          return { ok: true };
        }

        await sendTelegramMessage(
          bot,
          chatId,
          `*Welcome to HomeOS!* 🏠\n\nTo get started, please link your Telegram account in the HomeOS app:\n\n1. Open HomeOS app\n2. Go to Settings → Connections\n3. Tap "Connect Telegram"\n4. Scan the QR code or enter the code shown`
        );
        return { ok: true };
      }

      // Handle /link command
      if (text.startsWith('/link')) {
        const linkCode = text.split(' ')[1];

        if (!linkCode) {
          await sendTelegramMessage(
            bot,
            chatId,
            'Please provide a link code. Get one from the HomeOS app under Settings → Connections → Telegram.'
          );
          return { ok: true };
        }

        if (!pendingLinkRequests.has(linkCode)) {
          await sendTelegramMessage(
            bot,
            chatId,
            'Invalid or expired link code. Please generate a new one from the HomeOS app.'
          );
          return { ok: true };
        }

        const linkRequest = pendingLinkRequests.get(linkCode)!;

        if (linkRequest.expiresAt < new Date()) {
          pendingLinkRequests.delete(linkCode);
          await sendTelegramMessage(
            bot,
            chatId,
            'This link code has expired. Please generate a new one from the HomeOS app.'
          );
          return { ok: true };
        }

        linkRequest.telegramChatId = chatId;

        await sendTelegramMessage(
          bot,
          chatId,
          '✅ Account linking initiated! Please confirm in the HomeOS app to complete the connection.'
        );
        return { ok: true };
      }

      // Handle /help command
      if (text === '/help') {
        await sendTelegramMessage(
          bot,
          chatId,
          `*HomeOS Telegram Bot* 🏠\n\n` +
          `Available commands:\n` +
          `• /start - Get started with HomeOS\n` +
          `• /link <code> - Link your Telegram account\n` +
          `• /status - Check connection status\n` +
          `• /help - Show this help message\n\n` +
          `Once linked, just send any message to chat with your HomeOS assistant!`
        );
        return { ok: true };
      }

      // Handle /status command
      if (text === '/status') {
        const mapping = telegramUserMappings.get(chatId);
        if (mapping) {
          await sendTelegramMessage(
            bot,
            chatId,
            '✅ Your Telegram account is connected to HomeOS. Send any message to chat!'
          );
        } else {
          await sendTelegramMessage(
            bot,
            chatId,
            '❌ Your Telegram account is not connected. Use /start to learn how to connect.'
          );
        }
        return { ok: true };
      }

      // Check if user is linked
      const mapping = telegramUserMappings.get(chatId);

      if (!mapping) {
        await sendTelegramMessage(
          bot,
          chatId,
          'Your Telegram account is not linked to HomeOS yet. Use /start to learn how to connect.',
          message.message_id
        );
        return { ok: true };
      }

      // Send typing indicator
      await fetch(`${TELEGRAM_API_URL}/bot${bot.token}/sendChatAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          chat_id: chatId,
          action: 'typing',
        }),
      });

      // Process the message through HomeOS
      try {
        const client = await getTemporalClient();
        const workflowId = `telegram-chat-${mapping.workspaceId}-${Date.now()}`;

        const handle = await client.workflow.start('ChatTurnWorkflow', {
          taskQueue: 'homeos-workflows',
          workflowId,
          args: [
            {
              workspaceId: mapping.workspaceId,
              userId: mapping.userId,
              message: text,
              source: 'telegram',
              metadata: {
                telegramChatId: chatId,
                telegramMessageId: message.message_id,
                telegramUsername: username,
              },
            },
          ],
        });

        // Wait for workflow result (with timeout)
        const result = await Promise.race([
          handle.result(),
          new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout')), 60000)),
        ]) as { response: string };

        // Send response back to Telegram
        await sendTelegramMessage(bot, chatId, result.response, message.message_id);

        // Emit to WebSocket for iOS app sync
        emitToWorkspace(mapping.workspaceId, {
          type: 'chat.message.final',
          payload: {
            source: 'telegram',
            content: result.response,
            userMessage: text,
          },
        });
      } catch (error) {
        app.log.error({ error, chatId }, 'Failed to process Telegram message');
        await sendTelegramMessage(
          bot,
          chatId,
          'Sorry, I encountered an error processing your message. Please try again.',
          message.message_id
        );
      }

      return { ok: true };
    }
  );

  // Authenticated routes for managing Telegram connection
  app.register(async (authenticatedApp) => {
    authenticatedApp.addHook('onRequest', async (request, reply) => {
      try {
        await request.jwtVerify();
      } catch {
        return reply.status(401).send({ error: 'Unauthorized' });
      }
    });

    // Generate link code
    authenticatedApp.post(
      '/link',
      {
        schema: {
          description: 'Generate a Telegram link code',
          tags: ['telegram'],
          security: [{ bearerAuth: [] }],
          body: {
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
                linkCode: { type: 'string' },
                expiresAt: { type: 'string' },
                botUsername: { type: 'string' },
                deepLink: { type: 'string' },
              },
            },
          },
        },
      },
      async (request, reply) => {
        const user = request.user as { sub: string };
        const { workspaceId } = request.body as { workspaceId: string };

        const bot = await resolveBotForWorkspace(workspaceId);
        if (!bot) {
          return sendError(reply, 503, 'Telegram bot not configured');
        }

        // Generate random link code
        const linkCode = Math.random().toString(36).substring(2, 10).toUpperCase();
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

        pendingLinkRequests.set(linkCode, {
          telegramChatId: 0, // Will be set when user sends /link command
          expiresAt,
        });

        // Also store the workspace/user mapping for this code
        // In production, store in database
        setTimeout(() => {
          pendingLinkRequests.delete(linkCode);
        }, 10 * 60 * 1000);

        const botUsername = await getBotUsername(bot);

        return {
          linkCode,
          expiresAt: expiresAt.toISOString(),
          botUsername,
          deepLink: `https://t.me/${botUsername}?start=${linkCode}`,
        };
      }
    );

    // Complete link (called after user clicks deep link)
    authenticatedApp.post(
      '/link/complete',
      {
        schema: {
          description: 'Complete Telegram account linking',
          tags: ['telegram'],
          security: [{ bearerAuth: [] }],
          body: {
            type: 'object',
            required: ['workspaceId', 'linkCode'],
            properties: {
              workspaceId: { type: 'string', format: 'uuid' },
              linkCode: { type: 'string' },
            },
          },
          response: {
            200: {
              type: 'object',
              properties: {
                success: { type: 'boolean' },
                telegramUsername: { type: 'string' },
              },
            },
          },
        },
      },
      async (request, reply) => {
        const user = request.user as { sub: string };
        const { workspaceId, linkCode } = request.body as { workspaceId: string; linkCode: string };
        const bot = await resolveBotForWorkspace(workspaceId);

        const linkRequest = pendingLinkRequests.get(linkCode);

        if (!linkRequest) {
          return sendError(reply, 400, 'Invalid or expired link code');
        }

        if (linkRequest.telegramChatId === 0) {
          return sendError(reply, 400, 'Telegram account not yet linked. Please click the link and send /link in Telegram first.');
        }

        if (linkRequest.expiresAt < new Date()) {
          pendingLinkRequests.delete(linkCode);
          return sendError(reply, 400, 'Link code has expired');
        }

        // Store the mapping
        telegramUserMappings.set(linkRequest.telegramChatId, {
          workspaceId,
          userId: user.sub,
        });

        // Clean up
        pendingLinkRequests.delete(linkCode);

        // Send confirmation to Telegram
        if (bot) {
          await sendTelegramMessage(
            bot,
            linkRequest.telegramChatId,
            '🎉 *Account linked successfully!*\n\nYou can now chat with HomeOS directly in Telegram. Just send any message!'
          );
        }

        return {
          success: true,
          telegramUsername: undefined, // Would get from stored data
        };
      }
    );

    // Get connection status
    authenticatedApp.get(
      '/status',
      {
        schema: {
          description: 'Get Telegram connection status',
          tags: ['telegram'],
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
              properties: {
                connected: { type: 'boolean' },
                telegramUsername: { type: 'string' },
                connectedAt: { type: 'string' },
              },
            },
          },
        },
      },
      async (request) => {
        const user = request.user as { sub: string };
        const { workspaceId } = request.query as { workspaceId: string };
        const bot = await resolveBotForWorkspace(workspaceId);

        // Check if user has a Telegram mapping
        for (const [chatId, mapping] of telegramUserMappings.entries()) {
          if (mapping.workspaceId === workspaceId && mapping.userId === user.sub) {
            return {
              connected: true,
              telegramUsername: undefined, // Would store this in database
            };
          }
        }

        return {
          connected: false,
        };
      }
    );

    // Disconnect Telegram
    authenticatedApp.delete(
      '/disconnect',
      {
        schema: {
          description: 'Disconnect Telegram account',
          tags: ['telegram'],
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
              properties: {
                success: { type: 'boolean' },
              },
            },
          },
        },
      },
      async (request) => {
        const user = request.user as { sub: string };
        const { workspaceId } = request.query as { workspaceId: string };

        // Find and remove the mapping
        for (const [chatId, mapping] of telegramUserMappings.entries()) {
          if (mapping.workspaceId === workspaceId && mapping.userId === user.sub) {
            telegramUserMappings.delete(chatId);

            // Notify user on Telegram
            if (bot) {
              await sendTelegramMessage(
                bot,
                chatId,
                '👋 Your HomeOS account has been disconnected. Use /start to reconnect.'
              );
            }

            return { success: true };
          }
        }

        return { success: true };
      }
    );
  });

  // Bot configuration status (no auth)
  app.get(
    '/bot-status',
    {
      schema: {
        description: 'Check if Telegram bot is configured',
        tags: ['telegram'],
        response: {
          200: {
            type: 'object',
            properties: {
              configured: { type: 'boolean' },
              botUsername: { type: 'string' },
            },
          },
        },
      },
    },
    async () => {
      const bot = await resolveBotForWorkspace();
      if (!bot) {
        return { configured: false };
      }

      const botUsername = await getBotUsername(bot);
      return {
        configured: true,
        botUsername,
      };
    }
  );
};
