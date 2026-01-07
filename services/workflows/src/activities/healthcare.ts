/**
 * Healthcare Activities for homeOS
 *
 * Family health management:
 * - Doctor appointment booking
 * - Medication reminders and tracking
 * - Health records summary
 * - Prescription refill reminders
 * - Telemedicine integration
 */

import Anthropic from '@anthropic-ai/sdk';

// ============================================================================
// TYPES
// ============================================================================

export interface FamilyMember {
  id: string;
  name: string;
  dateOfBirth?: string;
  allergies?: string[];
  medications?: Medication[];
  primaryDoctor?: Doctor;
  insuranceInfo?: InsuranceInfo;
}

export interface Doctor {
  id: string;
  name: string;
  specialty: string;
  phone?: string;
  address?: string;
  acceptsInsurance?: boolean;
  rating?: number;
  nextAvailable?: string;
}

export interface Medication {
  id: string;
  name: string;
  dosage: string;
  frequency: string; // e.g., "twice daily", "every 8 hours"
  timeOfDay?: string[]; // e.g., ["morning", "evening"]
  prescribedBy?: string;
  startDate?: string;
  endDate?: string;
  refillDate?: string;
  pharmacy?: string;
  notes?: string;
}

export interface Appointment {
  id: string;
  memberId: string;
  doctorId: string;
  doctorName: string;
  specialty: string;
  dateTime: string;
  duration: number; // minutes
  location?: string;
  type: 'in-person' | 'telemedicine';
  reason?: string;
  status: 'scheduled' | 'confirmed' | 'completed' | 'cancelled';
  notes?: string;
}

export interface InsuranceInfo {
  provider: string;
  planName: string;
  memberId: string;
  groupNumber?: string;
  copay?: number;
}

// ============================================================================
// DOCTOR SEARCH
// ============================================================================

export interface SearchDoctorsInput {
  workspaceId: string;
  specialty: string;
  location?: string;
  insuranceProvider?: string;
  acceptingNewPatients?: boolean;
}

export async function searchDoctors(input: SearchDoctorsInput): Promise<Doctor[]> {
  const { specialty, location, insuranceProvider } = input;

  // In production, this would integrate with:
  // - Zocdoc API
  // - Healthgrades API
  // - Insurance provider directories
  // - Google Places API for local doctors

  // For now, return mock data demonstrating the structure
  const mockDoctors: Doctor[] = [
    {
      id: 'dr-1',
      name: 'Dr. Sarah Chen',
      specialty: specialty || 'Primary Care',
      phone: '(555) 123-4567',
      address: '123 Medical Center Dr, Suite 100',
      acceptsInsurance: true,
      rating: 4.8,
      nextAvailable: getNextWeekday().toISOString(),
    },
    {
      id: 'dr-2',
      name: 'Dr. Michael Johnson',
      specialty: specialty || 'Primary Care',
      phone: '(555) 234-5678',
      address: '456 Health Plaza, Building B',
      acceptsInsurance: true,
      rating: 4.6,
      nextAvailable: getNextWeekday(2).toISOString(),
    },
    {
      id: 'dr-3',
      name: 'Dr. Emily Rodriguez',
      specialty: specialty || 'Primary Care',
      phone: '(555) 345-6789',
      address: '789 Wellness Way',
      acceptsInsurance: insuranceProvider ? true : false,
      rating: 4.9,
      nextAvailable: getNextWeekday(3).toISOString(),
    },
  ];

  return mockDoctors;
}

function getNextWeekday(daysAhead = 1): Date {
  const date = new Date();
  date.setDate(date.getDate() + daysAhead);
  while (date.getDay() === 0 || date.getDay() === 6) {
    date.setDate(date.getDate() + 1);
  }
  date.setHours(9, 0, 0, 0);
  return date;
}

// ============================================================================
// APPOINTMENT BOOKING
// ============================================================================

export interface BookAppointmentInput {
  workspaceId: string;
  memberId: string;
  doctorId: string;
  preferredDateTime: string;
  reason: string;
  type: 'in-person' | 'telemedicine';
}

export async function bookAppointment(input: BookAppointmentInput): Promise<{
  success: boolean;
  appointment?: Appointment;
  alternativeTimes?: string[];
  error?: string;
}> {
  const { memberId, doctorId, preferredDateTime, reason, type } = input;

  // In production, this would integrate with:
  // - Doctor's scheduling system
  // - Zocdoc booking API
  // - Telemedicine platforms (Teladoc, MDLive)

  // Simulate successful booking
  const appointment: Appointment = {
    id: `apt-${Date.now()}`,
    memberId,
    doctorId,
    doctorName: 'Dr. Sarah Chen', // Would be looked up
    specialty: 'Primary Care',
    dateTime: preferredDateTime,
    duration: 30,
    type,
    reason,
    status: 'scheduled',
    location: type === 'in-person' ? '123 Medical Center Dr, Suite 100' : 'Video call link will be sent',
  };

  return {
    success: true,
    appointment,
  };
}

// ============================================================================
// APPOINTMENT MANAGEMENT
// ============================================================================

export interface GetAppointmentsInput {
  workspaceId: string;
  memberId?: string;
  upcoming?: boolean;
}

export async function getAppointments(input: GetAppointmentsInput): Promise<Appointment[]> {
  const { memberId, upcoming = true } = input;

  // In production, would query stored appointments
  // Return mock upcoming appointments
  const now = new Date();
  const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

  return [
    {
      id: 'apt-mock-1',
      memberId: memberId || 'default',
      doctorId: 'dr-1',
      doctorName: 'Dr. Sarah Chen',
      specialty: 'Primary Care',
      dateTime: nextWeek.toISOString(),
      duration: 30,
      type: 'in-person',
      reason: 'Annual checkup',
      status: 'confirmed',
      location: '123 Medical Center Dr, Suite 100',
    },
  ];
}

// ============================================================================
// MEDICATION MANAGEMENT
// ============================================================================

export interface GetMedicationsInput {
  workspaceId: string;
  memberId: string;
}

export async function getMedications(input: GetMedicationsInput): Promise<Medication[]> {
  const { memberId } = input;

  // In production, would integrate with:
  // - Pharmacy APIs (CVS, Walgreens)
  // - EHR systems
  // - Manual entry storage

  return [
    {
      id: 'med-1',
      name: 'Lisinopril',
      dosage: '10mg',
      frequency: 'once daily',
      timeOfDay: ['morning'],
      prescribedBy: 'Dr. Chen',
      refillDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString(),
      pharmacy: 'CVS Pharmacy',
    },
    {
      id: 'med-2',
      name: 'Vitamin D',
      dosage: '2000 IU',
      frequency: 'once daily',
      timeOfDay: ['morning'],
      notes: 'Take with food',
    },
  ];
}

export interface AddMedicationInput {
  workspaceId: string;
  memberId: string;
  medication: Omit<Medication, 'id'>;
}

export async function addMedication(input: AddMedicationInput): Promise<Medication> {
  const { medication } = input;

  return {
    id: `med-${Date.now()}`,
    ...medication,
  };
}

export interface CheckMedicationRemindersInput {
  workspaceId: string;
  memberId: string;
  timeOfDay: 'morning' | 'afternoon' | 'evening' | 'night';
}

export async function checkMedicationReminders(input: CheckMedicationRemindersInput): Promise<{
  medications: Medication[];
  message: string;
}> {
  const { memberId, timeOfDay } = input;

  const allMeds = await getMedications({ workspaceId: input.workspaceId, memberId });
  const dueMeds = allMeds.filter((med) =>
    med.timeOfDay?.some((t) => t.toLowerCase().includes(timeOfDay))
  );

  const medNames = dueMeds.map((m) => `${m.name} (${m.dosage})`).join(', ');
  const message = dueMeds.length > 0
    ? `Time for your ${timeOfDay} medications: ${medNames}`
    : `No medications scheduled for ${timeOfDay}`;

  return { medications: dueMeds, message };
}

// ============================================================================
// HEALTH SUMMARY
// ============================================================================

export interface GetHealthSummaryInput {
  workspaceId: string;
  memberId: string;
}

export interface HealthSummary {
  member: Partial<FamilyMember>;
  upcomingAppointments: Appointment[];
  currentMedications: Medication[];
  refillsNeeded: Medication[];
  recommendations: string[];
}

export async function getHealthSummary(input: GetHealthSummaryInput): Promise<HealthSummary> {
  const { workspaceId, memberId } = input;

  const appointments = await getAppointments({ workspaceId, memberId, upcoming: true });
  const medications = await getMedications({ workspaceId, memberId });

  const now = new Date();
  const twoWeeksFromNow = new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000);

  const refillsNeeded = medications.filter((med) => {
    if (!med.refillDate) return false;
    return new Date(med.refillDate) <= twoWeeksFromNow;
  });

  const recommendations: string[] = [];

  if (appointments.length === 0) {
    recommendations.push('Consider scheduling an annual checkup');
  }

  if (refillsNeeded.length > 0) {
    recommendations.push(`${refillsNeeded.length} medication(s) need refill soon`);
  }

  return {
    member: { id: memberId, name: 'Family Member' },
    upcomingAppointments: appointments,
    currentMedications: medications,
    refillsNeeded,
    recommendations,
  };
}

// ============================================================================
// PRESCRIPTION REFILL
// ============================================================================

export interface RequestRefillInput {
  workspaceId: string;
  memberId: string;
  medicationId: string;
  pharmacy?: string;
}

export async function requestPrescriptionRefill(input: RequestRefillInput): Promise<{
  success: boolean;
  refillId: string;
  estimatedReady: string;
  pharmacy: string;
}> {
  const { medicationId, pharmacy = 'CVS Pharmacy' } = input;

  // In production, would integrate with pharmacy APIs

  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(14, 0, 0, 0);

  return {
    success: true,
    refillId: `refill-${Date.now()}`,
    estimatedReady: tomorrow.toISOString(),
    pharmacy,
  };
}

// ============================================================================
// SYMPTOM CHECKER (AI-powered)
// ============================================================================

export interface CheckSymptomsInput {
  workspaceId: string;
  memberId: string;
  symptoms: string[];
  duration?: string;
  severity?: 'mild' | 'moderate' | 'severe';
}

export interface SymptomCheckResult {
  possibleConditions: {
    name: string;
    likelihood: 'low' | 'moderate' | 'high';
    description: string;
  }[];
  recommendation: 'self-care' | 'schedule-appointment' | 'urgent-care' | 'emergency';
  selfCareSteps?: string[];
  disclaimer: string;
}

export async function checkSymptoms(input: CheckSymptomsInput): Promise<SymptomCheckResult> {
  const { symptoms, duration, severity } = input;

  const anthropicKey = process.env['ANTHROPIC_API_KEY'];

  if (!anthropicKey) {
    return getDefaultSymptomResponse(symptoms, severity);
  }

  try {
    const client = new Anthropic({ apiKey: anthropicKey });

    const response = await client.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1000,
      system: `You are a helpful medical information assistant. Provide general health information based on symptoms.
IMPORTANT: Always recommend consulting a healthcare provider. Do not diagnose conditions.
Return as JSON: {
  "possibleConditions": [{"name": "...", "likelihood": "low|moderate|high", "description": "..."}],
  "recommendation": "self-care|schedule-appointment|urgent-care|emergency",
  "selfCareSteps": ["..."],
  "disclaimer": "This is not medical advice..."
}`,
      messages: [{
        role: 'user',
        content: `Symptoms: ${symptoms.join(', ')}\nDuration: ${duration || 'Not specified'}\nSeverity: ${severity || 'Not specified'}`,
      }],
    });

    const text = response.content[0]?.type === 'text' ? response.content[0].text : '{}';
    return JSON.parse(text.replace(/```json\n?/g, '').replace(/```\n?/g, ''));
  } catch {
    return getDefaultSymptomResponse(symptoms, severity);
  }
}

function getDefaultSymptomResponse(symptoms: string[], severity?: string): SymptomCheckResult {
  const isSevere = severity === 'severe';

  return {
    possibleConditions: [
      {
        name: 'Common conditions',
        likelihood: 'moderate',
        description: 'Symptoms could indicate various conditions. Please consult a healthcare provider for proper evaluation.',
      },
    ],
    recommendation: isSevere ? 'urgent-care' : 'schedule-appointment',
    selfCareSteps: isSevere ? undefined : [
      'Rest and stay hydrated',
      'Monitor symptoms for changes',
      'Keep a symptom diary',
    ],
    disclaimer: 'This information is for educational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.',
  };
}
