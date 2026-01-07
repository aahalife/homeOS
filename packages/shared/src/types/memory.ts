export type MemoryType = 'working' | 'episodic' | 'semantic' | 'procedural' | 'strategic';

export type EntityKind = 'person' | 'place' | 'organization' | 'product' | 'event' | 'concept';

export type PIILevel = 'none' | 'low' | 'medium' | 'high';

export interface MemoryItem {
  id: string;
  workspaceId: string;
  type: MemoryType;
  content: string;
  createdAt: string;
  salience: number;
  piiLevel: PIILevel;
  embedding?: number[];
}

export interface Entity {
  id: string;
  workspaceId: string;
  kind: EntityKind;
  name: string;
  attributes: Record<string, unknown>;
}

export interface MemoryEdge {
  fromId: string;
  toId: string;
  relation: string;
  weight: number;
}

export interface Procedure {
  id: string;
  workspaceId: string;
  name: string;
  trigger: string;
  steps: ProcedureStep[];
  toolsAllowed: string[];
}

export interface ProcedureStep {
  order: number;
  action: string;
  conditions?: Record<string, unknown>;
}

export interface Objective {
  id: string;
  workspaceId: string;
  horizon: 'short' | 'medium' | 'long';
  description: string;
  metrics: Record<string, unknown>;
}

export interface WorkingContext {
  taskId: string;
  scratchpad: Record<string, unknown>;
  expiresAt: string;
}

export interface CreateMemoryInput {
  workspaceId: string;
  type: MemoryType;
  content: string;
  salience?: number;
  piiLevel?: PIILevel;
}

export interface MemorySearchInput {
  workspaceId: string;
  query: string;
  types?: MemoryType[];
  limit?: number;
  minSalience?: number;
}
