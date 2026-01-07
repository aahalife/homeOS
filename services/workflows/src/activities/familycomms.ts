/**
 * Family Communication Activities for homeOS
 *
 * Family coordination and communication:
 * - Family announcements and messaging
 * - Shared calendar management
 * - Location check-ins
 * - Emergency contacts
 * - Chore/task assignments
 */

import Anthropic from '@anthropic-ai/sdk';

// ============================================================================
// TYPES
// ============================================================================

export interface FamilyMemberProfile {
  id: string;
  name: string;
  role: 'parent' | 'child' | 'other';
  email?: string;
  phone?: string;
  deviceId?: string;
  preferences?: {
    notificationMethod: 'push' | 'sms' | 'email';
    quietHoursStart?: string;
    quietHoursEnd?: string;
  };
}

export interface FamilyAnnouncement {
  id: string;
  title: string;
  message: string;
  priority: 'low' | 'normal' | 'high' | 'urgent';
  createdBy: string;
  createdAt: string;
  expiresAt?: string;
  recipients: string[]; // member IDs, or 'all'
  acknowledgements: { memberId: string; acknowledgedAt: string }[];
  attachments?: string[];
}

export interface FamilyEvent {
  id: string;
  title: string;
  description?: string;
  startTime: string;
  endTime?: string;
  location?: string;
  organizer: string;
  attendees: { memberId: string; status: 'pending' | 'accepted' | 'declined' }[];
  reminders: { minutesBefore: number; sent: boolean }[];
  recurring?: {
    frequency: 'daily' | 'weekly' | 'monthly';
    until?: string;
  };
  category: 'family' | 'school' | 'sports' | 'medical' | 'social' | 'other';
}

export interface ChoreAssignment {
  id: string;
  name: string;
  description?: string;
  assignedTo: string;
  dueDate?: string;
  recurring?: {
    frequency: 'daily' | 'weekly' | 'monthly';
    daysOfWeek?: number[];
  };
  status: 'pending' | 'in_progress' | 'completed' | 'overdue';
  points?: number; // For reward systems
  completedAt?: string;
}

export interface CheckIn {
  id: string;
  memberId: string;
  memberName: string;
  type: 'arrival' | 'departure' | 'safety' | 'custom';
  location?: string;
  message?: string;
  timestamp: string;
  acknowledgedBy?: string[];
}

// ============================================================================
// FAMILY MEMBERS
// ============================================================================

export interface GetFamilyMembersInput {
  workspaceId: string;
}

export async function getFamilyMembers(input: GetFamilyMembersInput): Promise<FamilyMemberProfile[]> {
  // In production, fetch from database
  return [
    {
      id: 'member-dad',
      name: 'Dad',
      role: 'parent',
      email: 'dad@family.com',
      phone: '(555) 100-0001',
      preferences: { notificationMethod: 'push' },
    },
    {
      id: 'member-mom',
      name: 'Mom',
      role: 'parent',
      email: 'mom@family.com',
      phone: '(555) 100-0002',
      preferences: { notificationMethod: 'push' },
    },
    {
      id: 'member-emma',
      name: 'Emma',
      role: 'child',
      preferences: { notificationMethod: 'push', quietHoursStart: '21:00', quietHoursEnd: '07:00' },
    },
    {
      id: 'member-jack',
      name: 'Jack',
      role: 'child',
      preferences: { notificationMethod: 'push', quietHoursStart: '20:00', quietHoursEnd: '07:00' },
    },
  ];
}

// ============================================================================
// ANNOUNCEMENTS
// ============================================================================

export interface CreateAnnouncementInput {
  workspaceId: string;
  title: string;
  message: string;
  priority?: 'low' | 'normal' | 'high' | 'urgent';
  createdBy: string;
  recipients?: string[]; // member IDs, defaults to 'all'
  expiresIn?: number; // hours
}

export async function createAnnouncement(input: CreateAnnouncementInput): Promise<FamilyAnnouncement> {
  const {
    title,
    message,
    priority = 'normal',
    createdBy,
    recipients,
    expiresIn,
  } = input;

  const announcement: FamilyAnnouncement = {
    id: `announce-${Date.now()}`,
    title,
    message,
    priority,
    createdBy,
    createdAt: new Date().toISOString(),
    expiresAt: expiresIn
      ? new Date(Date.now() + expiresIn * 60 * 60 * 1000).toISOString()
      : undefined,
    recipients: recipients || ['all'],
    acknowledgements: [],
  };

  // In production, would:
  // 1. Store announcement in database
  // 2. Send push notifications to recipients
  // 3. Send SMS for urgent announcements

  return announcement;
}

export interface GetAnnouncementsInput {
  workspaceId: string;
  memberId?: string;
  activeOnly?: boolean;
  limit?: number;
}

export async function getAnnouncements(input: GetAnnouncementsInput): Promise<FamilyAnnouncement[]> {
  const { activeOnly = true, limit = 10 } = input;

  // Mock announcements
  const announcements: FamilyAnnouncement[] = [
    {
      id: 'announce-1',
      title: 'Family Dinner Tonight',
      message: 'Grandma is coming over for dinner at 6pm. Please be home by 5:30!',
      priority: 'high',
      createdBy: 'member-mom',
      createdAt: new Date().toISOString(),
      recipients: ['all'],
      acknowledgements: [
        { memberId: 'member-dad', acknowledgedAt: new Date().toISOString() },
      ],
    },
    {
      id: 'announce-2',
      title: 'Weekend Trip Reminder',
      message: 'Don\'t forget to pack for the camping trip this weekend!',
      priority: 'normal',
      createdBy: 'member-dad',
      createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
      recipients: ['all'],
      acknowledgements: [],
    },
  ];

  return announcements.slice(0, limit);
}

export interface AcknowledgeAnnouncementInput {
  workspaceId: string;
  announcementId: string;
  memberId: string;
}

export async function acknowledgeAnnouncement(input: AcknowledgeAnnouncementInput): Promise<{
  success: boolean;
}> {
  // Would update announcement in database
  return { success: true };
}

// ============================================================================
// FAMILY CALENDAR
// ============================================================================

export interface CreateFamilyEventInput {
  workspaceId: string;
  title: string;
  description?: string;
  startTime: string;
  endTime?: string;
  location?: string;
  organizer: string;
  invitees?: string[];
  category?: FamilyEvent['category'];
  recurring?: FamilyEvent['recurring'];
  reminders?: number[]; // minutes before
}

export async function createFamilyEvent(input: CreateFamilyEventInput): Promise<FamilyEvent> {
  const {
    title,
    description,
    startTime,
    endTime,
    location,
    organizer,
    invitees = [],
    category = 'family',
    recurring,
    reminders = [30, 60],
  } = input;

  return {
    id: `event-${Date.now()}`,
    title,
    description,
    startTime,
    endTime,
    location,
    organizer,
    attendees: invitees.map((id) => ({ memberId: id, status: 'pending' })),
    reminders: reminders.map((min) => ({ minutesBefore: min, sent: false })),
    recurring,
    category,
  };
}

export interface GetFamilyCalendarInput {
  workspaceId: string;
  startDate: string;
  endDate: string;
  memberId?: string; // Filter to specific member's events
  categories?: FamilyEvent['category'][];
}

export async function getFamilyCalendar(input: GetFamilyCalendarInput): Promise<FamilyEvent[]> {
  const { startDate, endDate, categories } = input;

  // Mock calendar events
  const events: FamilyEvent[] = [
    {
      id: 'evt-1',
      title: 'Emma\'s Soccer Practice',
      startTime: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(),
      location: 'City Sports Complex',
      organizer: 'member-mom',
      attendees: [{ memberId: 'member-emma', status: 'accepted' }],
      reminders: [{ minutesBefore: 60, sent: false }],
      category: 'sports',
    },
    {
      id: 'evt-2',
      title: 'Family Movie Night',
      startTime: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
      location: 'Home',
      organizer: 'member-dad',
      attendees: [
        { memberId: 'member-mom', status: 'accepted' },
        { memberId: 'member-emma', status: 'accepted' },
        { memberId: 'member-jack', status: 'accepted' },
      ],
      reminders: [{ minutesBefore: 30, sent: false }],
      category: 'family',
    },
    {
      id: 'evt-3',
      title: 'Jack\'s Dentist Appointment',
      startTime: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString(),
      location: 'Smile Dental Clinic',
      organizer: 'member-mom',
      attendees: [{ memberId: 'member-jack', status: 'pending' }],
      reminders: [{ minutesBefore: 60, sent: false }, { minutesBefore: 1440, sent: false }],
      category: 'medical',
    },
  ];

  let filtered = events;
  if (categories && categories.length > 0) {
    filtered = filtered.filter((e) => categories.includes(e.category));
  }

  return filtered;
}

// ============================================================================
// CHORES & TASKS
// ============================================================================

export interface CreateChoreInput {
  workspaceId: string;
  name: string;
  description?: string;
  assignedTo: string;
  dueDate?: string;
  recurring?: ChoreAssignment['recurring'];
  points?: number;
}

export async function createChore(input: CreateChoreInput): Promise<ChoreAssignment> {
  const { name, description, assignedTo, dueDate, recurring, points } = input;

  return {
    id: `chore-${Date.now()}`,
    name,
    description,
    assignedTo,
    dueDate,
    recurring,
    status: 'pending',
    points,
  };
}

export interface GetChoresInput {
  workspaceId: string;
  assignedTo?: string;
  status?: ChoreAssignment['status'];
  includeCompleted?: boolean;
}

export async function getChores(input: GetChoresInput): Promise<ChoreAssignment[]> {
  const { assignedTo, status, includeCompleted = false } = input;

  // Mock chores
  let chores: ChoreAssignment[] = [
    {
      id: 'chore-1',
      name: 'Take out trash',
      assignedTo: 'member-jack',
      recurring: { frequency: 'weekly', daysOfWeek: [1, 4] },
      status: 'pending',
      points: 5,
    },
    {
      id: 'chore-2',
      name: 'Clean room',
      assignedTo: 'member-emma',
      recurring: { frequency: 'weekly', daysOfWeek: [6] },
      status: 'pending',
      points: 10,
    },
    {
      id: 'chore-3',
      name: 'Feed the dog',
      assignedTo: 'member-jack',
      recurring: { frequency: 'daily' },
      status: 'completed',
      points: 3,
      completedAt: new Date().toISOString(),
    },
    {
      id: 'chore-4',
      name: 'Homework check',
      assignedTo: 'member-emma',
      dueDate: new Date().toISOString(),
      status: 'in_progress',
      points: 5,
    },
  ];

  if (assignedTo) {
    chores = chores.filter((c) => c.assignedTo === assignedTo);
  }

  if (status) {
    chores = chores.filter((c) => c.status === status);
  }

  if (!includeCompleted) {
    chores = chores.filter((c) => c.status !== 'completed');
  }

  return chores;
}

export interface CompleteChoreInput {
  workspaceId: string;
  choreId: string;
  completedBy: string;
}

export async function completeChore(input: CompleteChoreInput): Promise<{
  success: boolean;
  pointsEarned: number;
}> {
  // Would update chore in database
  return {
    success: true,
    pointsEarned: 5, // Would look up actual points
  };
}

// ============================================================================
// CHECK-INS
// ============================================================================

export interface CreateCheckInInput {
  workspaceId: string;
  memberId: string;
  memberName: string;
  type: CheckIn['type'];
  location?: string;
  message?: string;
}

export async function createCheckIn(input: CreateCheckInInput): Promise<CheckIn> {
  const { memberId, memberName, type, location, message } = input;

  const checkIn: CheckIn = {
    id: `checkin-${Date.now()}`,
    memberId,
    memberName,
    type,
    location,
    message,
    timestamp: new Date().toISOString(),
    acknowledgedBy: [],
  };

  // In production, would:
  // 1. Store check-in
  // 2. Notify relevant family members (parents)
  // 3. Update location tracking

  return checkIn;
}

export interface GetCheckInsInput {
  workspaceId: string;
  memberId?: string;
  since?: string;
  limit?: number;
}

export async function getCheckIns(input: GetCheckInsInput): Promise<CheckIn[]> {
  const { memberId, since, limit = 20 } = input;

  // Mock check-ins
  const checkIns: CheckIn[] = [
    {
      id: 'checkin-1',
      memberId: 'member-emma',
      memberName: 'Emma',
      type: 'arrival',
      location: 'School',
      timestamp: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString(),
      acknowledgedBy: ['member-mom'],
    },
    {
      id: 'checkin-2',
      memberId: 'member-jack',
      memberName: 'Jack',
      type: 'arrival',
      location: 'Home',
      timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
      acknowledgedBy: ['member-mom', 'member-dad'],
    },
  ];

  let filtered = checkIns;

  if (memberId) {
    filtered = filtered.filter((c) => c.memberId === memberId);
  }

  return filtered.slice(0, limit);
}

// ============================================================================
// FAMILY SUMMARY (AI-powered)
// ============================================================================

export interface GetFamilySummaryInput {
  workspaceId: string;
  date?: string;
}

export interface FamilySummary {
  date: string;
  upcomingEvents: FamilyEvent[];
  pendingChores: ChoreAssignment[];
  activeAnnouncements: FamilyAnnouncement[];
  recentCheckIns: CheckIn[];
  aiSummary: string;
}

export async function getFamilySummary(input: GetFamilySummaryInput): Promise<FamilySummary> {
  const { workspaceId, date } = input;
  const targetDate = date || new Date().toISOString().split('T')[0]!;

  // Gather all family data
  const [events, chores, announcements, checkIns] = await Promise.all([
    getFamilyCalendar({
      workspaceId,
      startDate: targetDate,
      endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    }),
    getChores({ workspaceId }),
    getAnnouncements({ workspaceId, activeOnly: true }),
    getCheckIns({ workspaceId, limit: 5 }),
  ]);

  // Generate AI summary
  let aiSummary = '';
  const anthropicKey = process.env['ANTHROPIC_API_KEY'];

  if (anthropicKey) {
    try {
      const client = new Anthropic({ apiKey: anthropicKey });

      const summaryData = {
        events: events.slice(0, 5).map((e) => ({ title: e.title, when: e.startTime, where: e.location })),
        pendingChores: chores.filter((c) => c.status === 'pending').length,
        announcements: announcements.map((a) => a.title),
        checkIns: checkIns.map((c) => ({ who: c.memberName, type: c.type, where: c.location })),
      };

      const response = await client.messages.create({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 200,
        system: 'You are a helpful family assistant. Create a brief, friendly summary of the family\'s day. Keep it to 2-3 sentences.',
        messages: [{
          role: 'user',
          content: `Summarize this family's upcoming schedule:\n${JSON.stringify(summaryData)}`,
        }],
      });

      aiSummary = response.content[0]?.type === 'text' ? response.content[0].text : '';
    } catch {
      aiSummary = generateBasicFamilySummary(events, chores, announcements);
    }
  } else {
    aiSummary = generateBasicFamilySummary(events, chores, announcements);
  }

  return {
    date: targetDate,
    upcomingEvents: events.slice(0, 5),
    pendingChores: chores.filter((c) => c.status === 'pending'),
    activeAnnouncements: announcements,
    recentCheckIns: checkIns,
    aiSummary,
  };
}

function generateBasicFamilySummary(
  events: FamilyEvent[],
  chores: ChoreAssignment[],
  announcements: FamilyAnnouncement[]
): string {
  const parts: string[] = [];

  if (events.length > 0) {
    parts.push(`${events.length} upcoming event(s) this week`);
  }

  const pendingChores = chores.filter((c) => c.status === 'pending').length;
  if (pendingChores > 0) {
    parts.push(`${pendingChores} chore(s) pending`);
  }

  if (announcements.length > 0) {
    parts.push(`${announcements.length} active announcement(s)`);
  }

  return parts.length > 0
    ? `Today's overview: ${parts.join(', ')}.`
    : 'All caught up! No pending items.';
}

// ============================================================================
// EMERGENCY CONTACTS
// ============================================================================

export interface EmergencyContact {
  id: string;
  name: string;
  relationship: string;
  phone: string;
  email?: string;
  priority: number;
  notes?: string;
}

export interface GetEmergencyContactsInput {
  workspaceId: string;
}

export async function getEmergencyContacts(input: GetEmergencyContactsInput): Promise<EmergencyContact[]> {
  // In production, fetch from database
  return [
    {
      id: 'ec-1',
      name: 'Grandma Rose',
      relationship: 'Grandmother',
      phone: '(555) 200-0001',
      priority: 1,
      notes: 'Lives nearby, available anytime',
    },
    {
      id: 'ec-2',
      name: 'Uncle Mike',
      relationship: 'Uncle',
      phone: '(555) 200-0002',
      priority: 2,
    },
    {
      id: 'ec-3',
      name: 'Dr. Smith (Pediatrician)',
      relationship: 'Doctor',
      phone: '(555) 300-0001',
      priority: 3,
      notes: 'After hours: (555) 300-0002',
    },
    {
      id: 'ec-4',
      name: 'Poison Control',
      relationship: 'Emergency Service',
      phone: '1-800-222-1222',
      priority: 4,
    },
  ];
}

export interface TriggerEmergencyAlertInput {
  workspaceId: string;
  triggeredBy: string;
  alertType: 'medical' | 'safety' | 'location' | 'general';
  message?: string;
  location?: string;
}

export async function triggerEmergencyAlert(input: TriggerEmergencyAlertInput): Promise<{
  alertId: string;
  notifiedContacts: string[];
  notifiedMembers: string[];
}> {
  const { triggeredBy, alertType, message, location } = input;

  // In production, would:
  // 1. Send immediate push notifications to all family members
  // 2. Send SMS to emergency contacts
  // 3. Log the emergency
  // 4. Potentially contact emergency services

  return {
    alertId: `alert-${Date.now()}`,
    notifiedContacts: ['ec-1', 'ec-2'],
    notifiedMembers: ['member-dad', 'member-mom'],
  };
}
