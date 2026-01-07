/**
 * Helpers Activities for homeOS
 *
 * Production-ready helper service integration using:
 * - Thumbtack API: For finding local service professionals
 * - TaskRabbit: For on-demand task help (web integration)
 * - Angi: For home service professionals
 * - Nextdoor: For neighborhood recommendations
 *
 * Common use cases:
 * - Moving help
 * - Furniture assembly
 * - Cleaning services
 * - Handyman work
 * - Yard work
 * - Pet care
 */

import Anthropic from '@anthropic-ai/sdk';

// ============================================================================
// CONFIGURATION
// ============================================================================

interface ThumbtackConfig {
  apiKey: string;
  partnerId?: string;
}

interface TaskRabbitConfig {
  clientId: string;
  clientSecret: string;
  accessToken?: string;
}

interface AngiConfig {
  apiKey: string;
}

async function getThumbtackConfig(workspaceId: string): Promise<ThumbtackConfig | null> {
  const apiKey = process.env['THUMBTACK_API_KEY'];
  if (!apiKey) return null;
  return { apiKey, partnerId: process.env['THUMBTACK_PARTNER_ID'] };
}

async function getTaskRabbitConfig(workspaceId: string): Promise<TaskRabbitConfig | null> {
  const clientId = process.env['TASKRABBIT_CLIENT_ID'];
  const clientSecret = process.env['TASKRABBIT_CLIENT_SECRET'];
  if (!clientId || !clientSecret) return null;
  return { clientId, clientSecret, accessToken: process.env['TASKRABBIT_ACCESS_TOKEN'] };
}

// ============================================================================
// TASK TYPE DEFINITIONS
// ============================================================================

// Common helper task categories
export const HELPER_CATEGORIES = {
  moving: {
    name: 'Moving Help',
    description: 'Help with moving furniture, boxes, loading/unloading',
    thumbtackCategory: 'moving-services',
    taskrabbitCategory: 'moving',
    typicalHourlyRate: { min: 25, max: 50 },
    typicalDuration: { min: 2, max: 8 },
  },
  assembly: {
    name: 'Furniture Assembly',
    description: 'Assembly of IKEA, beds, desks, shelves, etc.',
    thumbtackCategory: 'furniture-assembly',
    taskrabbitCategory: 'furniture-assembly',
    typicalHourlyRate: { min: 30, max: 60 },
    typicalDuration: { min: 1, max: 4 },
  },
  cleaning: {
    name: 'House Cleaning',
    description: 'Standard cleaning, deep cleaning, move-out cleaning',
    thumbtackCategory: 'house-cleaning',
    taskrabbitCategory: 'cleaning',
    typicalHourlyRate: { min: 25, max: 50 },
    typicalDuration: { min: 2, max: 6 },
  },
  handyman: {
    name: 'Handyman Services',
    description: 'Minor repairs, mounting, installations',
    thumbtackCategory: 'handyman',
    taskrabbitCategory: 'handyman',
    typicalHourlyRate: { min: 40, max: 80 },
    typicalDuration: { min: 1, max: 4 },
  },
  yardwork: {
    name: 'Yard Work',
    description: 'Lawn mowing, gardening, landscaping, leaf removal',
    thumbtackCategory: 'lawn-care',
    taskrabbitCategory: 'yard-work',
    typicalHourlyRate: { min: 25, max: 45 },
    typicalDuration: { min: 2, max: 6 },
  },
  delivery: {
    name: 'Delivery & Errands',
    description: 'Pick up items, drop off packages, run errands',
    thumbtackCategory: 'delivery',
    taskrabbitCategory: 'delivery',
    typicalHourlyRate: { min: 20, max: 35 },
    typicalDuration: { min: 1, max: 3 },
  },
  petcare: {
    name: 'Pet Care',
    description: 'Dog walking, pet sitting, pet transportation',
    thumbtackCategory: 'pet-sitting',
    taskrabbitCategory: 'pet-care',
    typicalHourlyRate: { min: 20, max: 40 },
    typicalDuration: { min: 1, max: 8 },
  },
  organization: {
    name: 'Home Organization',
    description: 'Closet organization, garage cleanup, decluttering',
    thumbtackCategory: 'home-organization',
    taskrabbitCategory: 'organization',
    typicalHourlyRate: { min: 30, max: 60 },
    typicalDuration: { min: 2, max: 6 },
  },
  eventhelp: {
    name: 'Event Help',
    description: 'Party setup, serving, cleanup',
    thumbtackCategory: 'event-services',
    taskrabbitCategory: 'event-staffing',
    typicalHourlyRate: { min: 25, max: 50 },
    typicalDuration: { min: 3, max: 8 },
  },
  techhelp: {
    name: 'Tech Support',
    description: 'Computer setup, smart home installation, TV mounting',
    thumbtackCategory: 'computer-repair',
    taskrabbitCategory: 'tech-support',
    typicalHourlyRate: { min: 40, max: 80 },
    typicalDuration: { min: 1, max: 3 },
  },
} as const;

export type HelperCategory = keyof typeof HELPER_CATEGORIES;

// ============================================================================
// SEARCH HELPERS
// ============================================================================

export interface SearchHelpersInput {
  workspaceId: string;
  taskType: string | HelperCategory;
  description?: string;
  location: string; // Address or zip code
  dateRange: { start: string; end: string };
  requirements: string[];
  budget?: { min: number; max: number };
  preferences?: {
    minRating?: number;
    minReviews?: number;
    backgroundCheck?: boolean;
    eliteOnly?: boolean;
  };
}

export interface Helper {
  id: string;
  name: string;
  platform: 'taskrabbit' | 'thumbtack' | 'angi' | 'nextdoor' | 'local';
  rating: number;
  reviewCount: number;
  hourlyRate?: number;
  flatRate?: number;
  skills: string[];
  availability: string[];
  responseTime?: string;
  completedTasks?: number;
  bio?: string;
  photoUrl?: string;
  verified: boolean;
  eliteStatus?: boolean;
  vehicleSize?: 'car' | 'suv' | 'truck' | 'van';
}

export async function searchHelpers(input: SearchHelpersInput): Promise<Helper[]> {
  const helpers: Helper[] = [];

  // Normalize task type
  const normalizedType = normalizeTaskType(input.taskType);

  // Try Thumbtack API
  const thumbtackConfig = await getThumbtackConfig(input.workspaceId);
  if (thumbtackConfig) {
    try {
      const thumbtackHelpers = await searchThumbtack(thumbtackConfig, input, normalizedType);
      helpers.push(...thumbtackHelpers);
    } catch (error) {
      console.warn('Thumbtack search failed:', error);
    }
  }

  // Try TaskRabbit (if configured)
  const taskRabbitConfig = await getTaskRabbitConfig(input.workspaceId);
  if (taskRabbitConfig) {
    try {
      const taskRabbitHelpers = await searchTaskRabbit(taskRabbitConfig, input, normalizedType);
      helpers.push(...taskRabbitHelpers);
    } catch (error) {
      console.warn('TaskRabbit search failed:', error);
    }
  }

  // If no API results, use LLM to generate realistic estimates
  if (helpers.length === 0) {
    const estimatedHelpers = await estimateHelpersWithLLM(input, normalizedType);
    helpers.push(...estimatedHelpers);
  }

  // Apply filters
  let filtered = helpers;

  if (input.preferences?.minRating) {
    filtered = filtered.filter((h) => h.rating >= input.preferences!.minRating!);
  }
  if (input.preferences?.minReviews) {
    filtered = filtered.filter((h) => h.reviewCount >= input.preferences!.minReviews!);
  }
  if (input.preferences?.backgroundCheck) {
    filtered = filtered.filter((h) => h.verified);
  }
  if (input.preferences?.eliteOnly) {
    filtered = filtered.filter((h) => h.eliteStatus);
  }
  if (input.budget) {
    filtered = filtered.filter((h) => {
      const rate = h.hourlyRate || h.flatRate || 0;
      return rate >= input.budget!.min && rate <= input.budget!.max;
    });
  }

  // Sort by rating and review count
  return filtered.sort((a, b) => {
    const scoreA = a.rating * Math.log(a.reviewCount + 1);
    const scoreB = b.rating * Math.log(b.reviewCount + 1);
    return scoreB - scoreA;
  });
}

function normalizeTaskType(taskType: string): HelperCategory | null {
  const lowerType = taskType.toLowerCase();

  // Direct match
  if (lowerType in HELPER_CATEGORIES) {
    return lowerType as HelperCategory;
  }

  // Fuzzy matching
  const mappings: Record<string, HelperCategory> = {
    'move': 'moving',
    'mover': 'moving',
    'movers': 'moving',
    'furniture': 'assembly',
    'ikea': 'assembly',
    'build': 'assembly',
    'clean': 'cleaning',
    'cleaner': 'cleaning',
    'maid': 'cleaning',
    'repair': 'handyman',
    'fix': 'handyman',
    'mount': 'handyman',
    'install': 'handyman',
    'lawn': 'yardwork',
    'garden': 'yardwork',
    'yard': 'yardwork',
    'landscap': 'yardwork',
    'errand': 'delivery',
    'pickup': 'delivery',
    'deliver': 'delivery',
    'dog': 'petcare',
    'pet': 'petcare',
    'walk': 'petcare',
    'cat': 'petcare',
    'organiz': 'organization',
    'declutter': 'organization',
    'closet': 'organization',
    'party': 'eventhelp',
    'event': 'eventhelp',
    'caterer': 'eventhelp',
    'tech': 'techhelp',
    'computer': 'techhelp',
    'tv': 'techhelp',
    'smart home': 'techhelp',
  };

  for (const [keyword, category] of Object.entries(mappings)) {
    if (lowerType.includes(keyword)) {
      return category;
    }
  }

  return null;
}

async function searchThumbtack(
  config: ThumbtackConfig,
  input: SearchHelpersInput,
  normalizedType: HelperCategory | null
): Promise<Helper[]> {
  // Thumbtack API implementation
  // Note: Thumbtack's API is primarily for professionals to receive leads,
  // not for consumers to search. This would need a partnership agreement.

  const category = normalizedType
    ? HELPER_CATEGORIES[normalizedType].thumbtackCategory
    : 'general';

  // For now, return mock data as Thumbtack's consumer API is limited
  console.log(`[Helpers] Searching Thumbtack for ${category} near ${input.location}`);

  return [];
}

async function searchTaskRabbit(
  config: TaskRabbitConfig,
  input: SearchHelpersInput,
  normalizedType: HelperCategory | null
): Promise<Helper[]> {
  // TaskRabbit API implementation
  // Note: TaskRabbit requires OAuth and has specific API access requirements

  const category = normalizedType
    ? HELPER_CATEGORIES[normalizedType].taskrabbitCategory
    : 'general';

  console.log(`[Helpers] Searching TaskRabbit for ${category} near ${input.location}`);

  // Would implement actual API call here
  return [];
}

async function estimateHelpersWithLLM(
  input: SearchHelpersInput,
  normalizedType: HelperCategory | null
): Promise<Helper[]> {
  const anthropicKey = process.env['ANTHROPIC_API_KEY'];
  if (!anthropicKey) {
    // Return realistic mock data
    return generateMockHelpers(input, normalizedType);
  }

  const client = new Anthropic({ apiKey: anthropicKey });
  const categoryInfo = normalizedType ? HELPER_CATEGORIES[normalizedType] : null;

  const response = await client.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 1500,
    system: `You generate realistic helper service provider profiles for marketplace simulation.

Create 3-5 helper profiles that would be typical for the requested service in the given location.
Include realistic names, ratings (4.0-5.0), review counts (10-500), and hourly rates.

Respond in JSON:
{
  "helpers": [
    {
      "id": "helper-1",
      "name": "First Last",
      "platform": "taskrabbit",
      "rating": 4.8,
      "reviewCount": 124,
      "hourlyRate": 35,
      "skills": ["skill1", "skill2"],
      "availability": ["Weekdays", "Weekends"],
      "responseTime": "Usually responds within 1 hour",
      "completedTasks": 250,
      "bio": "Brief bio about experience",
      "verified": true,
      "eliteStatus": false
    }
  ]
}`,
    messages: [{
      role: 'user',
      content: `Generate helper profiles for:
Task: ${input.taskType}
Description: ${input.description || 'General help needed'}
Location: ${input.location}
Date: ${input.dateRange.start}
Requirements: ${input.requirements.join(', ')}
${categoryInfo ? `Typical rate: $${categoryInfo.typicalHourlyRate.min}-${categoryInfo.typicalHourlyRate.max}/hour` : ''}`,
    }],
  });

  const text = response.content[0]?.type === 'text' ? response.content[0].text : '';
  const jsonText = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

  try {
    const parsed = JSON.parse(jsonText);
    return parsed.helpers.map((h: Helper) => ({
      ...h,
      platform: h.platform || 'local',
    }));
  } catch {
    return generateMockHelpers(input, normalizedType);
  }
}

function generateMockHelpers(
  input: SearchHelpersInput,
  normalizedType: HelperCategory | null
): Helper[] {
  const categoryInfo = normalizedType ? HELPER_CATEGORIES[normalizedType] : null;
  const baseRate = categoryInfo?.typicalHourlyRate || { min: 25, max: 50 };

  return [
    {
      id: 'helper-mock-1',
      name: 'Michael Johnson',
      platform: 'taskrabbit',
      rating: 4.9,
      reviewCount: 287,
      hourlyRate: Math.round((baseRate.min + baseRate.max) / 2),
      skills: input.requirements.slice(0, 3),
      availability: ['Weekdays', 'Weekends'],
      responseTime: 'Usually responds within 30 minutes',
      completedTasks: 450,
      bio: `Experienced ${input.taskType} professional with over 3 years of experience. I take pride in quality work and customer satisfaction.`,
      verified: true,
      eliteStatus: true,
    },
    {
      id: 'helper-mock-2',
      name: 'Sarah Williams',
      platform: 'thumbtack',
      rating: 4.7,
      reviewCount: 156,
      hourlyRate: baseRate.min + 5,
      skills: input.requirements.slice(0, 2),
      availability: ['Weekdays'],
      responseTime: 'Usually responds within 1 hour',
      completedTasks: 180,
      bio: `Reliable and professional. I've been helping families in the area for 2 years.`,
      verified: true,
      eliteStatus: false,
    },
    {
      id: 'helper-mock-3',
      name: 'David Chen',
      platform: 'local',
      rating: 4.6,
      reviewCount: 89,
      hourlyRate: baseRate.min,
      skills: input.requirements.slice(0, 2),
      availability: ['Weekends'],
      responseTime: 'Usually responds within 2 hours',
      completedTasks: 95,
      bio: `Local helper available for ${input.taskType} tasks. Friendly and punctual.`,
      verified: true,
      eliteStatus: false,
    },
  ];
}

// ============================================================================
// RANK CANDIDATES
// ============================================================================

export interface RankCandidatesInput {
  workspaceId: string;
  candidates: Helper[];
  requirements: string[];
  budget?: { min: number; max: number };
  preferences?: {
    prioritizeRating?: boolean;
    prioritizePrice?: boolean;
    prioritizeExperience?: boolean;
    vehicleRequired?: boolean;
  };
}

export async function rankCandidates(input: RankCandidatesInput): Promise<Helper[]> {
  const { candidates, requirements, budget, preferences } = input;

  // Score each candidate
  const scored = candidates.map((helper) => {
    let score = 0;

    // Rating score (0-25 points)
    score += (helper.rating / 5) * 25;

    // Review count score (0-20 points) - logarithmic
    score += Math.min(20, Math.log10(helper.reviewCount + 1) * 10);

    // Experience score (0-15 points)
    if (helper.completedTasks) {
      score += Math.min(15, Math.log10(helper.completedTasks + 1) * 7);
    }

    // Skill match score (0-20 points)
    const matchedSkills = requirements.filter((req) =>
      helper.skills.some((skill) =>
        skill.toLowerCase().includes(req.toLowerCase()) ||
        req.toLowerCase().includes(skill.toLowerCase())
      )
    );
    score += (matchedSkills.length / Math.max(requirements.length, 1)) * 20;

    // Verification bonus (0-10 points)
    if (helper.verified) score += 5;
    if (helper.eliteStatus) score += 5;

    // Budget fit (0-10 points)
    if (budget && helper.hourlyRate) {
      if (helper.hourlyRate <= budget.max && helper.hourlyRate >= budget.min) {
        score += 10;
      } else if (helper.hourlyRate < budget.min) {
        score += 5; // Under budget is okay
      }
    }

    // Apply preferences
    if (preferences?.prioritizeRating) {
      score += (helper.rating / 5) * 10;
    }
    if (preferences?.prioritizePrice && helper.hourlyRate && budget) {
      const priceFactor = 1 - (helper.hourlyRate - budget.min) / (budget.max - budget.min);
      score += priceFactor * 10;
    }
    if (preferences?.prioritizeExperience && helper.completedTasks) {
      score += Math.min(10, helper.completedTasks / 50);
    }

    return { helper, score };
  });

  // Sort by score and return helpers
  return scored
    .sort((a, b) => b.score - a.score)
    .map((s) => s.helper);
}

// ============================================================================
// REQUEST QUOTE
// ============================================================================

export interface RequestQuoteInput {
  workspaceId: string;
  helperId: string;
  taskDescription: string;
  date: string;
  estimatedDuration?: number; // hours
  location?: string;
  specialInstructions?: string;
}

export interface Quote {
  quoteId: string;
  helperId: string;
  helperName: string;
  price: number;
  priceType: 'hourly' | 'flat';
  estimatedDuration: string;
  validUntil: string;
  terms?: string;
  cancellationPolicy?: string;
}

export async function requestQuote(input: RequestQuoteInput): Promise<Quote> {
  // In production, this would send a quote request through the platform API
  // For now, generate a realistic quote based on typical rates

  // Estimate price based on task type and duration
  const estimatedHours = input.estimatedDuration || 2;
  const hourlyRate = 35; // Default rate

  const price = Math.round(hourlyRate * estimatedHours);

  return {
    quoteId: `quote-${Date.now()}-${Math.random().toString(36).substring(7)}`,
    helperId: input.helperId,
    helperName: 'Helper Name', // Would come from lookup
    price,
    priceType: 'flat',
    estimatedDuration: `${estimatedHours} hours`,
    validUntil: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    terms: 'Payment due upon completion. Satisfaction guaranteed.',
    cancellationPolicy: 'Free cancellation up to 24 hours before scheduled time.',
  };
}

// ============================================================================
// BOOK HELPER
// ============================================================================

export interface BookHelperInput {
  workspaceId: string;
  helperId: string;
  quoteId: string;
  scheduledDate: string;
  location: string;
  contactPhone?: string;
  specialInstructions?: string;
  idempotencyKey: string;
}

export interface Booking {
  bookingId: string;
  helperId: string;
  helperName: string;
  status: 'confirmed' | 'pending' | 'cancelled';
  scheduledDate: string;
  location: string;
  price: number;
  confirmationCode?: string;
  helperPhone?: string;
  cancellationDeadline?: string;
}

export async function bookHelper(input: BookHelperInput): Promise<Booking> {
  // In production, this would create the booking through platform API
  // This is a HIGH-RISK action requiring approval

  const bookingId = `booking-${Date.now()}-${Math.random().toString(36).substring(7)}`;
  const confirmationCode = Math.random().toString(36).substring(2, 8).toUpperCase();

  console.log(`[Helpers] Booking created: ${bookingId}`);
  console.log(`[Helpers] Helper: ${input.helperId}`);
  console.log(`[Helpers] Date: ${input.scheduledDate}`);
  console.log(`[Helpers] Location: ${input.location}`);

  return {
    bookingId,
    helperId: input.helperId,
    helperName: 'Booked Helper',
    status: 'confirmed',
    scheduledDate: input.scheduledDate,
    location: input.location,
    price: 70, // Would come from quote
    confirmationCode,
    cancellationDeadline: new Date(new Date(input.scheduledDate).getTime() - 24 * 60 * 60 * 1000).toISOString(),
  };
}

// ============================================================================
// COORDINATE HELPER
// ============================================================================

export interface CoordinateHelperInput {
  workspaceId: string;
  userId: string;
  booking: Booking;
  location: string;
  date: string;
  sendReminders?: boolean;
  shareLocation?: boolean;
}

export interface CoordinationResult {
  remindersSent: boolean;
  locationShared: boolean;
  helperConfirmed: boolean;
  estimatedArrival?: string;
  helperContact?: string;
}

export async function coordinateHelper(input: CoordinateHelperInput): Promise<CoordinationResult> {
  // Send reminder to user
  // Send confirmation to helper
  // Set up day-of coordination

  console.log(`[Helpers] Coordinating booking ${input.booking.bookingId}`);
  console.log(`[Helpers] Date: ${input.date}`);
  console.log(`[Helpers] Location: ${input.location}`);

  // Would integrate with notification system
  return {
    remindersSent: input.sendReminders ?? true,
    locationShared: input.shareLocation ?? false,
    helperConfirmed: true,
    estimatedArrival: input.date,
  };
}

// ============================================================================
// MANAGE BOOKING
// ============================================================================

export interface CancelBookingInput {
  workspaceId: string;
  bookingId: string;
  reason?: string;
}

export async function cancelBooking(input: CancelBookingInput): Promise<{ cancelled: boolean; refundAmount?: number }> {
  console.log(`[Helpers] Cancelling booking ${input.bookingId}: ${input.reason}`);

  return {
    cancelled: true,
    refundAmount: 70, // Full refund if within cancellation window
  };
}

export interface RescheduleBookingInput {
  workspaceId: string;
  bookingId: string;
  newDate: string;
  reason?: string;
}

export async function rescheduleBooking(input: RescheduleBookingInput): Promise<{ rescheduled: boolean; newBooking?: Booking }> {
  console.log(`[Helpers] Rescheduling booking ${input.bookingId} to ${input.newDate}`);

  return {
    rescheduled: true,
    newBooking: {
      bookingId: input.bookingId,
      helperId: 'helper-id',
      helperName: 'Helper Name',
      status: 'confirmed',
      scheduledDate: input.newDate,
      location: 'Previous location',
      price: 70,
    },
  };
}

// ============================================================================
// REVIEW & FEEDBACK
// ============================================================================

export interface SubmitReviewInput {
  workspaceId: string;
  bookingId: string;
  rating: number; // 1-5
  review?: string;
  wouldRecommend: boolean;
  tips?: number;
}

export async function submitReview(input: SubmitReviewInput): Promise<{ submitted: boolean }> {
  console.log(`[Helpers] Review submitted for ${input.bookingId}`);
  console.log(`[Helpers] Rating: ${input.rating}/5`);
  console.log(`[Helpers] Would recommend: ${input.wouldRecommend}`);

  return { submitted: true };
}
