/**
 * Telephony Activities for homeOS
 *
 * Production-ready voice AI integration using:
 * - Retell AI: For conversational AI voice agents
 * - Twilio: For phone number provisioning and call infrastructure
 * - Google Places: For restaurant/business discovery
 * - Google Calendar: For scheduling integration
 */

import Anthropic from '@anthropic-ai/sdk';

// ============================================================================
// CONFIGURATION INTERFACES
// ============================================================================

interface RetellConfig {
  apiKey: string;
  agentId?: string;
  voiceId?: string;
}

interface TwilioConfig {
  accountSid: string;
  authToken: string;
  phoneNumber: string;
}

interface GooglePlacesConfig {
  apiKey: string;
}

interface GoogleCalendarConfig {
  clientId: string;
  clientSecret: string;
  refreshToken: string;
}

// ============================================================================
// SERVICE CONFIGURATION LOADERS
// ============================================================================

async function getRetellConfig(workspaceId: string): Promise<RetellConfig> {
  // TODO: Load from workspace secrets via control plane
  const apiKey = process.env['RETELL_API_KEY'];
  if (!apiKey) {
    throw new Error('Retell API key not configured. Set RETELL_API_KEY or configure via workspace secrets.');
  }
  return {
    apiKey,
    agentId: process.env['RETELL_AGENT_ID'],
    voiceId: process.env['RETELL_VOICE_ID'] || '11labs-Adrian', // Default to a natural male voice
  };
}

async function getTwilioConfig(workspaceId: string): Promise<TwilioConfig> {
  const accountSid = process.env['TWILIO_ACCOUNT_SID'];
  const authToken = process.env['TWILIO_AUTH_TOKEN'];
  const phoneNumber = process.env['TWILIO_PHONE_NUMBER'];

  if (!accountSid || !authToken || !phoneNumber) {
    throw new Error('Twilio not configured. Set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_PHONE_NUMBER.');
  }

  return { accountSid, authToken, phoneNumber };
}

async function getGooglePlacesConfig(workspaceId: string): Promise<GooglePlacesConfig> {
  const apiKey = process.env['GOOGLE_PLACES_API_KEY'];
  if (!apiKey) {
    throw new Error('Google Places API key not configured. Set GOOGLE_PLACES_API_KEY.');
  }
  return { apiKey };
}

// ============================================================================
// RETELL AI VOICE AGENT CONFIGURATION
// ============================================================================

interface RetellAgentConfig {
  agentName: string;
  voiceId: string;
  llmWebsocketUrl?: string;
  generalPrompt: string;
  beginMessage: string;
  generalTools?: RetellTool[];
  endCallAfterSilenceSec?: number;
  maxCallDurationSec?: number;
  interruptionSensitivity?: number;
  ambientSoundVolume?: number;
  responsiveness?: number;
  enableBackchannel?: boolean;
}

interface RetellTool {
  type: 'end_call' | 'transfer_call' | 'check_availability' | 'book_reservation';
  name: string;
  description: string;
}

// Pre-configured agent prompts for different use cases
const RESERVATION_AGENT_PROMPT = `You are a friendly, professional assistant making a phone call to book a restaurant reservation on behalf of a family. Be polite, natural, and conversational.

## Your Task
- Make a reservation for the party size, date, and time specified
- Be flexible within the negotiation bounds provided
- Handle common scenarios like being put on hold, transferred, or asked questions

## Conversation Guidelines
1. Greet warmly and state your purpose clearly
2. Provide all necessary details: party size, date, time, name for reservation
3. If the requested time isn't available, ask for the next closest option
4. Confirm all details before ending the call
5. Thank them and say goodbye politely

## Important Rules
- NEVER share sensitive personal information beyond what's needed
- If they ask for a credit card, politely decline and say you'll provide it upon arrival
- If they ask questions you can't answer, say you'll call back with that information
- Stay calm if put on hold - wait patiently
- If the call seems to be going nowhere after 3 attempts, politely end and say you'll try again later

## Handling Negotiation
- If requested time unavailable: Accept alternatives within {timeFlexibility}
- If they require a deposit: Only if explicitly allowed in negotiation bounds
- If minimum party size required: Confirm you meet it or ask about alternatives

## End Call Conditions
- Reservation confirmed successfully
- No availability on requested date
- Restaurant is closed or not taking reservations
- Asked to call back at a different time
- 3+ failed attempts to communicate`;

const GENERAL_CALLER_PROMPT = `You are a helpful, professional assistant making a phone call on behalf of a family. Be polite, natural, and conversational.

## Guidelines
1. State your purpose clearly at the start
2. Be patient if put on hold or transferred
3. Confirm all important details
4. Thank them before ending

## Rules
- Never share unnecessary personal information
- If unsure about something, say you'll call back
- Stay professional even if the other party is difficult`;

// ============================================================================
// RETELL AI API FUNCTIONS
// ============================================================================

interface CreateRetellCallRequest {
  agentId: string;
  toPhoneNumber: string;
  fromPhoneNumber: string;
  metadata?: Record<string, unknown>;
  retellLlmDynamicVariables?: Record<string, string>;
}

interface RetellCallResponse {
  callId: string;
  agentId: string;
  callStatus: 'registered' | 'ongoing' | 'ended' | 'error';
  startTimestamp?: number;
  endTimestamp?: number;
  transcript?: string;
  recordingUrl?: string;
  callAnalysis?: {
    callSuccessful: boolean;
    callSummary: string;
    userSentiment: 'positive' | 'negative' | 'neutral';
    agentSentiment: 'positive' | 'negative' | 'neutral';
    customAnalysis?: Record<string, unknown>;
  };
}

async function createRetellAgent(
  config: RetellConfig,
  agentConfig: RetellAgentConfig
): Promise<string> {
  const response = await fetch('https://api.retellai.com/create-agent', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${config.apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      agent_name: agentConfig.agentName,
      voice_id: agentConfig.voiceId,
      response_engine: {
        type: 'retell-llm',
        llm_id: process.env['RETELL_LLM_ID'] || undefined, // Optional custom LLM
      },
      general_prompt: agentConfig.generalPrompt,
      begin_message: agentConfig.beginMessage,
      end_call_after_silence_ms: (agentConfig.endCallAfterSilenceSec || 10) * 1000,
      max_call_duration_ms: (agentConfig.maxCallDurationSec || 600) * 1000, // 10 min default
      interruption_sensitivity: agentConfig.interruptionSensitivity || 0.8,
      ambient_sound_volume: agentConfig.ambientSoundVolume || 0,
      responsiveness: agentConfig.responsiveness || 1,
      enable_backchannel: agentConfig.enableBackchannel ?? true,
      language: 'en-US',
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Failed to create Retell agent: ${error}`);
  }

  const data = await response.json() as { agent_id: string };
  return data.agent_id;
}

async function initiateRetellCall(
  config: RetellConfig,
  request: CreateRetellCallRequest
): Promise<RetellCallResponse> {
  const response = await fetch('https://api.retellai.com/v2/create-phone-call', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${config.apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      agent_id: request.agentId,
      to_number: request.toPhoneNumber,
      from_number: request.fromPhoneNumber,
      metadata: request.metadata,
      retell_llm_dynamic_variables: request.retellLlmDynamicVariables,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Failed to initiate Retell call: ${error}`);
  }

  const data = await response.json() as { call_id: string; agent_id: string; call_status: string };
  return {
    callId: data.call_id,
    agentId: data.agent_id,
    callStatus: data.call_status as RetellCallResponse['callStatus'],
  };
}

async function getRetellCallDetails(
  config: RetellConfig,
  callId: string
): Promise<RetellCallResponse> {
  const response = await fetch(`https://api.retellai.com/v2/get-call/${callId}`, {
    headers: {
      'Authorization': `Bearer ${config.apiKey}`,
    },
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Failed to get call details: ${error}`);
  }

  const data = await response.json() as {
    call_id: string;
    agent_id: string;
    call_status: string;
    start_timestamp?: number;
    end_timestamp?: number;
    transcript?: string;
    recording_url?: string;
    call_analysis?: {
      call_successful: boolean;
      call_summary: string;
      user_sentiment: string;
      agent_sentiment: string;
      custom_analysis?: Record<string, unknown>;
    };
  };

  return {
    callId: data.call_id,
    agentId: data.agent_id,
    callStatus: data.call_status as RetellCallResponse['callStatus'],
    startTimestamp: data.start_timestamp,
    endTimestamp: data.end_timestamp,
    transcript: data.transcript,
    recordingUrl: data.recording_url,
    callAnalysis: data.call_analysis ? {
      callSuccessful: data.call_analysis.call_successful,
      callSummary: data.call_analysis.call_summary,
      userSentiment: data.call_analysis.user_sentiment as 'positive' | 'negative' | 'neutral',
      agentSentiment: data.call_analysis.agent_sentiment as 'positive' | 'negative' | 'neutral',
      customAnalysis: data.call_analysis.custom_analysis,
    } : undefined,
  };
}

// Poll for call completion
async function waitForCallCompletion(
  config: RetellConfig,
  callId: string,
  maxWaitMs: number = 600000 // 10 minutes
): Promise<RetellCallResponse> {
  const startTime = Date.now();
  const pollIntervalMs = 5000; // 5 seconds

  while (Date.now() - startTime < maxWaitMs) {
    const callDetails = await getRetellCallDetails(config, callId);

    if (callDetails.callStatus === 'ended' || callDetails.callStatus === 'error') {
      return callDetails;
    }

    await new Promise((resolve) => setTimeout(resolve, pollIntervalMs));
  }

  throw new Error(`Call ${callId} did not complete within ${maxWaitMs}ms`);
}

// ============================================================================
// GOOGLE PLACES API FUNCTIONS
// ============================================================================

interface PlaceSearchResult {
  id: string;
  name: string;
  address: string;
  phoneNumber: string;
  rating?: number;
  priceLevel?: number;
  hours?: string[];
  website?: string;
  types: string[];
  location: {
    lat: number;
    lng: number;
  };
}

interface PlaceSearchRequest {
  query: string;
  location: string; // "lat,lng" or address
  radius?: number; // meters
  type?: string;
  openNow?: boolean;
}

async function searchPlaces(
  config: GooglePlacesConfig,
  request: PlaceSearchRequest
): Promise<PlaceSearchResult[]> {
  // First, geocode the location if it's an address
  let locationParam = request.location;
  if (!request.location.match(/^-?\d+\.?\d*,-?\d+\.?\d*$/)) {
    const geocodeUrl = new URL('https://maps.googleapis.com/maps/api/geocode/json');
    geocodeUrl.searchParams.set('address', request.location);
    geocodeUrl.searchParams.set('key', config.apiKey);

    const geocodeResponse = await fetch(geocodeUrl.toString());
    const geocodeData = await geocodeResponse.json() as {
      results: Array<{ geometry: { location: { lat: number; lng: number } } }>;
      status: string;
    };

    if (geocodeData.status === 'OK' && geocodeData.results[0]) {
      const loc = geocodeData.results[0].geometry.location;
      locationParam = `${loc.lat},${loc.lng}`;
    }
  }

  // Search for places
  const searchUrl = new URL('https://maps.googleapis.com/maps/api/place/textsearch/json');
  searchUrl.searchParams.set('query', request.query);
  searchUrl.searchParams.set('location', locationParam);
  searchUrl.searchParams.set('radius', (request.radius || 5000).toString());
  searchUrl.searchParams.set('key', config.apiKey);

  if (request.type) {
    searchUrl.searchParams.set('type', request.type);
  }
  if (request.openNow) {
    searchUrl.searchParams.set('opennow', 'true');
  }

  const response = await fetch(searchUrl.toString());
  const data = await response.json() as {
    results: Array<{
      place_id: string;
      name: string;
      formatted_address: string;
      formatted_phone_number?: string;
      rating?: number;
      price_level?: number;
      opening_hours?: { weekday_text?: string[] };
      website?: string;
      types: string[];
      geometry: { location: { lat: number; lng: number } };
    }>;
    status: string;
  };

  if (data.status !== 'OK' && data.status !== 'ZERO_RESULTS') {
    throw new Error(`Google Places API error: ${data.status}`);
  }

  // Get detailed info for each place (phone number, hours)
  const results: PlaceSearchResult[] = [];

  for (const place of data.results.slice(0, 5)) { // Limit to top 5
    try {
      const detailsUrl = new URL('https://maps.googleapis.com/maps/api/place/details/json');
      detailsUrl.searchParams.set('place_id', place.place_id);
      detailsUrl.searchParams.set('fields', 'formatted_phone_number,opening_hours,website');
      detailsUrl.searchParams.set('key', config.apiKey);

      const detailsResponse = await fetch(detailsUrl.toString());
      const detailsData = await detailsResponse.json() as {
        result: {
          formatted_phone_number?: string;
          opening_hours?: { weekday_text?: string[] };
          website?: string;
        };
        status: string;
      };

      if (detailsData.status === 'OK' && detailsData.result.formatted_phone_number) {
        results.push({
          id: place.place_id,
          name: place.name,
          address: place.formatted_address,
          phoneNumber: detailsData.result.formatted_phone_number,
          rating: place.rating,
          priceLevel: place.price_level,
          hours: detailsData.result.opening_hours?.weekday_text,
          website: detailsData.result.website,
          types: place.types,
          location: place.geometry.location,
        });
      }
    } catch (error) {
      console.warn(`Failed to get details for place ${place.place_id}:`, error);
    }
  }

  return results;
}

// ============================================================================
// EXPORTED ACTIVITY FUNCTIONS
// ============================================================================

export interface PlaceCallInput {
  workspaceId: string;
  phoneNumber: string;
  purpose: 'restaurant_reservation' | 'appointment_booking' | 'general_inquiry' | 'customer_service';
  script: {
    greeting: string;
    request: string;
    specialRequests?: string[];
    negotiationBounds?: {
      timeFlexibility?: string;
      priceRange?: { min: number; max: number };
      depositAllowed?: boolean;
    };
  };
  context?: {
    businessName?: string;
    dateTime?: string;
    partySize?: number;
    userName?: string;
    userPhone?: string;
  };
  idempotencyKey: string;
}

export interface PlaceCallOutput {
  callSid: string;
  callId: string;
  status: 'completed' | 'failed' | 'no_answer' | 'busy' | 'voicemail';
  transcript: string;
  outcome: 'success' | 'voicemail' | 'no_answer' | 'failed' | 'callback_needed';
  analysis?: {
    callSuccessful: boolean;
    summary: string;
    confirmedDateTime?: string;
    confirmationNumber?: string;
    needsFollowUp: boolean;
    followUpReason?: string;
  };
  recordingUrl?: string;
  durationSeconds?: number;
}

export async function placeCall(input: PlaceCallInput): Promise<PlaceCallOutput> {
  const retellConfig = await getRetellConfig(input.workspaceId);
  const twilioConfig = await getTwilioConfig(input.workspaceId);

  // Build dynamic prompt based on purpose
  let generalPrompt = GENERAL_CALLER_PROMPT;
  let beginMessage = input.script.greeting;

  if (input.purpose === 'restaurant_reservation') {
    generalPrompt = RESERVATION_AGENT_PROMPT
      .replace('{timeFlexibility}', input.script.negotiationBounds?.timeFlexibility || '30 minutes');

    beginMessage = `Hi! I'm calling to make a reservation${input.context?.businessName ? ` at ${input.context.businessName}` : ''}. `;
    if (input.context?.partySize) {
      beginMessage += `I'd like a table for ${input.context.partySize} `;
    }
    if (input.context?.dateTime) {
      beginMessage += `on ${input.context.dateTime}. `;
    }
    if (input.context?.userName) {
      beginMessage += `The reservation would be under the name ${input.context.userName}.`;
    }
  }

  // Create or use existing agent
  let agentId = retellConfig.agentId;

  if (!agentId) {
    // Create a temporary agent for this call
    agentId = await createRetellAgent(retellConfig, {
      agentName: `homeOS-${input.purpose}-${Date.now()}`,
      voiceId: retellConfig.voiceId || '11labs-Adrian',
      generalPrompt,
      beginMessage,
      endCallAfterSilenceSec: 15,
      maxCallDurationSec: 600,
      interruptionSensitivity: 0.7,
      enableBackchannel: true,
    });
  }

  // Format phone number to E.164
  const formattedPhone = formatPhoneNumber(input.phoneNumber);

  // Initiate the call
  const callResponse = await initiateRetellCall(retellConfig, {
    agentId,
    toPhoneNumber: formattedPhone,
    fromPhoneNumber: twilioConfig.phoneNumber,
    metadata: {
      workspaceId: input.workspaceId,
      purpose: input.purpose,
      idempotencyKey: input.idempotencyKey,
    },
    retellLlmDynamicVariables: {
      business_name: input.context?.businessName || 'the business',
      party_size: input.context?.partySize?.toString() || '2',
      date_time: input.context?.dateTime || 'today',
      user_name: input.context?.userName || 'Guest',
      special_requests: input.script.specialRequests?.join(', ') || 'none',
    },
  });

  // Wait for call to complete
  const finalCall = await waitForCallCompletion(retellConfig, callResponse.callId);

  // Analyze the transcript if available
  let analysis: PlaceCallOutput['analysis'] | undefined;

  if (finalCall.transcript) {
    analysis = await analyzeCallTranscript(
      input.workspaceId,
      input.purpose,
      finalCall.transcript,
      finalCall.callAnalysis
    );
  }

  // Determine outcome
  let outcome: PlaceCallOutput['outcome'] = 'failed';
  let status: PlaceCallOutput['status'] = 'failed';

  if (finalCall.callStatus === 'ended') {
    if (finalCall.callAnalysis?.callSuccessful) {
      outcome = 'success';
      status = 'completed';
    } else if (finalCall.transcript?.toLowerCase().includes('voicemail')) {
      outcome = 'voicemail';
      status = 'voicemail';
    } else if (finalCall.transcript?.toLowerCase().includes('call back')) {
      outcome = 'callback_needed';
      status = 'completed';
    } else {
      outcome = 'failed';
      status = 'completed';
    }
  }

  return {
    callSid: callResponse.callId,
    callId: callResponse.callId,
    status,
    transcript: finalCall.transcript || '',
    outcome,
    analysis,
    recordingUrl: finalCall.recordingUrl,
    durationSeconds: finalCall.startTimestamp && finalCall.endTimestamp
      ? Math.round((finalCall.endTimestamp - finalCall.startTimestamp) / 1000)
      : undefined,
  };
}

// Analyze transcript using Claude to extract structured information
async function analyzeCallTranscript(
  workspaceId: string,
  purpose: string,
  transcript: string,
  retellAnalysis?: RetellCallResponse['callAnalysis']
): Promise<PlaceCallOutput['analysis']> {
  const anthropicKey = process.env['ANTHROPIC_API_KEY'];
  if (!anthropicKey) {
    return {
      callSuccessful: retellAnalysis?.callSuccessful ?? false,
      summary: retellAnalysis?.callSummary ?? 'Unable to analyze transcript',
      needsFollowUp: true,
    };
  }

  const client = new Anthropic({ apiKey: anthropicKey });

  const response = await client.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 1024,
    system: `You analyze phone call transcripts and extract structured information.
For restaurant reservations, extract:
- Whether the reservation was successfully made
- Confirmed date and time
- Confirmation number if provided
- Whether follow-up is needed and why

Respond in JSON format:
{
  "callSuccessful": boolean,
  "summary": "brief summary",
  "confirmedDateTime": "YYYY-MM-DD HH:MM" or null,
  "confirmationNumber": "string" or null,
  "needsFollowUp": boolean,
  "followUpReason": "string" or null
}`,
    messages: [{
      role: 'user',
      content: `Analyze this ${purpose} call transcript:\n\n${transcript}`,
    }],
  });

  const text = response.content[0]?.type === 'text' ? response.content[0].text : '';
  const jsonText = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

  try {
    return JSON.parse(jsonText);
  } catch {
    return {
      callSuccessful: retellAnalysis?.callSuccessful ?? false,
      summary: retellAnalysis?.callSummary ?? 'Unable to parse analysis',
      needsFollowUp: true,
    };
  }
}

// Format phone number to E.164 format
function formatPhoneNumber(phone: string): string {
  const cleaned = phone.replace(/\D/g, '');
  if (cleaned.length === 10) {
    return `+1${cleaned}`;
  }
  if (cleaned.length === 11 && cleaned.startsWith('1')) {
    return `+${cleaned}`;
  }
  if (!phone.startsWith('+')) {
    return `+${cleaned}`;
  }
  return phone;
}

// ============================================================================
// HANDLE CALL OUTCOME
// ============================================================================

export interface HandleCallOutcomeInput {
  workspaceId: string;
  callResult: PlaceCallOutput;
}

export interface HandleCallOutcomeOutput {
  success: boolean;
  confirmedDateTime?: string;
  confirmationNumber?: string;
  needsFollowUp?: boolean;
  followUpAction?: string;
}

export async function handleCallOutcome(
  input: HandleCallOutcomeInput
): Promise<HandleCallOutcomeOutput> {
  const { callResult } = input;

  return {
    success: callResult.outcome === 'success',
    confirmedDateTime: callResult.analysis?.confirmedDateTime,
    confirmationNumber: callResult.analysis?.confirmationNumber,
    needsFollowUp: callResult.analysis?.needsFollowUp,
    followUpAction: callResult.analysis?.followUpReason,
  };
}

// ============================================================================
// SEARCH CANDIDATES (RESTAURANTS/BUSINESSES)
// ============================================================================

export interface SearchCandidatesInput {
  workspaceId: string;
  type: 'restaurant' | 'doctor' | 'salon' | 'service' | 'store';
  query: string;
  location: string;
  dateTime?: string;
  filters?: {
    minRating?: number;
    priceLevel?: number;
    openNow?: boolean;
  };
}

export interface Candidate {
  id: string;
  name: string;
  address: string;
  phoneNumber: string;
  rating?: number;
  priceLevel?: number;
  hours?: string[];
  website?: string;
}

export async function searchCandidates(input: SearchCandidatesInput): Promise<Candidate[]> {
  try {
    const config = await getGooglePlacesConfig(input.workspaceId);

    // Map type to Google Places type
    const typeMap: Record<string, string> = {
      restaurant: 'restaurant',
      doctor: 'doctor',
      salon: 'hair_care',
      service: 'establishment',
      store: 'store',
    };

    const results = await searchPlaces(config, {
      query: input.query,
      location: input.location,
      type: typeMap[input.type],
      openNow: input.filters?.openNow,
    });

    // Filter by rating and price level if specified
    let filtered = results;
    if (input.filters?.minRating) {
      filtered = filtered.filter((r) => (r.rating || 0) >= input.filters!.minRating!);
    }
    if (input.filters?.priceLevel !== undefined) {
      filtered = filtered.filter((r) => (r.priceLevel || 0) <= input.filters!.priceLevel!);
    }

    return filtered.map((r) => ({
      id: r.id,
      name: r.name,
      address: r.address,
      phoneNumber: r.phoneNumber,
      rating: r.rating,
      priceLevel: r.priceLevel,
      hours: r.hours,
      website: r.website,
    }));
  } catch (error) {
    console.error('Failed to search candidates:', error);

    // Return mock data for development
    if (process.env['NODE_ENV'] !== 'production') {
      return [
        {
          id: 'mock-1',
          name: 'Example Restaurant',
          address: '123 Main St, City, State',
          phoneNumber: '+1234567890',
          rating: 4.5,
          priceLevel: 2,
        },
      ];
    }

    throw error;
  }
}

// ============================================================================
// CALENDAR INTEGRATION
// ============================================================================

export interface CreateCalendarEventInput {
  workspaceId: string;
  userId: string;
  title: string;
  dateTime: string;
  durationMinutes?: number;
  location?: string;
  notes?: string;
  reminders?: number[]; // minutes before
}

export interface CalendarEvent {
  eventId: string;
  title: string;
  startTime: string;
  endTime: string;
  location?: string;
  link?: string;
}

export async function createCalendarEvent(
  input: CreateCalendarEventInput
): Promise<CalendarEvent> {
  // TODO: Implement Google Calendar API integration
  // For now, return a mock event

  const startTime = new Date(input.dateTime);
  const endTime = new Date(startTime.getTime() + (input.durationMinutes || 60) * 60000);

  return {
    eventId: `event-${Date.now()}`,
    title: input.title,
    startTime: startTime.toISOString(),
    endTime: endTime.toISOString(),
    location: input.location,
  };
}

export interface GetCalendarAvailabilityInput {
  workspaceId: string;
  userId: string;
  startDate: string;
  endDate: string;
}

export interface TimeSlot {
  start: string;
  end: string;
  available: boolean;
}

export async function getCalendarAvailability(
  input: GetCalendarAvailabilityInput
): Promise<TimeSlot[]> {
  // TODO: Implement Google Calendar API integration
  // For now, return mock availability

  return [
    { start: '09:00', end: '10:00', available: true },
    { start: '10:00', end: '11:00', available: false },
    { start: '11:00', end: '12:00', available: true },
    { start: '12:00', end: '13:00', available: false },
    { start: '13:00', end: '14:00', available: true },
    { start: '14:00', end: '15:00', available: true },
    { start: '15:00', end: '16:00', available: false },
    { start: '16:00', end: '17:00', available: true },
    { start: '17:00', end: '18:00', available: true },
  ];
}
