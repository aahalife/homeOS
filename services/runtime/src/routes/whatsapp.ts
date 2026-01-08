/**
 * WhatsApp Gateway for HomeOS
 *
 * Allows users to chat with HomeOS agents via WhatsApp.
 * Uses Twilio's WhatsApp Business API for messaging.
 */

import type { FastifyPluginAsync, FastifyReply } from 'fastify';
import { Connection, Client } from '@temporalio/client';
import { emitToWorkspace } from '../ws/stream.js';

const TEMPORAL_ADDRESS = process.env['TEMPORAL_ADDRESS'] ?? 'localhost:7233';
const TWILIO_ACCOUNT_SID = process.env['TWILIO_ACCOUNT_SID'] ?? '';
const TWILIO_AUTH_TOKEN = process.env['TWILIO_AUTH_TOKEN'] ?? '';
const TWILIO_WHATSAPP_NUMBER = process.env['TWILIO_WHATSAPP_NUMBER'] ?? '';

// In-memory mapping for development (use database in production)
const whatsappUserMappings = new Map<string, { workspaceId: string; userId: string }>();
const pendingLinkRequests = new Map<string, { whatsappNumber: string; expiresAt: Date }>();

let temporalClient: Client | null = null;

async function getTemporalClient(): Promise<Client> {
  if (!temporalClient) {
    const connection = await Connection.connect({ address: TEMPORAL_ADDRESS });
    temporalClient = new Client({ connection });
  }
  return temporalClient;
}

function sendError(reply: FastifyReply, status: number, message: string) {
  return reply.status(status).send({ error: message });
}

async function sendWhatsAppMessage(to: string, message: string): Promise<boolean> {
  if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !TWILIO_WHATSAPP_NUMBER) {
    console.warn('[WhatsApp] Twilio credentials not configured');
    return false;
  }

  try {
    const response = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': `Basic ${Buffer.from(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`).toString('base64')}`,
        },
        body: new URLSearchParams({
          From: `whatsapp:${TWILIO_WHATSAPP_NUMBER}`,
          To: `whatsapp:${to}`,
          Body: message,
        }),
      }
    );

    if (!response.ok) {
      const error = await response.text();
      console.error('[WhatsApp] Send message error:', error);
      return false;
    }

    return true;
  } catch (error) {
    console.error('[WhatsApp] Send message failed:', error);
    return false;
  }
}

interface TwilioWebhookBody {
  MessageSid: string;
  AccountSid: string;
  From: string;
  To: string;
  Body: string;
  NumMedia: string;
  ProfileName?: string;
}

export const whatsappRoutes: FastifyPluginAsync = async (app) => {
  // Twilio webhook endpoint (no auth required - Twilio calls this directly)
  app.post(
    '/webhook',
    {
      schema: {
        description: 'Twilio WhatsApp webhook endpoint',
        tags: ['whatsapp'],
        body: {
          type: 'object',
          properties: {
            MessageSid: { type: 'string' },
            From: { type: 'string' },
            To: { type: 'string' },
            Body: { type: 'string' },
          },
        },
        response: {
          200: {
            type: 'string',
          },
        },
      },
    },
    async (request, reply) => {
      const body = request.body as TwilioWebhookBody;
      const from = body.From.replace('whatsapp:', '');
      const text = body.Body?.trim() ?? '';
      const profileName = body.ProfileName ?? from;

      app.log.info({ from, text: text.substring(0, 50), profileName }, 'WhatsApp message received');

      // Verify the webhook is from Twilio (in production, verify signature)
      if (body.AccountSid && body.AccountSid !== TWILIO_ACCOUNT_SID) {
        app.log.warn('Invalid Twilio webhook signature');
        return sendTwiMLResponse(reply);
      }

      // Handle link command
      if (text.toLowerCase().startsWith('link ')) {
        const linkCode = text.substring(5).trim().toUpperCase();

        if (!pendingLinkRequests.has(linkCode)) {
          await sendWhatsAppMessage(
            from,
            'Invalid or expired link code. Please generate a new one from the HomeOS app.'
          );
          return sendTwiMLResponse(reply);
        }

        const linkRequest = pendingLinkRequests.get(linkCode)!;

        if (linkRequest.expiresAt < new Date()) {
          pendingLinkRequests.delete(linkCode);
          await sendWhatsAppMessage(
            from,
            'This link code has expired. Please generate a new one from the HomeOS app.'
          );
          return sendTwiMLResponse(reply);
        }

        linkRequest.whatsappNumber = from;

        await sendWhatsAppMessage(
          from,
          '✅ Account linking initiated! Please confirm in the HomeOS app to complete the connection.'
        );
        return sendTwiMLResponse(reply);
      }

      // Handle help command
      if (text.toLowerCase() === 'help') {
        await sendWhatsAppMessage(
          from,
          `*HomeOS WhatsApp Bot* 🏠\n\n` +
          `Available commands:\n` +
          `• link <code> - Link your WhatsApp to HomeOS\n` +
          `• status - Check connection status\n` +
          `• help - Show this help message\n\n` +
          `Once linked, just send any message to chat with your HomeOS assistant!`
        );
        return sendTwiMLResponse(reply);
      }

      // Handle status command
      if (text.toLowerCase() === 'status') {
        const mapping = whatsappUserMappings.get(from);
        if (mapping) {
          await sendWhatsAppMessage(
            from,
            '✅ Your WhatsApp is connected to HomeOS. Send any message to chat!'
          );
        } else {
          await sendWhatsAppMessage(
            from,
            '❌ Your WhatsApp is not connected. To connect:\n\n1. Open HomeOS app\n2. Go to Settings → Connections\n3. Tap "Connect WhatsApp"\n4. Send "link <code>" here with the code shown'
          );
        }
        return sendTwiMLResponse(reply);
      }

      // Check if user is linked
      const mapping = whatsappUserMappings.get(from);

      if (!mapping) {
        await sendWhatsAppMessage(
          from,
          'Your WhatsApp is not linked to HomeOS yet. Send "help" for instructions on how to connect.'
        );
        return sendTwiMLResponse(reply);
      }

      // Process the message through HomeOS
      try {
        const client = await getTemporalClient();
        const workflowId = `whatsapp-chat-${mapping.workspaceId}-${Date.now()}`;

        const handle = await client.workflow.start('ChatTurnWorkflow', {
          taskQueue: 'homeos-workflows',
          workflowId,
          args: [
            {
              workspaceId: mapping.workspaceId,
              userId: mapping.userId,
              message: text,
              source: 'whatsapp',
              metadata: {
                whatsappNumber: from,
                profileName,
                messageSid: body.MessageSid,
              },
            },
          ],
        });

        // Wait for workflow result (with timeout)
        const result = await Promise.race([
          handle.result(),
          new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout')), 60000)),
        ]) as { response: string };

        // Send response back to WhatsApp
        await sendWhatsAppMessage(from, result.response);

        // Emit to WebSocket for iOS app sync
        emitToWorkspace(mapping.workspaceId, {
          type: 'chat.message.final',
          payload: {
            source: 'whatsapp',
            content: result.response,
            userMessage: text,
          },
        });
      } catch (error) {
        app.log.error({ error, from }, 'Failed to process WhatsApp message');
        await sendWhatsAppMessage(
          from,
          'Sorry, I encountered an error processing your message. Please try again.'
        );
      }

      return sendTwiMLResponse(reply);
    }
  );

  // Authenticated routes for managing WhatsApp connection
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
          description: 'Generate a WhatsApp link code',
          tags: ['whatsapp'],
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
                whatsappNumber: { type: 'string' },
                instructions: { type: 'string' },
              },
            },
          },
        },
      },
      async (request, reply) => {
        if (!TWILIO_WHATSAPP_NUMBER) {
          return sendError(reply, 503, 'WhatsApp not configured');
        }

        const { workspaceId } = request.body as { workspaceId: string };

        // Generate random link code
        const linkCode = Math.random().toString(36).substring(2, 8).toUpperCase();
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

        pendingLinkRequests.set(linkCode, {
          whatsappNumber: '', // Will be set when user sends link command
          expiresAt,
        });

        // Cleanup after expiry
        setTimeout(() => {
          pendingLinkRequests.delete(linkCode);
        }, 10 * 60 * 1000);

        return {
          linkCode,
          expiresAt: expiresAt.toISOString(),
          whatsappNumber: TWILIO_WHATSAPP_NUMBER,
          instructions: `Send "link ${linkCode}" to ${TWILIO_WHATSAPP_NUMBER} on WhatsApp`,
        };
      }
    );

    // Complete link (called after user sends link message)
    authenticatedApp.post(
      '/link/complete',
      {
        schema: {
          description: 'Complete WhatsApp account linking',
          tags: ['whatsapp'],
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
                whatsappNumber: { type: 'string' },
              },
            },
          },
        },
      },
      async (request, reply) => {
        const user = request.user as { sub: string };
        const { workspaceId, linkCode } = request.body as { workspaceId: string; linkCode: string };

        const linkRequest = pendingLinkRequests.get(linkCode.toUpperCase());

        if (!linkRequest) {
          return sendError(reply, 400, 'Invalid or expired link code');
        }

        if (!linkRequest.whatsappNumber) {
          return sendError(reply, 400, 'WhatsApp number not yet received. Please send the link message on WhatsApp first.');
        }

        if (linkRequest.expiresAt < new Date()) {
          pendingLinkRequests.delete(linkCode.toUpperCase());
          return sendError(reply, 400, 'Link code has expired');
        }

        // Store the mapping
        whatsappUserMappings.set(linkRequest.whatsappNumber, {
          workspaceId,
          userId: user.sub,
        });

        // Clean up
        pendingLinkRequests.delete(linkCode.toUpperCase());

        // Send confirmation to WhatsApp
        await sendWhatsAppMessage(
          linkRequest.whatsappNumber,
          '🎉 *Account linked successfully!*\n\nYou can now chat with HomeOS directly on WhatsApp. Just send any message!'
        );

        return {
          success: true,
          whatsappNumber: linkRequest.whatsappNumber,
        };
      }
    );

    // Get connection status
    authenticatedApp.get(
      '/status',
      {
        schema: {
          description: 'Get WhatsApp connection status',
          tags: ['whatsapp'],
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
                whatsappNumber: { type: 'string' },
              },
            },
          },
        },
      },
      async (request) => {
        const user = request.user as { sub: string };
        const { workspaceId } = request.query as { workspaceId: string };

        // Check if user has a WhatsApp mapping
        for (const [number, mapping] of whatsappUserMappings.entries()) {
          if (mapping.workspaceId === workspaceId && mapping.userId === user.sub) {
            return {
              connected: true,
              whatsappNumber: number,
            };
          }
        }

        return {
          connected: false,
        };
      }
    );

    // Disconnect WhatsApp
    authenticatedApp.delete(
      '/disconnect',
      {
        schema: {
          description: 'Disconnect WhatsApp account',
          tags: ['whatsapp'],
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
        for (const [number, mapping] of whatsappUserMappings.entries()) {
          if (mapping.workspaceId === workspaceId && mapping.userId === user.sub) {
            whatsappUserMappings.delete(number);

            // Notify user on WhatsApp
            await sendWhatsAppMessage(
              number,
              '👋 Your HomeOS account has been disconnected. Send "help" to reconnect.'
            );

            return { success: true };
          }
        }

        return { success: true };
      }
    );
  });

  // Service status (no auth)
  app.get(
    '/service-status',
    {
      schema: {
        description: 'Check if WhatsApp service is configured',
        tags: ['whatsapp'],
        response: {
          200: {
            type: 'object',
            properties: {
              configured: { type: 'boolean' },
              whatsappNumber: { type: 'string' },
            },
          },
        },
      },
    },
    async () => {
      if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !TWILIO_WHATSAPP_NUMBER) {
        return { configured: false };
      }

      return {
        configured: true,
        whatsappNumber: TWILIO_WHATSAPP_NUMBER,
      };
    }
  );
};

function sendTwiMLResponse(reply: FastifyReply) {
  reply.header('Content-Type', 'text/xml');
  return reply.send('<?xml version="1.0" encoding="UTF-8"?><Response></Response>');
}
