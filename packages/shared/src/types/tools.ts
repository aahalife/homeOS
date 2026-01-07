import type { RiskLevel } from './task.js';

export interface ToolDefinition {
  name: string;
  description: string;
  category: ToolCategory;
  riskLevel: RiskLevel;
  requiresApproval: boolean;
  inputSchema: Record<string, unknown>;
  outputSchema: Record<string, unknown>;
}

export type ToolCategory =
  | 'telephony'
  | 'marketplace'
  | 'helpers'
  | 'calendar'
  | 'groceries'
  | 'content'
  | 'planning'
  | 'memory'
  | 'integration';

export interface TelephonyPlaceCallInput {
  phoneNumber: string;
  purpose: string;
  constraints: string[];
  negotiationBounds: {
    timeFlexibility?: string;
    priceRange?: { min: number; max: number };
  };
  allowedDisclosures: string[];
  notAllowed: string[];
}

export interface TelephonyPlaceCallOutput {
  callSid: string;
  transcript: string;
  outcomeSummary: string;
  followUps: string[];
  success: boolean;
}

export interface MarketplaceCreateListingInput {
  title: string;
  description: string;
  price: number;
  priceFloor: number;
  photos: string[];
  category: string;
  condition: string;
}

export interface MarketplaceListingOutput {
  listingId: string;
  platform: string;
  url: string;
  status: 'draft' | 'active' | 'sold' | 'expired';
}

export interface HelpersSearchInput {
  taskType: string;
  location: string;
  dateRange: { start: string; end: string };
  requirements: string[];
}

export interface HelpersCandidate {
  id: string;
  name: string;
  platform: string;
  rating: number;
  reviewCount: number;
  priceEstimate: string;
  availability: string;
}
