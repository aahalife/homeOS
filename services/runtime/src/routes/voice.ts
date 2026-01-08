import type { FastifyPluginAsync, FastifyReply } from 'fastify';
import { z } from 'zod';
import { Readable } from 'stream';

// Helper to send error responses with proper typing
function sendError(reply: FastifyReply, status: number, message: string) {
  return reply.status(status).send({ error: message });
}

const OPENAI_API_KEY = process.env['OPENAI_API_KEY'] ?? '';
const ECHO_TTS_URL = process.env['ECHO_TTS_URL'] ?? 'https://homeos-echo-tts.fly.dev';

const TranscribeResponseSchema = z.object({
  text: z.string(),
});

export const voiceRoutes: FastifyPluginAsync = async (app) => {
  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  // Transcribe audio to text using Whisper API
  app.post(
    '/transcribe',
    {
      schema: {
        description: 'Transcribe audio to text using Whisper',
        tags: ['voice'],
        security: [{ bearerAuth: [] }],
        consumes: ['multipart/form-data'],
        response: {
          200: {
            type: 'object',
            properties: {
              text: { type: 'string' },
              duration: { type: 'number' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      if (!OPENAI_API_KEY) {
        return sendError(reply, 503, 'Speech recognition not configured');
      }

      // Get multipart data
      const data = await request.file();
      if (!data) {
        return sendError(reply, 400, 'No audio file provided');
      }

      const buffer = await data.toBuffer();

      try {
        // Call OpenAI Whisper API
        const formData = new FormData();
        formData.append('file', new Blob([buffer], { type: data.mimetype }), data.filename || 'audio.wav');
        formData.append('model', 'whisper-1');
        formData.append('language', 'en');

        const response = await fetch('https://api.openai.com/v1/audio/transcriptions', {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${OPENAI_API_KEY}`,
          },
          body: formData,
        });

        if (!response.ok) {
          const errorText = await response.text();
          app.log.error({ err: errorText }, 'Whisper API error');
          return sendError(reply, 500, 'Transcription failed');
        }

        const result = TranscribeResponseSchema.parse(await response.json());

        return {
          text: result.text,
          duration: buffer.length / (16000 * 2), // Approximate duration for 16kHz mono audio
        };
      } catch (error) {
        app.log.error({ err: error }, 'Transcription error');
        return sendError(reply, 500, 'Transcription failed');
      }
    }
  );

  // Synthesize text to speech using Echo-TTS service
  app.post(
    '/synthesize',
    {
      schema: {
        description: 'Synthesize text to speech using cloned or default voice',
        tags: ['voice'],
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['text'],
          properties: {
            text: { type: 'string', maxLength: 5000 },
            voiceProfileId: { type: 'string' },
            useDefault: { type: 'boolean', default: false },
          },
        },
      },
    },
    async (request, reply) => {
      const { text, voiceProfileId, useDefault } = request.body as {
        text: string;
        voiceProfileId?: string;
        useDefault?: boolean;
      };

      // Get the authorization header to forward to Echo-TTS
      const authHeader = request.headers.authorization;
      if (!authHeader) {
        return sendError(reply, 401, 'Missing authorization');
      }

      try {
        const response = await fetch(`${ECHO_TTS_URL}/synthesize`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: authHeader,
          },
          body: JSON.stringify({
            text,
            voice_profile_id: voiceProfileId,
            use_default: useDefault ?? !voiceProfileId,
          }),
        });

        if (!response.ok) {
          const errorText = await response.text();
          app.log.error({ err: errorText }, 'Echo-TTS API error');
          return sendError(reply, 500, 'Speech synthesis failed');
        }

        // Stream the audio back to the client
        const audioBuffer = await response.arrayBuffer();
        return reply
          .header('Content-Type', 'audio/mpeg')
          .header('Content-Length', audioBuffer.byteLength)
          .send(Buffer.from(audioBuffer));
      } catch (error) {
        app.log.error({ err: error }, 'Speech synthesis error');
        return sendError(reply, 500, 'Speech synthesis failed');
      }
    }
  );

  // Stream synthesized speech (lower latency)
  app.post(
    '/synthesize/stream',
    {
      schema: {
        description: 'Stream synthesized speech for lower latency',
        tags: ['voice'],
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['text'],
          properties: {
            text: { type: 'string', maxLength: 5000 },
            voiceProfileId: { type: 'string' },
            useDefault: { type: 'boolean', default: false },
          },
        },
      },
    },
    async (request, reply) => {
      const { text, voiceProfileId, useDefault } = request.body as {
        text: string;
        voiceProfileId?: string;
        useDefault?: boolean;
      };

      const authHeader = request.headers.authorization;
      if (!authHeader) {
        return sendError(reply, 401, 'Missing authorization');
      }

      try {
        const response = await fetch(`${ECHO_TTS_URL}/synthesize/stream`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: authHeader,
          },
          body: JSON.stringify({
            text,
            voice_profile_id: voiceProfileId,
            use_default: useDefault ?? !voiceProfileId,
          }),
        });

        if (!response.ok || !response.body) {
          return sendError(reply, 500, 'Speech synthesis failed');
        }

        // Stream the response
        reply.header('Content-Type', 'audio/mpeg');
        return reply.send(Readable.fromWeb(response.body as any));
      } catch (error) {
        app.log.error({ err: error }, 'Speech synthesis stream error');
        return sendError(reply, 500, 'Speech synthesis failed');
      }
    }
  );

  // Clone voice from audio recording
  app.post(
    '/clone',
    {
      schema: {
        description: 'Clone a voice from an audio recording (5-30 seconds)',
        tags: ['voice'],
        security: [{ bearerAuth: [] }],
        consumes: ['multipart/form-data'],
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              voiceProfile: { type: 'object' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const data = await request.file();
      if (!data) {
        return sendError(reply, 400, 'No audio file provided');
      }

      const fields = data.fields as Record<string, any>;
      const workspaceId = fields.workspaceId?.value;
      const name = fields.name?.value;

      if (!workspaceId || !name) {
        return sendError(reply, 400, 'Missing workspaceId or name');
      }

      const authHeader = request.headers.authorization;
      if (!authHeader) {
        return sendError(reply, 401, 'Missing authorization');
      }

      const buffer = await data.toBuffer();

      try {
        // Forward to Echo-TTS service
        const formData = new FormData();
        formData.append('audio', new Blob([buffer], { type: data.mimetype }), data.filename || 'recording.wav');
        formData.append('workspace_id', workspaceId);
        formData.append('name', name);

        const response = await fetch(`${ECHO_TTS_URL}/clone`, {
          method: 'POST',
          headers: {
            Authorization: authHeader,
          },
          body: formData,
        });

        if (!response.ok) {
          const errorText = await response.text();
          app.log.error({ err: errorText }, 'Voice clone error');
          return sendError(reply, 500, 'Voice cloning failed');
        }

        return await response.json();
      } catch (error) {
        app.log.error({ err: error }, 'Voice clone error');
        return sendError(reply, 500, 'Voice cloning failed');
      }
    }
  );

  // Clone voice from YouTube
  app.post(
    '/clone/youtube',
    {
      schema: {
        description: 'Clone a voice from a YouTube video',
        tags: ['voice'],
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['workspaceId', 'name', 'youtubeUrl'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            name: { type: 'string' },
            youtubeUrl: { type: 'string' },
            startTime: { type: 'integer', default: 0 },
            duration: { type: 'integer', default: 30 },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              voiceProfile: { type: 'object' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const body = request.body as {
        workspaceId: string;
        name: string;
        youtubeUrl: string;
        startTime?: number;
        duration?: number;
      };

      const authHeader = request.headers.authorization;
      if (!authHeader) {
        return sendError(reply, 401, 'Missing authorization');
      }

      try {
        const response = await fetch(`${ECHO_TTS_URL}/clone/youtube`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: authHeader,
          },
          body: JSON.stringify({
            workspace_id: body.workspaceId,
            name: body.name,
            youtube_url: body.youtubeUrl,
            start_time: body.startTime ?? 0,
            duration: body.duration ?? 30,
          }),
        });

        if (!response.ok) {
          const errorText = await response.text();
          app.log.error({ err: errorText }, 'YouTube voice clone error');
          return sendError(reply, 500, 'Voice cloning failed');
        }

        return await response.json();
      } catch (error) {
        app.log.error({ err: error }, 'YouTube voice clone error');
        return sendError(reply, 500, 'Voice cloning failed');
      }
    }
  );

  // Search YouTube for celebrity clips
  app.get(
    '/youtube/search',
    {
      schema: {
        description: 'Search YouTube for videos to clone voice from',
        tags: ['voice'],
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          required: ['query'],
          properties: {
            query: { type: 'string' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              videos: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    title: { type: 'string' },
                    url: { type: 'string' },
                    thumbnail: { type: 'string' },
                    duration: { type: 'number' },
                    channel: { type: 'string' },
                  },
                },
              },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { query } = request.query as { query: string };

      const authHeader = request.headers.authorization;
      if (!authHeader) {
        return sendError(reply, 401, 'Missing authorization');
      }

      try {
        const response = await fetch(
          `${ECHO_TTS_URL}/youtube/search?query=${encodeURIComponent(query)}`,
          {
            headers: {
              Authorization: authHeader,
            },
          }
        );

        if (!response.ok) {
          return sendError(reply, 500, 'YouTube search failed');
        }

        return await response.json();
      } catch (error) {
        app.log.error({ err: error }, 'YouTube search error');
        return sendError(reply, 500, 'YouTube search failed');
      }
    }
  );

  // List voice profiles
  app.get(
    '/voices',
    {
      schema: {
        description: 'List voice profiles for a workspace',
        tags: ['voice'],
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
              voices: { type: 'array' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { workspaceId } = request.query as { workspaceId: string };

      const authHeader = request.headers.authorization;
      if (!authHeader) {
        return sendError(reply, 401, 'Missing authorization');
      }

      try {
        const response = await fetch(
          `${ECHO_TTS_URL}/voices?workspace_id=${workspaceId}`,
          {
            headers: {
              Authorization: authHeader,
            },
          }
        );

        if (!response.ok) {
          return sendError(reply, 500, 'Failed to list voices');
        }

        return await response.json();
      } catch (error) {
        app.log.error({ err: error }, 'List voices error');
        return sendError(reply, 500, 'Failed to list voices');
      }
    }
  );

  // List default voices
  app.get(
    '/voices/defaults',
    {
      schema: {
        description: 'List available default voices',
        tags: ['voice'],
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            type: 'object',
            properties: {
              voices: { type: 'array' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const authHeader = request.headers.authorization;
      if (!authHeader) {
        return sendError(reply, 401, 'Missing authorization');
      }

      try {
        const response = await fetch(`${ECHO_TTS_URL}/voices/defaults`, {
          headers: {
            Authorization: authHeader,
          },
        });

        if (!response.ok) {
          return sendError(reply, 500, 'Failed to list default voices');
        }

        return await response.json();
      } catch (error) {
        app.log.error({ err: error }, 'List default voices error');
        return sendError(reply, 500, 'Failed to list default voices');
      }
    }
  );

  // Delete a voice profile
  app.delete(
    '/voices/:voiceId',
    {
      schema: {
        description: 'Delete a cloned voice profile',
        tags: ['voice'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['voiceId'],
          properties: {
            voiceId: { type: 'string' },
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
      const { voiceId } = request.params as { voiceId: string };

      const authHeader = request.headers.authorization;
      if (!authHeader) {
        return sendError(reply, 401, 'Missing authorization');
      }

      try {
        const response = await fetch(`${ECHO_TTS_URL}/voices/${voiceId}`, {
          method: 'DELETE',
          headers: {
            Authorization: authHeader,
          },
        });

        if (!response.ok) {
          return sendError(reply, 500, 'Failed to delete voice');
        }

        return await response.json();
      } catch (error) {
        app.log.error({ err: error }, 'Delete voice error');
        return sendError(reply, 500, 'Failed to delete voice');
      }
    }
  );
};
