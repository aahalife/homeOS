import type { FastifyPluginAsync } from 'fastify';
import { emitToWorkspace } from '../ws/stream.js';

// In-memory task storage (in production, use database)
const tasksStore = new Map<string, Map<string, TaskRecord>>();

interface TaskRecord {
  taskId: string;
  workspaceId: string;
  title: string;
  category: string;
  status: 'queued' | 'running' | 'needs_approval' | 'blocked' | 'done' | 'failed';
  riskLevel: 'low' | 'medium' | 'high';
  requiresApproval: boolean;
  summaryForUser: string;
  details?: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
}

export const tasksRoutes: FastifyPluginAsync = async (app) => {
  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.get(
    '/',
    {
      schema: {
        description: 'List tasks for workspace',
        tags: ['tasks'],
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            status: {
              type: 'string',
              enum: ['queued', 'running', 'needs_approval', 'blocked', 'done', 'failed'],
            },
            limit: { type: 'integer', default: 20 },
            offset: { type: 'integer', default: 0 },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              tasks: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    taskId: { type: 'string' },
                    title: { type: 'string' },
                    category: { type: 'string' },
                    status: { type: 'string' },
                    riskLevel: { type: 'string' },
                    requiresApproval: { type: 'boolean' },
                    summaryForUser: { type: 'string' },
                    createdAt: { type: 'string' },
                    updatedAt: { type: 'string' },
                  },
                },
              },
            },
          },
        },
      },
    },
    async (request) => {
      const { workspaceId, status, limit, offset } = request.query as {
        workspaceId: string;
        status?: string;
        limit: number;
        offset: number;
      };

      const workspaceTasks = tasksStore.get(workspaceId) || new Map();
      let tasks = Array.from(workspaceTasks.values());

      // Filter by status if provided
      if (status) {
        tasks = tasks.filter((t) => t.status === status);
      }

      // Sort by creation date (newest first)
      tasks.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

      // Apply pagination
      const paginatedTasks = tasks.slice(offset, offset + limit);

      return {
        tasks: paginatedTasks.map((t) => ({
          taskId: t.taskId,
          title: t.title,
          category: t.category,
          status: t.status,
          riskLevel: t.riskLevel,
          requiresApproval: t.requiresApproval,
          summaryForUser: t.summaryForUser,
          createdAt: t.createdAt.toISOString(),
          updatedAt: t.updatedAt.toISOString(),
        })),
      };
    }
  );

  app.get(
    '/:taskId',
    {
      schema: {
        description: 'Get task details',
        tags: ['tasks'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['taskId'],
          properties: {
            taskId: { type: 'string' },
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
              taskId: { type: 'string' },
              workspaceId: { type: 'string' },
              title: { type: 'string' },
              category: { type: 'string' },
              status: { type: 'string' },
              riskLevel: { type: 'string' },
              requiresApproval: { type: 'boolean' },
              summaryForUser: { type: 'string' },
              details: { type: 'object' },
              createdAt: { type: 'string' },
              updatedAt: { type: 'string' },
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
      const { taskId } = request.params as { taskId: string };
      const { workspaceId } = request.query as { workspaceId: string };

      const workspaceTasks = tasksStore.get(workspaceId);
      if (!workspaceTasks) {
        return reply.status(404).send({ error: 'Task not found' });
      }

      const task = workspaceTasks.get(taskId);
      if (!task) {
        return reply.status(404).send({ error: 'Task not found' });
      }

      return {
        taskId: task.taskId,
        workspaceId: task.workspaceId,
        title: task.title,
        category: task.category,
        status: task.status,
        riskLevel: task.riskLevel,
        requiresApproval: task.requiresApproval,
        summaryForUser: task.summaryForUser,
        details: task.details || {},
        createdAt: task.createdAt.toISOString(),
        updatedAt: task.updatedAt.toISOString(),
      };
    }
  );

  app.post(
    '/:taskId/approve',
    {
      schema: {
        description: 'Approve a task that requires approval',
        tags: ['tasks'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['taskId'],
          properties: {
            taskId: { type: 'string' },
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
              taskId: { type: 'string' },
              message: { type: 'string' },
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
      const { taskId } = request.params as { taskId: string };
      const { workspaceId } = request.query as { workspaceId: string };

      const workspaceTasks = tasksStore.get(workspaceId);
      if (!workspaceTasks) {
        return reply.status(404).send({ error: 'Task not found' });
      }

      const task = workspaceTasks.get(taskId);
      if (!task) {
        return reply.status(404).send({ error: 'Task not found' });
      }

      // Update task status
      task.status = 'running';
      task.updatedAt = new Date();
      workspaceTasks.set(taskId, task);

      // Emit WebSocket event
      emitToWorkspace(workspaceId, {
        type: 'task.approved',
        payload: { taskId, status: 'running' },
      });

      return {
        success: true,
        taskId,
        message: 'Task approved and running',
      };
    }
  );

  app.post(
    '/:taskId/deny',
    {
      schema: {
        description: 'Deny a task that requires approval',
        tags: ['tasks'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['taskId'],
          properties: {
            taskId: { type: 'string' },
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
          properties: {
            reason: { type: 'string', maxLength: 500 },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              taskId: { type: 'string' },
              message: { type: 'string' },
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
      const { taskId } = request.params as { taskId: string };
      const { workspaceId } = request.query as { workspaceId: string };
      const { reason } = request.body as { reason?: string };

      const workspaceTasks = tasksStore.get(workspaceId);
      if (!workspaceTasks) {
        return reply.status(404).send({ error: 'Task not found' });
      }

      const task = workspaceTasks.get(taskId);
      if (!task) {
        return reply.status(404).send({ error: 'Task not found' });
      }

      // Remove the task (denied tasks are removed)
      workspaceTasks.delete(taskId);

      // Emit WebSocket event
      emitToWorkspace(workspaceId, {
        type: 'task.denied',
        payload: { taskId, reason: reason || 'Denied by user' },
      });

      return {
        success: true,
        taskId,
        message: 'Task denied',
      };
    }
  );

  // Create a new task (for internal use by chat/workflows)
  app.post(
    '/',
    {
      schema: {
        description: 'Create a new task',
        tags: ['tasks'],
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['workspaceId', 'title', 'category'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            title: { type: 'string' },
            category: { type: 'string' },
            summaryForUser: { type: 'string' },
            riskLevel: { type: 'string', enum: ['low', 'medium', 'high'] },
            requiresApproval: { type: 'boolean' },
            details: { type: 'object' },
          },
        },
        response: {
          201: {
            type: 'object',
            properties: {
              taskId: { type: 'string' },
              status: { type: 'string' },
            },
          },
        },
      },
    },
    async (request) => {
      const body = request.body as {
        workspaceId: string;
        title: string;
        category: string;
        summaryForUser?: string;
        riskLevel?: 'low' | 'medium' | 'high';
        requiresApproval?: boolean;
        details?: Record<string, unknown>;
      };

      const taskId = crypto.randomUUID();
      const now = new Date();

      const task: TaskRecord = {
        taskId,
        workspaceId: body.workspaceId,
        title: body.title,
        category: body.category,
        status: body.requiresApproval ? 'needs_approval' : 'queued',
        riskLevel: body.riskLevel || 'low',
        requiresApproval: body.requiresApproval || false,
        summaryForUser: body.summaryForUser || body.title,
        details: body.details,
        createdAt: now,
        updatedAt: now,
      };

      // Store the task
      if (!tasksStore.has(body.workspaceId)) {
        tasksStore.set(body.workspaceId, new Map());
      }
      tasksStore.get(body.workspaceId)!.set(taskId, task);

      // Emit WebSocket event
      emitToWorkspace(body.workspaceId, {
        type: 'task.created',
        payload: {
          taskId: task.taskId,
          title: task.title,
          category: task.category,
          status: task.status,
          riskLevel: task.riskLevel,
          requiresApproval: task.requiresApproval,
          summaryForUser: task.summaryForUser,
        },
      });

      return {
        taskId,
        status: task.status,
      };
    }
  );
};
