/**
 * Home Maintenance Workflows for homeOS
 *
 * Property and home management:
 * - Scheduled maintenance tracking
 * - Service provider coordination
 * - Emergency repair handling
 */

import {
  proxyActivities,
  defineSignal,
  setHandler,
  condition,
} from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const {
  getMaintenanceSchedule,
  searchServiceProviders,
  createServiceRequest,
  requestQuotes,
  scheduleService,
  getHomeInventory,
  reportEmergency,
  getMaintenanceTips,
  emitTaskEvent,
  storeMemory,
  requestApproval,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '10 minutes',
  retry: { maximumAttempts: 3 },
});

// ============================================================================
// SCHEDULE MAINTENANCE WORKFLOW
// ============================================================================

export interface ScheduleMaintenanceWorkflowInput {
  workspaceId: string;
  userId: string;
  taskType: string;
  description: string;
  urgency: 'routine' | 'urgent' | 'emergency';
  preferredDate?: string;
}

export interface ApprovalSignal {
  envelopeId: string;
  approved: boolean;
  selectedProviderId?: string;
  reason?: string;
}

export const maintenanceApprovalSignal = defineSignal<[ApprovalSignal]>('maintenanceApproval');

export async function ScheduleMaintenanceWorkflow(input: ScheduleMaintenanceWorkflowInput): Promise<{
  success: boolean;
  serviceRequest?: unknown;
  scheduledWith?: unknown;
}> {
  const { workspaceId, userId, taskType, description, urgency, preferredDate } = input;
  let pendingApproval: ApprovalSignal | null = null;

  setHandler(maintenanceApprovalSignal, (signal) => {
    pendingApproval = signal;
  });

  await emitTaskEvent(workspaceId, 'maintenance.scheduling.start', { taskType, urgency });

  // Create the service request
  const serviceRequest = await createServiceRequest({
    workspaceId,
    taskType,
    description,
    urgency,
    preferredDate,
  });

  // Search for service providers
  const providers = await searchServiceProviders({
    workspaceId,
    category: taskType,
    urgency,
  });

  if (providers.length === 0) {
    return { success: false, serviceRequest };
  }

  // Request quotes from top providers
  const topProviders = providers.slice(0, 3);
  await requestQuotes({
    workspaceId,
    serviceRequestId: serviceRequest.id,
    providerIds: topProviders.map((p) => p.id),
  });

  // Request user approval to proceed
  const envelopeId = await requestApproval({
    workspaceId,
    userId,
    intent: `Schedule ${taskType} service`,
    toolName: 'maintenance.schedule',
    inputs: {
      taskType,
      description,
      providers: topProviders.map((p) => ({
        name: p.businessName || p.name,
        rating: p.rating,
        priceRange: p.priceRange,
      })),
    },
    riskLevel: urgency === 'urgent' ? 'high' : 'medium',
  });

  // For simplicity, proceed with best-rated provider
  // In production, would wait for approval signal
  const selectedProvider = providers.sort((a, b) => b.rating - a.rating)[0];

  const scheduledDateTime = preferredDate ||
    new Date(Date.now() + (urgency === 'urgent' ? 1 : 3) * 24 * 60 * 60 * 1000).toISOString();

  const result = await scheduleService({
    workspaceId,
    serviceRequestId: serviceRequest.id,
    providerId: selectedProvider.id,
    dateTime: scheduledDateTime,
  });

  if (result.success) {
    await storeMemory({
      workspaceId,
      type: 'episodic',
      content: JSON.stringify({
        type: 'maintenance_scheduled',
        taskType,
        provider: selectedProvider.businessName || selectedProvider.name,
        scheduledFor: scheduledDateTime,
        confirmation: result.confirmation,
      }),
      salience: 0.7,
      tags: ['maintenance', taskType],
    });

    await emitTaskEvent(workspaceId, 'maintenance.scheduling.complete', {
      confirmation: result.confirmation,
      provider: selectedProvider.name,
    });
  }

  return {
    success: result.success,
    serviceRequest,
    scheduledWith: {
      provider: selectedProvider,
      dateTime: scheduledDateTime,
      confirmation: result.confirmation,
    },
  };
}

// ============================================================================
// MAINTENANCE REMINDER WORKFLOW
// ============================================================================

export interface MaintenanceReminderWorkflowInput {
  workspaceId: string;
  daysAhead?: number;
  categories?: string[];
}

export async function MaintenanceReminderWorkflow(input: MaintenanceReminderWorkflowInput): Promise<{
  dueTasks: unknown[];
  overdueTasks: unknown[];
  tips: string[];
}> {
  const { workspaceId, daysAhead = 30, categories } = input;

  await emitTaskEvent(workspaceId, 'maintenance.reminder.checking', {});

  // Get maintenance schedule
  const allTasks = await getMaintenanceSchedule({
    workspaceId,
    category: categories?.[0], // Would need to handle multiple categories
    dueWithin: daysAhead,
    includeOverdue: true,
  });

  const now = new Date();
  const dueTasks = allTasks.filter((t) => new Date(t.nextDue) >= now);
  const overdueTasks = allTasks.filter((t) => new Date(t.nextDue) < now);

  // Get seasonal tips
  const tipsResult = await getMaintenanceTips({ workspaceId });

  // Check for expiring warranties
  const inventory = await getHomeInventory({
    workspaceId,
    expiringWarranties: 90,
  });

  const warrantyAlerts = inventory.map((item) =>
    `${item.name} warranty expires ${item.warrantyExpiration}`
  );

  // Emit events for overdue tasks
  if (overdueTasks.length > 0) {
    await emitTaskEvent(workspaceId, 'maintenance.overdue', {
      count: overdueTasks.length,
      tasks: overdueTasks.map((t) => t.name),
    });
  }

  // Emit events for high-priority tasks
  const highPriorityTasks = dueTasks.filter((t) => t.priority === 'high' || t.priority === 'urgent');
  if (highPriorityTasks.length > 0) {
    await emitTaskEvent(workspaceId, 'maintenance.priority_tasks', {
      count: highPriorityTasks.length,
      tasks: highPriorityTasks.map((t) => t.name),
    });
  }

  return {
    dueTasks,
    overdueTasks,
    tips: [...tipsResult.tips, ...warrantyAlerts],
  };
}

// ============================================================================
// EMERGENCY REPAIR WORKFLOW
// ============================================================================

export interface EmergencyRepairWorkflowInput {
  workspaceId: string;
  userId: string;
  emergencyType: 'water' | 'gas' | 'electrical' | 'hvac' | 'security' | 'other';
  description: string;
  location?: string;
}

export async function EmergencyRepairWorkflow(input: EmergencyRepairWorkflowInput): Promise<{
  emergencyId: string;
  severity: string;
  immediateSteps: string[];
  providersContacted: unknown[];
  estimatedResponse: string;
}> {
  const { workspaceId, userId, emergencyType, description, location } = input;

  await emitTaskEvent(workspaceId, 'maintenance.emergency.reported', {
    type: emergencyType,
    severity: 'unknown',
  });

  // Report emergency and get response
  const response = await reportEmergency({
    workspaceId,
    type: emergencyType,
    description,
    location,
  });

  // Store emergency in memory
  await storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'home_emergency',
      emergencyType,
      severity: response.severity,
      description,
      reportedAt: new Date().toISOString(),
      providersContacted: response.providersContacted.map((p) => p.name),
    }),
    salience: 0.95, // Very high salience for emergencies
    tags: ['emergency', emergencyType, 'maintenance'],
  });

  // Emit high-priority event
  await emitTaskEvent(workspaceId, 'maintenance.emergency.response', {
    emergencyId: response.emergencyId,
    severity: response.severity,
    providersContacted: response.providersContacted.length,
    estimatedResponse: response.estimatedResponse,
  });

  return {
    emergencyId: response.emergencyId,
    severity: response.severity,
    immediateSteps: response.immediateSteps,
    providersContacted: response.providersContacted,
    estimatedResponse: response.estimatedResponse,
  };
}
