/**
 * All supported service providers for homeOS
 * Each provider requires specific configuration stored encrypted in workspace_secrets
 */

// LLM Providers
export type LLMProvider = 'anthropic' | 'openai';

// Voice AI Providers (for phone calls)
export type VoiceProvider = 'retell' | 'vapi' | 'bland';

// Telephony Providers (for phone numbers and call infrastructure)
export type TelephonyProvider = 'twilio' | 'vonage';

// Places/Search Providers
export type PlacesProvider = 'google_places' | 'yelp' | 'foursquare';

// Calendar Providers
export type CalendarProvider = 'google_calendar' | 'microsoft_outlook' | 'apple_calendar';

// Marketplace Providers
export type MarketplaceProvider = 'facebook_marketplace' | 'craigslist' | 'offerup' | 'mercari';

// Helper/Service Providers
export type HelperProvider = 'taskrabbit' | 'thumbtack' | 'angi' | 'nextdoor';

// Payment Providers
export type PaymentProvider = 'stripe' | 'square';

// Vision/Image Analysis
export type VisionProvider = 'anthropic_vision' | 'openai_vision' | 'google_vision';

// Email Providers
export type EmailProvider = 'sendgrid' | 'postmark' | 'ses';

// SMS Providers (separate from voice)
export type SMSProvider = 'twilio_sms' | 'messagebird';

// Storage Providers
export type StorageProvider = 'minio' | 's3' | 'gcs' | 'cloudflare_r2';

// Grocery/Shopping Providers
export type GroceryProvider = 'instacart' | 'amazon_fresh' | 'walmart';

// Transportation Providers
export type TransportProvider = 'uber' | 'lyft';

// School/Education Providers
export type EducationProvider = 'google_classroom' | 'canvas' | 'schoology' | 'clever';

// Healthcare Providers
export type HealthcareProvider = 'zocdoc' | 'healthgrades' | 'one_medical';

// Home Automation Providers
export type HomeAutomationProvider = 'homekit' | 'smartthings' | 'google_home' | 'alexa';

// All provider types union
export type ServiceProvider =
  | LLMProvider
  | VoiceProvider
  | TelephonyProvider
  | PlacesProvider
  | CalendarProvider
  | MarketplaceProvider
  | HelperProvider
  | PaymentProvider
  | VisionProvider
  | EmailProvider
  | SMSProvider
  | StorageProvider
  | GroceryProvider
  | TransportProvider
  | EducationProvider
  | HealthcareProvider
  | HomeAutomationProvider;

// Provider configuration requirements
export interface ProviderConfig {
  provider: ServiceProvider;
  displayName: string;
  category: ProviderCategory;
  authType: 'api_key' | 'oauth2' | 'basic' | 'bearer';
  requiredFields: string[];
  optionalFields?: string[];
  testEndpoint?: string;
  documentationUrl: string;
  pricingUrl?: string;
  sandboxAvailable: boolean;
}

export type ProviderCategory =
  | 'llm'
  | 'voice'
  | 'telephony'
  | 'places'
  | 'calendar'
  | 'marketplace'
  | 'helpers'
  | 'payment'
  | 'vision'
  | 'email'
  | 'sms'
  | 'storage'
  | 'grocery'
  | 'transport'
  | 'education'
  | 'healthcare'
  | 'home_automation';

// Provider configurations with setup requirements
export const PROVIDER_CONFIGS: Record<ServiceProvider, ProviderConfig> = {
  // LLM Providers
  anthropic: {
    provider: 'anthropic',
    displayName: 'Anthropic (Claude)',
    category: 'llm',
    authType: 'api_key',
    requiredFields: ['api_key'],
    testEndpoint: 'https://api.anthropic.com/v1/messages',
    documentationUrl: 'https://docs.anthropic.com/en/api/getting-started',
    pricingUrl: 'https://www.anthropic.com/pricing',
    sandboxAvailable: false,
  },
  openai: {
    provider: 'openai',
    displayName: 'OpenAI (GPT)',
    category: 'llm',
    authType: 'bearer',
    requiredFields: ['api_key'],
    testEndpoint: 'https://api.openai.com/v1/models',
    documentationUrl: 'https://platform.openai.com/docs/api-reference',
    pricingUrl: 'https://openai.com/pricing',
    sandboxAvailable: false,
  },

  // Voice AI Providers
  retell: {
    provider: 'retell',
    displayName: 'Retell AI',
    category: 'voice',
    authType: 'api_key',
    requiredFields: ['api_key'],
    optionalFields: ['agent_id', 'voice_id'],
    testEndpoint: 'https://api.retellai.com/v2/agent',
    documentationUrl: 'https://docs.retellai.com/',
    pricingUrl: 'https://www.retellai.com/pricing',
    sandboxAvailable: true,
  },
  vapi: {
    provider: 'vapi',
    displayName: 'Vapi',
    category: 'voice',
    authType: 'bearer',
    requiredFields: ['api_key'],
    optionalFields: ['assistant_id'],
    testEndpoint: 'https://api.vapi.ai/assistant',
    documentationUrl: 'https://docs.vapi.ai/',
    pricingUrl: 'https://vapi.ai/pricing',
    sandboxAvailable: true,
  },
  bland: {
    provider: 'bland',
    displayName: 'Bland AI',
    category: 'voice',
    authType: 'api_key',
    requiredFields: ['api_key'],
    testEndpoint: 'https://api.bland.ai/v1/calls',
    documentationUrl: 'https://docs.bland.ai/',
    pricingUrl: 'https://www.bland.ai/pricing',
    sandboxAvailable: true,
  },

  // Telephony Providers
  twilio: {
    provider: 'twilio',
    displayName: 'Twilio',
    category: 'telephony',
    authType: 'basic',
    requiredFields: ['account_sid', 'auth_token', 'phone_number'],
    optionalFields: ['messaging_service_sid'],
    testEndpoint: 'https://api.twilio.com/2010-04-01/Accounts',
    documentationUrl: 'https://www.twilio.com/docs',
    pricingUrl: 'https://www.twilio.com/pricing',
    sandboxAvailable: true,
  },
  vonage: {
    provider: 'vonage',
    displayName: 'Vonage',
    category: 'telephony',
    authType: 'api_key',
    requiredFields: ['api_key', 'api_secret', 'phone_number'],
    testEndpoint: 'https://api.nexmo.com/account/get-balance',
    documentationUrl: 'https://developer.vonage.com/',
    pricingUrl: 'https://www.vonage.com/pricing/',
    sandboxAvailable: true,
  },

  // Places Providers
  google_places: {
    provider: 'google_places',
    displayName: 'Google Places API',
    category: 'places',
    authType: 'api_key',
    requiredFields: ['api_key'],
    testEndpoint: 'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
    documentationUrl: 'https://developers.google.com/maps/documentation/places/web-service',
    pricingUrl: 'https://developers.google.com/maps/billing-and-pricing/pricing',
    sandboxAvailable: false,
  },
  yelp: {
    provider: 'yelp',
    displayName: 'Yelp Fusion API',
    category: 'places',
    authType: 'bearer',
    requiredFields: ['api_key'],
    testEndpoint: 'https://api.yelp.com/v3/businesses/search',
    documentationUrl: 'https://docs.developer.yelp.com/docs/fusion-intro',
    pricingUrl: 'https://fusion.yelp.com/',
    sandboxAvailable: true,
  },
  foursquare: {
    provider: 'foursquare',
    displayName: 'Foursquare Places API',
    category: 'places',
    authType: 'api_key',
    requiredFields: ['api_key'],
    testEndpoint: 'https://api.foursquare.com/v3/places/search',
    documentationUrl: 'https://docs.foursquare.com/',
    pricingUrl: 'https://foursquare.com/products/pricing/',
    sandboxAvailable: true,
  },

  // Calendar Providers
  google_calendar: {
    provider: 'google_calendar',
    displayName: 'Google Calendar',
    category: 'calendar',
    authType: 'oauth2',
    requiredFields: ['client_id', 'client_secret', 'refresh_token'],
    documentationUrl: 'https://developers.google.com/calendar/api/guides/overview',
    sandboxAvailable: true,
  },
  microsoft_outlook: {
    provider: 'microsoft_outlook',
    displayName: 'Microsoft Outlook Calendar',
    category: 'calendar',
    authType: 'oauth2',
    requiredFields: ['client_id', 'client_secret', 'refresh_token'],
    documentationUrl: 'https://learn.microsoft.com/en-us/graph/api/resources/calendar',
    sandboxAvailable: true,
  },
  apple_calendar: {
    provider: 'apple_calendar',
    displayName: 'Apple Calendar (iCloud)',
    category: 'calendar',
    authType: 'api_key',
    requiredFields: ['app_specific_password', 'apple_id'],
    documentationUrl: 'https://support.apple.com/en-us/HT204397',
    sandboxAvailable: false,
  },

  // Marketplace Providers
  facebook_marketplace: {
    provider: 'facebook_marketplace',
    displayName: 'Facebook Marketplace',
    category: 'marketplace',
    authType: 'oauth2',
    requiredFields: ['access_token', 'page_id'],
    documentationUrl: 'https://developers.facebook.com/docs/commerce-platform/',
    sandboxAvailable: true,
  },
  craigslist: {
    provider: 'craigslist',
    displayName: 'Craigslist',
    category: 'marketplace',
    authType: 'basic',
    requiredFields: ['email', 'password', 'phone_verification'],
    documentationUrl: 'https://www.craigslist.org/about/help/',
    sandboxAvailable: false,
  },
  offerup: {
    provider: 'offerup',
    displayName: 'OfferUp',
    category: 'marketplace',
    authType: 'oauth2',
    requiredFields: ['access_token'],
    documentationUrl: 'https://offerup.com/',
    sandboxAvailable: false,
  },
  mercari: {
    provider: 'mercari',
    displayName: 'Mercari',
    category: 'marketplace',
    authType: 'oauth2',
    requiredFields: ['access_token'],
    documentationUrl: 'https://www.mercari.com/',
    sandboxAvailable: false,
  },

  // Helper Service Providers
  taskrabbit: {
    provider: 'taskrabbit',
    displayName: 'TaskRabbit',
    category: 'helpers',
    authType: 'oauth2',
    requiredFields: ['client_id', 'client_secret', 'access_token'],
    documentationUrl: 'https://www.taskrabbit.com/',
    sandboxAvailable: false,
  },
  thumbtack: {
    provider: 'thumbtack',
    displayName: 'Thumbtack',
    category: 'helpers',
    authType: 'api_key',
    requiredFields: ['api_key'],
    documentationUrl: 'https://www.thumbtack.com/api',
    sandboxAvailable: true,
  },
  angi: {
    provider: 'angi',
    displayName: 'Angi (formerly Angie\'s List)',
    category: 'helpers',
    authType: 'api_key',
    requiredFields: ['api_key'],
    documentationUrl: 'https://www.angi.com/',
    sandboxAvailable: false,
  },
  nextdoor: {
    provider: 'nextdoor',
    displayName: 'Nextdoor',
    category: 'helpers',
    authType: 'oauth2',
    requiredFields: ['access_token'],
    documentationUrl: 'https://developer.nextdoor.com/',
    sandboxAvailable: true,
  },

  // Payment Providers
  stripe: {
    provider: 'stripe',
    displayName: 'Stripe',
    category: 'payment',
    authType: 'api_key',
    requiredFields: ['secret_key'],
    optionalFields: ['publishable_key', 'webhook_secret'],
    testEndpoint: 'https://api.stripe.com/v1/balance',
    documentationUrl: 'https://stripe.com/docs/api',
    pricingUrl: 'https://stripe.com/pricing',
    sandboxAvailable: true,
  },
  square: {
    provider: 'square',
    displayName: 'Square',
    category: 'payment',
    authType: 'bearer',
    requiredFields: ['access_token'],
    optionalFields: ['location_id'],
    testEndpoint: 'https://connect.squareup.com/v2/locations',
    documentationUrl: 'https://developer.squareup.com/docs',
    pricingUrl: 'https://squareup.com/us/en/pricing',
    sandboxAvailable: true,
  },

  // Vision Providers (reuse LLM keys)
  anthropic_vision: {
    provider: 'anthropic_vision',
    displayName: 'Claude Vision',
    category: 'vision',
    authType: 'api_key',
    requiredFields: ['api_key'],
    documentationUrl: 'https://docs.anthropic.com/en/docs/build-with-claude/vision',
    sandboxAvailable: false,
  },
  openai_vision: {
    provider: 'openai_vision',
    displayName: 'GPT-4 Vision',
    category: 'vision',
    authType: 'bearer',
    requiredFields: ['api_key'],
    documentationUrl: 'https://platform.openai.com/docs/guides/vision',
    sandboxAvailable: false,
  },
  google_vision: {
    provider: 'google_vision',
    displayName: 'Google Cloud Vision',
    category: 'vision',
    authType: 'api_key',
    requiredFields: ['api_key'],
    testEndpoint: 'https://vision.googleapis.com/v1/images:annotate',
    documentationUrl: 'https://cloud.google.com/vision/docs',
    pricingUrl: 'https://cloud.google.com/vision/pricing',
    sandboxAvailable: true,
  },

  // Email Providers
  sendgrid: {
    provider: 'sendgrid',
    displayName: 'SendGrid',
    category: 'email',
    authType: 'bearer',
    requiredFields: ['api_key'],
    optionalFields: ['from_email', 'from_name'],
    testEndpoint: 'https://api.sendgrid.com/v3/user/profile',
    documentationUrl: 'https://docs.sendgrid.com/',
    pricingUrl: 'https://sendgrid.com/pricing/',
    sandboxAvailable: true,
  },
  postmark: {
    provider: 'postmark',
    displayName: 'Postmark',
    category: 'email',
    authType: 'api_key',
    requiredFields: ['server_token'],
    optionalFields: ['from_email'],
    testEndpoint: 'https://api.postmarkapp.com/server',
    documentationUrl: 'https://postmarkapp.com/developer',
    pricingUrl: 'https://postmarkapp.com/pricing',
    sandboxAvailable: true,
  },
  ses: {
    provider: 'ses',
    displayName: 'Amazon SES',
    category: 'email',
    authType: 'api_key',
    requiredFields: ['access_key_id', 'secret_access_key', 'region'],
    documentationUrl: 'https://docs.aws.amazon.com/ses/',
    pricingUrl: 'https://aws.amazon.com/ses/pricing/',
    sandboxAvailable: true,
  },

  // SMS Providers
  twilio_sms: {
    provider: 'twilio_sms',
    displayName: 'Twilio SMS',
    category: 'sms',
    authType: 'basic',
    requiredFields: ['account_sid', 'auth_token', 'phone_number'],
    documentationUrl: 'https://www.twilio.com/docs/sms',
    pricingUrl: 'https://www.twilio.com/sms/pricing',
    sandboxAvailable: true,
  },
  messagebird: {
    provider: 'messagebird',
    displayName: 'MessageBird',
    category: 'sms',
    authType: 'api_key',
    requiredFields: ['api_key', 'originator'],
    documentationUrl: 'https://developers.messagebird.com/',
    pricingUrl: 'https://messagebird.com/pricing/',
    sandboxAvailable: true,
  },

  // Storage Providers
  minio: {
    provider: 'minio',
    displayName: 'MinIO (Self-hosted S3)',
    category: 'storage',
    authType: 'api_key',
    requiredFields: ['endpoint', 'access_key', 'secret_key', 'bucket'],
    documentationUrl: 'https://min.io/docs/',
    sandboxAvailable: true,
  },
  s3: {
    provider: 's3',
    displayName: 'Amazon S3',
    category: 'storage',
    authType: 'api_key',
    requiredFields: ['access_key_id', 'secret_access_key', 'region', 'bucket'],
    documentationUrl: 'https://docs.aws.amazon.com/s3/',
    pricingUrl: 'https://aws.amazon.com/s3/pricing/',
    sandboxAvailable: true,
  },
  gcs: {
    provider: 'gcs',
    displayName: 'Google Cloud Storage',
    category: 'storage',
    authType: 'api_key',
    requiredFields: ['service_account_json', 'bucket'],
    documentationUrl: 'https://cloud.google.com/storage/docs',
    pricingUrl: 'https://cloud.google.com/storage/pricing',
    sandboxAvailable: true,
  },
  cloudflare_r2: {
    provider: 'cloudflare_r2',
    displayName: 'Cloudflare R2',
    category: 'storage',
    authType: 'api_key',
    requiredFields: ['account_id', 'access_key_id', 'secret_access_key', 'bucket'],
    documentationUrl: 'https://developers.cloudflare.com/r2/',
    pricingUrl: 'https://www.cloudflare.com/products/r2/',
    sandboxAvailable: true,
  },

  // Grocery Providers
  instacart: {
    provider: 'instacart',
    displayName: 'Instacart',
    category: 'grocery',
    authType: 'oauth2',
    requiredFields: ['client_id', 'client_secret', 'access_token'],
    documentationUrl: 'https://docs.instacart.com/',
    sandboxAvailable: true,
  },
  amazon_fresh: {
    provider: 'amazon_fresh',
    displayName: 'Amazon Fresh',
    category: 'grocery',
    authType: 'oauth2',
    requiredFields: ['access_token', 'refresh_token'],
    documentationUrl: 'https://developer.amazon.com/',
    sandboxAvailable: false,
  },
  walmart: {
    provider: 'walmart',
    displayName: 'Walmart Grocery',
    category: 'grocery',
    authType: 'api_key',
    requiredFields: ['client_id', 'client_secret'],
    documentationUrl: 'https://developer.walmart.com/',
    pricingUrl: 'https://developer.walmart.com/pricing',
    sandboxAvailable: true,
  },

  // Transportation Providers
  uber: {
    provider: 'uber',
    displayName: 'Uber',
    category: 'transport',
    authType: 'oauth2',
    requiredFields: ['client_id', 'client_secret', 'access_token'],
    documentationUrl: 'https://developer.uber.com/docs',
    sandboxAvailable: true,
  },
  lyft: {
    provider: 'lyft',
    displayName: 'Lyft',
    category: 'transport',
    authType: 'oauth2',
    requiredFields: ['client_id', 'client_secret', 'access_token'],
    documentationUrl: 'https://developer.lyft.com/docs',
    sandboxAvailable: true,
  },

  // Education Providers
  google_classroom: {
    provider: 'google_classroom',
    displayName: 'Google Classroom',
    category: 'education',
    authType: 'oauth2',
    requiredFields: ['client_id', 'client_secret', 'refresh_token'],
    documentationUrl: 'https://developers.google.com/classroom',
    sandboxAvailable: true,
  },
  canvas: {
    provider: 'canvas',
    displayName: 'Canvas LMS',
    category: 'education',
    authType: 'bearer',
    requiredFields: ['access_token', 'domain'],
    documentationUrl: 'https://canvas.instructure.com/doc/api/',
    sandboxAvailable: true,
  },
  schoology: {
    provider: 'schoology',
    displayName: 'Schoology',
    category: 'education',
    authType: 'oauth2',
    requiredFields: ['consumer_key', 'consumer_secret'],
    documentationUrl: 'https://developers.schoology.com/',
    sandboxAvailable: true,
  },
  clever: {
    provider: 'clever',
    displayName: 'Clever',
    category: 'education',
    authType: 'oauth2',
    requiredFields: ['client_id', 'client_secret'],
    documentationUrl: 'https://dev.clever.com/',
    sandboxAvailable: true,
  },

  // Healthcare Providers
  zocdoc: {
    provider: 'zocdoc',
    displayName: 'Zocdoc',
    category: 'healthcare',
    authType: 'oauth2',
    requiredFields: ['access_token'],
    documentationUrl: 'https://www.zocdoc.com/',
    sandboxAvailable: false,
  },
  healthgrades: {
    provider: 'healthgrades',
    displayName: 'Healthgrades',
    category: 'healthcare',
    authType: 'api_key',
    requiredFields: ['api_key'],
    documentationUrl: 'https://www.healthgrades.com/',
    sandboxAvailable: false,
  },
  one_medical: {
    provider: 'one_medical',
    displayName: 'One Medical',
    category: 'healthcare',
    authType: 'oauth2',
    requiredFields: ['access_token'],
    documentationUrl: 'https://www.onemedical.com/',
    sandboxAvailable: false,
  },

  // Home Automation Providers
  homekit: {
    provider: 'homekit',
    displayName: 'Apple HomeKit',
    category: 'home_automation',
    authType: 'oauth2',
    requiredFields: ['home_hub_pairing'],
    documentationUrl: 'https://developer.apple.com/homekit/',
    sandboxAvailable: false,
  },
  smartthings: {
    provider: 'smartthings',
    displayName: 'Samsung SmartThings',
    category: 'home_automation',
    authType: 'bearer',
    requiredFields: ['personal_access_token'],
    testEndpoint: 'https://api.smartthings.com/v1/locations',
    documentationUrl: 'https://developer.smartthings.com/docs/api/public/',
    sandboxAvailable: true,
  },
  google_home: {
    provider: 'google_home',
    displayName: 'Google Home',
    category: 'home_automation',
    authType: 'oauth2',
    requiredFields: ['client_id', 'client_secret', 'refresh_token'],
    documentationUrl: 'https://developers.google.com/assistant/smarthome',
    sandboxAvailable: true,
  },
  alexa: {
    provider: 'alexa',
    displayName: 'Amazon Alexa',
    category: 'home_automation',
    authType: 'oauth2',
    requiredFields: ['client_id', 'client_secret', 'refresh_token'],
    documentationUrl: 'https://developer.amazon.com/alexa',
    sandboxAvailable: true,
  },
};

// Get providers by category
export function getProvidersByCategory(category: ProviderCategory): ProviderConfig[] {
  return Object.values(PROVIDER_CONFIGS).filter((p) => p.category === category);
}

// Get required providers for a workflow
export interface WorkflowProviderRequirements {
  required: ServiceProvider[];
  optional: ServiceProvider[];
  description: string;
}

export const WORKFLOW_PROVIDER_REQUIREMENTS: Record<string, WorkflowProviderRequirements> = {
  ReservationCallWorkflow: {
    required: ['retell', 'twilio', 'google_places'],
    optional: ['google_calendar', 'yelp'],
    description: 'Make restaurant reservations via AI phone calls',
  },
  MarketplaceSellWorkflow: {
    required: ['anthropic', 'facebook_marketplace'],
    optional: ['anthropic_vision', 'craigslist', 'offerup'],
    description: 'Sell items on marketplace platforms',
  },
  HireHelperWorkflow: {
    required: ['taskrabbit'],
    optional: ['thumbtack', 'angi', 'stripe'],
    description: 'Find and book helpers for tasks',
  },
  ChatTurnWorkflow: {
    required: ['anthropic'],
    optional: ['openai'],
    description: 'Main conversational AI workflow',
  },
  GroceryShoppingWorkflow: {
    required: ['instacart'],
    optional: ['amazon_fresh', 'walmart'],
    description: 'Order groceries for delivery',
  },
  TransportationWorkflow: {
    required: ['uber'],
    optional: ['lyft'],
    description: 'Book rides and transportation',
  },
  SchoolManagementWorkflow: {
    required: ['google_classroom'],
    optional: ['canvas', 'clever'],
    description: 'Manage school activities and homework',
  },
  HealthcareWorkflow: {
    required: ['google_calendar'],
    optional: ['zocdoc', 'one_medical'],
    description: 'Book and manage healthcare appointments',
  },
  HomeAutomationWorkflow: {
    required: ['smartthings'],
    optional: ['homekit', 'google_home', 'alexa'],
    description: 'Control smart home devices',
  },
};
