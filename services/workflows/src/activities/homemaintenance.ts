/**
 * Home Maintenance Activities for homeOS
 *
 * Property and home management:
 * - Maintenance scheduling and reminders
 * - Contractor/service provider booking
 * - Home inventory tracking
 * - Warranty and documentation management
 * - Emergency repair coordination
 */

import Anthropic from '@anthropic-ai/sdk';

// ============================================================================
// TYPES
// ============================================================================

export interface MaintenanceTask {
  id: string;
  name: string;
  category: 'hvac' | 'plumbing' | 'electrical' | 'appliance' | 'exterior' | 'interior' | 'yard' | 'safety';
  frequency: 'weekly' | 'monthly' | 'quarterly' | 'biannual' | 'annual' | 'as_needed';
  lastCompleted?: string;
  nextDue: string;
  estimatedDuration: number; // minutes
  estimatedCost?: number;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  notes?: string;
  diyFriendly: boolean;
  contractorNeeded?: boolean;
}

export interface ServiceProvider {
  id: string;
  name: string;
  businessName?: string;
  category: string;
  phone: string;
  email?: string;
  address?: string;
  rating: number;
  reviewCount: number;
  licensed: boolean;
  insured: boolean;
  availability?: string;
  priceRange?: 'budget' | 'moderate' | 'premium';
}

export interface ServiceRequest {
  id: string;
  taskType: string;
  description: string;
  urgency: 'routine' | 'soon' | 'urgent' | 'emergency';
  preferredDate?: string;
  providerId?: string;
  status: 'pending' | 'quoted' | 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
  quotes?: { providerId: string; amount: number; notes: string }[];
  scheduledDateTime?: string;
  completedDateTime?: string;
  cost?: number;
}

export interface HomeInventoryItem {
  id: string;
  name: string;
  category: string;
  location: string; // room/area
  purchaseDate?: string;
  purchasePrice?: number;
  warrantyExpiration?: string;
  model?: string;
  serialNumber?: string;
  manualUrl?: string;
  notes?: string;
}

// ============================================================================
// MAINTENANCE SCHEDULE
// ============================================================================

export interface GetMaintenanceScheduleInput {
  workspaceId: string;
  category?: string;
  dueWithin?: number; // days
  includeOverdue?: boolean;
}

export async function getMaintenanceSchedule(input: GetMaintenanceScheduleInput): Promise<MaintenanceTask[]> {
  const { category, dueWithin = 30, includeOverdue = true } = input;

  // Standard home maintenance tasks
  const allTasks: MaintenanceTask[] = [
    // HVAC
    {
      id: 'hvac-filter',
      name: 'Replace HVAC filters',
      category: 'hvac',
      frequency: 'monthly',
      nextDue: getNextDueDate(30),
      estimatedDuration: 15,
      estimatedCost: 25,
      priority: 'medium',
      diyFriendly: true,
    },
    {
      id: 'hvac-service',
      name: 'HVAC system inspection',
      category: 'hvac',
      frequency: 'biannual',
      nextDue: getNextDueDate(180),
      estimatedDuration: 120,
      estimatedCost: 150,
      priority: 'medium',
      diyFriendly: false,
      contractorNeeded: true,
    },
    // Plumbing
    {
      id: 'water-heater',
      name: 'Flush water heater',
      category: 'plumbing',
      frequency: 'annual',
      nextDue: getNextDueDate(365),
      estimatedDuration: 60,
      priority: 'low',
      diyFriendly: true,
    },
    {
      id: 'check-leaks',
      name: 'Check for leaks under sinks',
      category: 'plumbing',
      frequency: 'monthly',
      nextDue: getNextDueDate(30),
      estimatedDuration: 15,
      priority: 'medium',
      diyFriendly: true,
    },
    // Safety
    {
      id: 'smoke-detectors',
      name: 'Test smoke/CO detectors',
      category: 'safety',
      frequency: 'monthly',
      nextDue: getNextDueDate(30),
      estimatedDuration: 15,
      priority: 'high',
      diyFriendly: true,
    },
    {
      id: 'fire-extinguisher',
      name: 'Check fire extinguisher',
      category: 'safety',
      frequency: 'annual',
      nextDue: getNextDueDate(365),
      estimatedDuration: 10,
      priority: 'high',
      diyFriendly: true,
    },
    // Exterior
    {
      id: 'gutters',
      name: 'Clean gutters',
      category: 'exterior',
      frequency: 'biannual',
      nextDue: getNextDueDate(180),
      estimatedDuration: 120,
      estimatedCost: 150,
      priority: 'medium',
      diyFriendly: true,
    },
    {
      id: 'roof-inspection',
      name: 'Roof inspection',
      category: 'exterior',
      frequency: 'annual',
      nextDue: getNextDueDate(365),
      estimatedDuration: 60,
      estimatedCost: 200,
      priority: 'medium',
      diyFriendly: false,
      contractorNeeded: true,
    },
    // Appliances
    {
      id: 'fridge-coils',
      name: 'Clean refrigerator coils',
      category: 'appliance',
      frequency: 'biannual',
      nextDue: getNextDueDate(180),
      estimatedDuration: 30,
      priority: 'low',
      diyFriendly: true,
    },
    {
      id: 'dryer-vent',
      name: 'Clean dryer vent',
      category: 'appliance',
      frequency: 'annual',
      nextDue: getNextDueDate(365),
      estimatedDuration: 45,
      priority: 'high',
      diyFriendly: true,
      notes: 'Fire hazard if not maintained',
    },
    // Yard
    {
      id: 'lawn-care',
      name: 'Lawn mowing',
      category: 'yard',
      frequency: 'weekly',
      nextDue: getNextDueDate(7),
      estimatedDuration: 60,
      priority: 'low',
      diyFriendly: true,
    },
  ];

  let filtered = allTasks;

  if (category) {
    filtered = filtered.filter((t) => t.category === category);
  }

  // Filter by due date
  const cutoffDate = new Date(Date.now() + dueWithin * 24 * 60 * 60 * 1000);
  filtered = filtered.filter((t) => {
    const dueDate = new Date(t.nextDue);
    if (includeOverdue && dueDate < new Date()) return true;
    return dueDate <= cutoffDate;
  });

  // Sort by priority and due date
  return filtered.sort((a, b) => {
    const priorityOrder = { urgent: 0, high: 1, medium: 2, low: 3 };
    const priorityDiff = priorityOrder[a.priority] - priorityOrder[b.priority];
    if (priorityDiff !== 0) return priorityDiff;
    return new Date(a.nextDue).getTime() - new Date(b.nextDue).getTime();
  });
}

function getNextDueDate(daysFromNow: number): string {
  const date = new Date();
  date.setDate(date.getDate() + daysFromNow);
  return date.toISOString().split('T')[0]!;
}

// ============================================================================
// SERVICE PROVIDER SEARCH
// ============================================================================

export interface SearchServiceProvidersInput {
  workspaceId: string;
  category: string;
  location?: string;
  urgency?: 'routine' | 'urgent' | 'emergency';
}

export async function searchServiceProviders(input: SearchServiceProvidersInput): Promise<ServiceProvider[]> {
  const { category, urgency } = input;

  // In production, integrate with:
  // - TaskRabbit API
  // - Thumbtack API
  // - HomeAdvisor/Angi API
  // - Yelp Fusion API

  // Return mock providers
  return [
    {
      id: 'provider-1',
      name: 'Mike Johnson',
      businessName: 'Johnson Home Services',
      category,
      phone: '(555) 123-4567',
      email: 'mike@johnsonhome.com',
      rating: 4.8,
      reviewCount: 156,
      licensed: true,
      insured: true,
      availability: urgency === 'emergency' ? 'Available now' : 'Available this week',
      priceRange: 'moderate',
    },
    {
      id: 'provider-2',
      name: 'Sarah Davis',
      businessName: 'Davis Repairs LLC',
      category,
      phone: '(555) 234-5678',
      rating: 4.9,
      reviewCount: 89,
      licensed: true,
      insured: true,
      availability: 'Next available: 3 days',
      priceRange: 'premium',
    },
    {
      id: 'provider-3',
      name: 'Budget Fix',
      businessName: 'Budget Fix Services',
      category,
      phone: '(555) 345-6789',
      rating: 4.2,
      reviewCount: 203,
      licensed: true,
      insured: true,
      availability: 'Available tomorrow',
      priceRange: 'budget',
    },
  ];
}

// ============================================================================
// SERVICE REQUEST
// ============================================================================

export interface CreateServiceRequestInput {
  workspaceId: string;
  taskType: string;
  description: string;
  urgency: 'routine' | 'soon' | 'urgent' | 'emergency';
  preferredDate?: string;
  photos?: string[]; // URLs to photos of the issue
}

export async function createServiceRequest(input: CreateServiceRequestInput): Promise<ServiceRequest> {
  const { taskType, description, urgency, preferredDate } = input;

  return {
    id: `service-${Date.now()}`,
    taskType,
    description,
    urgency,
    preferredDate,
    status: 'pending',
    quotes: [],
  };
}

export interface RequestQuoteInput {
  workspaceId: string;
  serviceRequestId: string;
  providerIds: string[];
}

export async function requestQuotes(input: RequestQuoteInput): Promise<{
  success: boolean;
  quotesRequested: number;
}> {
  const { providerIds } = input;

  // In production, would send quote requests to providers
  return {
    success: true,
    quotesRequested: providerIds.length,
  };
}

export interface ScheduleServiceInput {
  workspaceId: string;
  serviceRequestId: string;
  providerId: string;
  dateTime: string;
}

export async function scheduleService(input: ScheduleServiceInput): Promise<{
  success: boolean;
  confirmation: string;
  scheduledDateTime: string;
}> {
  const { serviceRequestId, dateTime } = input;

  return {
    success: true,
    confirmation: `SVC-${Date.now()}`,
    scheduledDateTime: dateTime,
  };
}

// ============================================================================
// HOME INVENTORY
// ============================================================================

export interface GetHomeInventoryInput {
  workspaceId: string;
  category?: string;
  location?: string;
  expiringWarranties?: number; // within days
}

export async function getHomeInventory(input: GetHomeInventoryInput): Promise<HomeInventoryItem[]> {
  const { category, location, expiringWarranties } = input;

  // Mock inventory items
  let items: HomeInventoryItem[] = [
    {
      id: 'inv-1',
      name: 'Refrigerator',
      category: 'appliance',
      location: 'Kitchen',
      purchaseDate: '2022-03-15',
      purchasePrice: 1200,
      warrantyExpiration: '2027-03-15',
      model: 'Samsung RF28R7551SR',
      serialNumber: 'RF28R-12345',
    },
    {
      id: 'inv-2',
      name: 'Washer',
      category: 'appliance',
      location: 'Laundry Room',
      purchaseDate: '2021-06-01',
      purchasePrice: 800,
      warrantyExpiration: '2024-06-01',
      model: 'LG WM4000HWA',
    },
    {
      id: 'inv-3',
      name: 'HVAC System',
      category: 'hvac',
      location: 'Utility Room',
      purchaseDate: '2020-01-15',
      purchasePrice: 5000,
      warrantyExpiration: '2030-01-15',
      model: 'Carrier 24ACC636A003',
    },
    {
      id: 'inv-4',
      name: 'Garage Door Opener',
      category: 'exterior',
      location: 'Garage',
      purchaseDate: '2019-08-20',
      purchasePrice: 350,
      warrantyExpiration: '2024-08-20',
      model: 'Chamberlain B970',
    },
  ];

  if (category) {
    items = items.filter((i) => i.category === category);
  }

  if (location) {
    items = items.filter((i) => i.location.toLowerCase().includes(location.toLowerCase()));
  }

  if (expiringWarranties) {
    const cutoff = new Date(Date.now() + expiringWarranties * 24 * 60 * 60 * 1000);
    items = items.filter((i) =>
      i.warrantyExpiration && new Date(i.warrantyExpiration) <= cutoff
    );
  }

  return items;
}

export interface AddInventoryItemInput {
  workspaceId: string;
  item: Omit<HomeInventoryItem, 'id'>;
}

export async function addInventoryItem(input: AddInventoryItemInput): Promise<HomeInventoryItem> {
  return {
    id: `inv-${Date.now()}`,
    ...input.item,
  };
}

// ============================================================================
// EMERGENCY REPAIR
// ============================================================================

export interface ReportEmergencyInput {
  workspaceId: string;
  type: 'water' | 'gas' | 'electrical' | 'hvac' | 'security' | 'other';
  description: string;
  location?: string;
}

export interface EmergencyResponse {
  emergencyId: string;
  type: string;
  severity: 'critical' | 'high' | 'moderate';
  immediateSteps: string[];
  emergencyContacts: { name: string; phone: string; type: string }[];
  providersContacted: ServiceProvider[];
  estimatedResponse: string;
}

export async function reportEmergency(input: ReportEmergencyInput): Promise<EmergencyResponse> {
  const { type, description } = input;

  // Determine severity and immediate steps
  const emergencyInfo = getEmergencyInfo(type);

  // Find emergency service providers
  const providers = await searchServiceProviders({
    workspaceId: input.workspaceId,
    category: type,
    urgency: 'emergency',
  });

  return {
    emergencyId: `emergency-${Date.now()}`,
    type,
    severity: emergencyInfo.severity,
    immediateSteps: emergencyInfo.steps,
    emergencyContacts: emergencyInfo.contacts,
    providersContacted: providers.slice(0, 2),
    estimatedResponse: '30-60 minutes',
  };
}

function getEmergencyInfo(type: string): {
  severity: 'critical' | 'high' | 'moderate';
  steps: string[];
  contacts: { name: string; phone: string; type: string }[];
} {
  const emergencyData: Record<string, ReturnType<typeof getEmergencyInfo>> = {
    water: {
      severity: 'high',
      steps: [
        'Locate and turn off the main water shut-off valve',
        'Turn off electricity to affected areas if water is near outlets',
        'Move valuables away from water',
        'Document damage with photos',
      ],
      contacts: [
        { name: 'Emergency Plumber', phone: '(555) 911-1234', type: 'plumber' },
        { name: 'Water Damage Restoration', phone: '(555) 911-5678', type: 'restoration' },
      ],
    },
    gas: {
      severity: 'critical',
      steps: [
        'LEAVE THE BUILDING IMMEDIATELY',
        'Do NOT use any electrical switches or phones inside',
        'Call 911 from outside',
        'Do not return until cleared by fire department',
      ],
      contacts: [
        { name: '911 Emergency', phone: '911', type: 'emergency' },
        { name: 'Gas Company Emergency', phone: '1-800-GAS-LEAK', type: 'utility' },
      ],
    },
    electrical: {
      severity: 'high',
      steps: [
        'Do NOT touch any exposed wires',
        'Turn off the main electrical breaker if safe to do so',
        'If sparking or fire, call 911',
        'Keep everyone away from the affected area',
      ],
      contacts: [
        { name: '911 (if fire/sparking)', phone: '911', type: 'emergency' },
        { name: 'Emergency Electrician', phone: '(555) 911-2345', type: 'electrician' },
      ],
    },
    hvac: {
      severity: 'moderate',
      steps: [
        'Turn off the HVAC system',
        'Check thermostat settings',
        'Check air filters',
        'If gas furnace and smell gas, treat as gas emergency',
      ],
      contacts: [
        { name: '24/7 HVAC Service', phone: '(555) 911-3456', type: 'hvac' },
      ],
    },
    security: {
      severity: 'critical',
      steps: [
        'If break-in in progress, call 911 immediately',
        'Do not enter the property if you suspect intruder',
        'Wait for police to arrive',
        'Document any damage',
      ],
      contacts: [
        { name: '911 Emergency', phone: '911', type: 'emergency' },
        { name: 'Security Company', phone: '(555) 911-4567', type: 'security' },
      ],
    },
    other: {
      severity: 'moderate',
      steps: [
        'Assess the situation for immediate dangers',
        'Document the issue with photos',
        'Contact appropriate service provider',
      ],
      contacts: [
        { name: 'General Contractor', phone: '(555) 911-5678', type: 'contractor' },
      ],
    },
  };

  return emergencyData[type] ?? emergencyData.other!;
}

// ============================================================================
// MAINTENANCE TIPS (AI-powered)
// ============================================================================

export interface GetMaintenanceTipsInput {
  workspaceId: string;
  season?: 'spring' | 'summer' | 'fall' | 'winter';
  homeType?: 'house' | 'condo' | 'apartment';
}

export async function getMaintenanceTips(input: GetMaintenanceTipsInput): Promise<{
  tips: string[];
  priorityTasks: MaintenanceTask[];
}> {
  const { season, homeType } = input;

  const currentSeason = season || getCurrentSeason();

  const seasonalTips: Record<string, string[]> = {
    spring: [
      'Check for winter damage to roof and siding',
      'Clean gutters and downspouts',
      'Service air conditioning before summer',
      'Power wash deck and exterior surfaces',
      'Check window and door seals',
    ],
    summer: [
      'Keep AC filters clean (monthly)',
      'Check irrigation system for leaks',
      'Trim trees away from house',
      'Inspect deck for loose boards',
      'Clean grill and check propane connections',
    ],
    fall: [
      'Schedule furnace maintenance before winter',
      'Clean gutters after leaves fall',
      'Winterize outdoor faucets',
      'Check weatherstripping on doors/windows',
      'Test smoke and CO detectors',
    ],
    winter: [
      'Keep walkways clear of ice',
      'Change furnace filter monthly',
      'Check for ice dams on roof',
      'Prevent pipe freezing',
      'Check attic insulation',
    ],
  };

  const tips = seasonalTips[currentSeason] ?? seasonalTips.spring!;

  const priorityTasks = await getMaintenanceSchedule({
    workspaceId: input.workspaceId,
    dueWithin: 30,
    includeOverdue: true,
  });

  return {
    tips,
    priorityTasks: priorityTasks.slice(0, 5),
  };
}

function getCurrentSeason(): 'spring' | 'summer' | 'fall' | 'winter' {
  const month = new Date().getMonth();
  if (month >= 2 && month <= 4) return 'spring';
  if (month >= 5 && month <= 7) return 'summer';
  if (month >= 8 && month <= 10) return 'fall';
  return 'winter';
}
