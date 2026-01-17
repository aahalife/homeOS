import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { startWorkflowRun } from '../services/temporal.js';

const WorkflowRunSchema = z.object({
  workspaceId: z.string().uuid(),
  workflowType: z.string().min(1),
  input: z.record(z.unknown()).optional(),
  triggerType: z.string().optional(),
  workflowId: z.string().optional(),
  taskQueue: z.string().optional(),
});

const ALLOWED_WORKFLOW_TYPES = new Set([
  'ChatTurnWorkflow',
  'ReservationCallWorkflow',
  'MarketplaceSellWorkflow',
  'HireHelperWorkflow',
  'DynamicIntegrationWorkflow',
  'DailyHomeworkCheckWorkflow',
  'GradeMonitoringWorkflow',
  'CreateStudyPlanWorkflow',
  'SchoolEventsSyncWorkflow',
  'BookDoctorAppointmentWorkflow',
  'MedicationReminderWorkflow',
  'HealthSummaryWorkflow',
  'BookRideWorkflow',
  'TrackFamilyLocationWorkflow',
  'CommuteAlertWorkflow',
  'MealPlanWorkflow',
  'GroceryListWorkflow',
  'RecipeSuggestionWorkflow',
  'ScheduleMaintenanceWorkflow',
  'MaintenanceReminderWorkflow',
  'EmergencyRepairWorkflow',
  'FamilyAnnouncementWorkflow',
  'SharedCalendarSyncWorkflow',
  'FamilyCheckInWorkflow',
  'DailyFamilyDigestWorkflow',
  'FamilyEmergencyAlertWorkflow',
  'HydrationReminderWorkflow',
  'MovementNudgeWorkflow',
  'SleepHygieneWorkflow',
  'ScreenTimeWorkflow',
  'PostureBreakWorkflow',
  'EnergyOptimizationWorkflow',
  'DailyWellnessCheckWorkflow',
  'FamilyDinnerWorkflow',
  'GameNightWorkflow',
  'WeekendActivityWorkflow',
  'GratitudeMomentWorkflow',
  'OneOnOneTimeWorkflow',
  'FamilyTraditionWorkflow',
  'MorningBriefingWorkflow',
  'WeeklyPlanningWorkflow',
  'ProactiveReminderWorkflow',
  'DecisionSimplificationWorkflow',
  'EveningWindDownWorkflow',
  'HouseholdCoordinationWorkflow',
]);

export const workflowsRoutes: FastifyPluginAsync = async (app) => {
  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.post(
    '/run',
    {
      schema: {
        description: 'Manually run a workflow',
        tags: ['workflows'],
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['workspaceId', 'workflowType'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            workflowType: { type: 'string' },
            input: { type: 'object', additionalProperties: true },
            triggerType: { type: 'string' },
            workflowId: { type: 'string' },
            taskQueue: { type: 'string' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              workflowId: { type: 'string' },
              runId: { type: 'string' },
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
      const user = request.user as { sub: string; workspaceId?: string };
      const body = WorkflowRunSchema.parse(request.body);

      if (!ALLOWED_WORKFLOW_TYPES.has(body.workflowType)) {
        return reply.status(403).send({ error: 'Workflow type not allowed' });
      }

      const tokenWorkspaceId = user.workspaceId;
      if (tokenWorkspaceId && tokenWorkspaceId !== body.workspaceId) {
        return reply.status(403).send({ error: 'Workspace mismatch' });
      }

      const input = {
        workspaceId: body.workspaceId,
        userId: (body.input as Record<string, unknown> | undefined)?.userId ?? user.sub,
        ...(body.input ?? {}),
      };

      const result = await startWorkflowRun({
        workspaceId: body.workspaceId,
        userId: user.sub,
        workflowType: body.workflowType,
        triggerType: body.triggerType ?? 'manual',
        workflowId: body.workflowId,
        taskQueue: body.taskQueue,
        input,
      });

      return result;
    }
  );
};
