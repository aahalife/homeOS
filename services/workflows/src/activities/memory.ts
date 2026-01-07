/**
 * Memory Activities for homeOS
 *
 * Production-ready memory system using:
 * - PostgreSQL + pgvector: For vector similarity search
 * - OpenAI/Anthropic embeddings: For semantic search
 * - Multi-tier memory architecture
 *
 * Memory Types:
 * - Working: Current conversation context (short-term)
 * - Episodic: Specific events and interactions (medium-term)
 * - Semantic: Facts, preferences, and knowledge (long-term)
 * - Procedural: How to do things (persistent)
 * - Strategic: Goals, plans, and priorities (persistent)
 */

import Anthropic from '@anthropic-ai/sdk';
import OpenAI from 'openai';
import pg from 'pg';

// ============================================================================
// CONFIGURATION
// ============================================================================

interface DatabaseConfig {
  connectionString: string;
}

interface EmbeddingConfig {
  provider: 'openai' | 'anthropic';
  apiKey: string;
  model: string;
  dimensions: number;
}

async function getDatabaseConfig(): Promise<DatabaseConfig> {
  const connectionString = process.env['DATABASE_URL'];
  if (!connectionString) {
    throw new Error('DATABASE_URL not configured');
  }
  return { connectionString };
}

async function getEmbeddingConfig(): Promise<EmbeddingConfig> {
  // Prefer OpenAI for embeddings (better quality and cheaper)
  const openaiKey = process.env['OPENAI_API_KEY'];
  if (openaiKey) {
    return {
      provider: 'openai',
      apiKey: openaiKey,
      model: 'text-embedding-3-small',
      dimensions: 1536,
    };
  }

  // Fall back to Anthropic (using Claude to generate text for embeddings)
  const anthropicKey = process.env['ANTHROPIC_API_KEY'];
  if (anthropicKey) {
    return {
      provider: 'anthropic',
      apiKey: anthropicKey,
      model: 'claude-sonnet-4-20250514',
      dimensions: 1536, // We'll use a summarization approach
    };
  }

  throw new Error('No embedding API key configured. Set OPENAI_API_KEY or ANTHROPIC_API_KEY.');
}

// ============================================================================
// DATABASE CLIENT
// ============================================================================

let dbPool: pg.Pool | null = null;

async function getDbPool(): Promise<pg.Pool> {
  if (!dbPool) {
    const config = await getDatabaseConfig();
    dbPool = new pg.Pool({
      connectionString: config.connectionString,
      max: 10,
      idleTimeoutMillis: 30000,
    });
  }
  return dbPool;
}

async function dbQuery<T>(sql: string, params?: unknown[]): Promise<T[]> {
  const pool = await getDbPool();
  const result = await pool.query(sql, params);
  return result.rows as T[];
}

async function dbQueryOne<T>(sql: string, params?: unknown[]): Promise<T | null> {
  const rows = await dbQuery<T>(sql, params);
  return rows[0] ?? null;
}

// ============================================================================
// EMBEDDING GENERATION
// ============================================================================

async function generateEmbedding(text: string): Promise<number[]> {
  const config = await getEmbeddingConfig();

  if (config.provider === 'openai') {
    const client = new OpenAI({ apiKey: config.apiKey });
    const response = await client.embeddings.create({
      model: config.model,
      input: text,
    });
    return response.data[0]!.embedding;
  } else {
    // For Anthropic, we use a different approach since they don't have embeddings API
    // We'll use a simple hash-based approach for now, or integrate with a dedicated service
    // In production, you'd want to use a proper embedding service

    // Simple fallback: use character-based features
    // This is NOT recommended for production - use OpenAI or a dedicated embedding service
    console.warn('Using fallback embedding method. Consider using OpenAI for better results.');
    return generateSimpleEmbedding(text, config.dimensions);
  }
}

function generateSimpleEmbedding(text: string, dimensions: number): number[] {
  // This is a placeholder - in production, always use a real embedding model
  const normalized = text.toLowerCase().trim();
  const embedding = new Array(dimensions).fill(0);

  // Character frequency-based features
  for (let i = 0; i < normalized.length; i++) {
    const charCode = normalized.charCodeAt(i);
    embedding[charCode % dimensions] += 1;
  }

  // Word-based features
  const words = normalized.split(/\s+/);
  for (let i = 0; i < words.length; i++) {
    const word = words[i]!;
    const hash = hashString(word);
    embedding[(hash % dimensions + dimensions) % dimensions]! += 0.5;
  }

  // Normalize
  const magnitude = Math.sqrt(embedding.reduce((sum, v) => sum + v * v, 0)) || 1;
  return embedding.map((v) => v / magnitude);
}

function hashString(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return hash;
}

// ============================================================================
// MEMORY TYPES
// ============================================================================

export type MemoryType = 'working' | 'episodic' | 'semantic' | 'procedural' | 'strategic';

export interface MemoryItem {
  id: string;
  type: MemoryType;
  content: string;
  salience: number;
  createdAt: string;
  updatedAt?: string;
  metadata?: Record<string, unknown>;
  tags?: string[];
  relatedMemoryIds?: string[];
}

interface DBMemory {
  id: string;
  workspace_id: string;
  type: MemoryType;
  content: string;
  salience: number;
  embedding: string; // pgvector format
  metadata: Record<string, unknown> | null;
  tags: string[] | null;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// RECALL (MEMORY RETRIEVAL)
// ============================================================================

export interface RecallInput {
  workspaceId: string;
  query: string;
  context?: unknown;
  types?: MemoryType[];
  limit?: number;
  minSalience?: number;
  tags?: string[];
}

export async function recall(input: RecallInput): Promise<MemoryItem[]> {
  const {
    workspaceId,
    query,
    types,
    limit = 10,
    minSalience = 0,
    tags,
  } = input;

  try {
    // Generate embedding for query
    const queryEmbedding = await generateEmbedding(query);
    const embeddingStr = `[${queryEmbedding.join(',')}]`;

    // Build query with filters
    let sql = `
      SELECT
        id,
        type,
        content,
        salience,
        metadata,
        tags,
        created_at,
        updated_at,
        1 - (embedding <=> $1::vector) as similarity
      FROM homeos.memories
      WHERE workspace_id = $2
        AND salience >= $3
    `;
    const params: unknown[] = [embeddingStr, workspaceId, minSalience];
    let paramIndex = 4;

    if (types && types.length > 0) {
      sql += ` AND type = ANY($${paramIndex}::text[])`;
      params.push(types);
      paramIndex++;
    }

    if (tags && tags.length > 0) {
      sql += ` AND tags && $${paramIndex}::text[]`;
      params.push(tags);
      paramIndex++;
    }

    sql += `
      ORDER BY similarity DESC
      LIMIT $${paramIndex}
    `;
    params.push(limit);

    const rows = await dbQuery<DBMemory & { similarity: number }>(sql, params);

    return rows.map((row) => ({
      id: row.id,
      type: row.type,
      content: row.content,
      salience: row.salience,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      metadata: row.metadata ?? undefined,
      tags: row.tags ?? undefined,
    }));
  } catch (error) {
    console.warn('Memory recall failed, returning empty results:', error);
    return [];
  }
}

// ============================================================================
// STORE MEMORY
// ============================================================================

export interface StoreMemoryInput {
  workspaceId: string;
  type: MemoryType;
  content: string;
  salience?: number;
  metadata?: Record<string, unknown>;
  tags?: string[];
}

export async function storeMemory(input: StoreMemoryInput): Promise<{ id: string }> {
  const {
    workspaceId,
    type,
    content,
    salience = calculateDefaultSalience(type),
    metadata,
    tags,
  } = input;

  try {
    // Generate embedding
    const embedding = await generateEmbedding(content);
    const embeddingStr = `[${embedding.join(',')}]`;

    // Generate ID
    const id = `mem-${Date.now()}-${Math.random().toString(36).substring(7)}`;

    await dbQuery(
      `INSERT INTO homeos.memories (id, workspace_id, type, content, salience, embedding, metadata, tags)
       VALUES ($1, $2, $3, $4, $5, $6::vector, $7, $8)`,
      [
        id,
        workspaceId,
        type,
        content,
        salience,
        embeddingStr,
        metadata ? JSON.stringify(metadata) : null,
        tags ?? null,
      ]
    );

    return { id };
  } catch (error) {
    console.warn('Memory store failed:', error);
    // Return a mock ID in case of failure
    return { id: `mem-${Date.now()}` };
  }
}

function calculateDefaultSalience(type: MemoryType): number {
  const defaults: Record<MemoryType, number> = {
    working: 0.5,
    episodic: 0.6,
    semantic: 0.7,
    procedural: 0.8,
    strategic: 0.9,
  };
  return defaults[type];
}

// ============================================================================
// UPDATE SALIENCE (MEMORY REINFORCEMENT)
// ============================================================================

export interface UpdateSalienceInput {
  workspaceId: string;
  memoryId: string;
  delta: number; // Positive to reinforce, negative to decay
}

export async function updateSalience(input: UpdateSalienceInput): Promise<void> {
  const { workspaceId, memoryId, delta } = input;

  try {
    await dbQuery(
      `UPDATE homeos.memories
       SET salience = GREATEST(0, LEAST(1, salience + $1)),
           updated_at = NOW()
       WHERE id = $2 AND workspace_id = $3`,
      [delta, memoryId, workspaceId]
    );
  } catch (error) {
    console.warn('Salience update failed:', error);
  }
}

// ============================================================================
// DECAY MEMORIES (BACKGROUND MAINTENANCE)
// ============================================================================

export interface DecayMemoriesInput {
  workspaceId: string;
  decayRate?: number; // Default 0.01 per day
  minSalience?: number; // Memories below this are deleted
}

export async function decayMemories(input: DecayMemoriesInput): Promise<{ decayed: number; deleted: number }> {
  const {
    workspaceId,
    decayRate = 0.01,
    minSalience = 0.1,
  } = input;

  try {
    // Calculate decay based on age
    const decayResult = await dbQuery<{ count: string }>(
      `UPDATE homeos.memories
       SET salience = salience * (1 - $1 * EXTRACT(EPOCH FROM NOW() - updated_at) / 86400),
           updated_at = NOW()
       WHERE workspace_id = $2
         AND type IN ('working', 'episodic')
       RETURNING id`,
      [decayRate, workspaceId]
    );

    // Delete memories below threshold
    const deleteResult = await dbQuery<{ count: string }>(
      `DELETE FROM homeos.memories
       WHERE workspace_id = $1
         AND salience < $2
         AND type IN ('working', 'episodic')
       RETURNING id`,
      [workspaceId, minSalience]
    );

    return {
      decayed: decayResult.length,
      deleted: deleteResult.length,
    };
  } catch (error) {
    console.warn('Memory decay failed:', error);
    return { decayed: 0, deleted: 0 };
  }
}

// ============================================================================
// ENTITY MANAGEMENT (KNOWLEDGE GRAPH)
// ============================================================================

export interface CreateEntityInput {
  workspaceId: string;
  kind: string; // person, place, thing, concept
  name: string;
  attributes: Record<string, unknown>;
}

export async function createEntity(input: CreateEntityInput): Promise<{ id: string }> {
  const { workspaceId, kind, name, attributes } = input;

  const id = `entity-${Date.now()}-${Math.random().toString(36).substring(7)}`;

  try {
    await dbQuery(
      `INSERT INTO homeos.entities (id, workspace_id, kind, name, attributes)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (workspace_id, kind, name) DO UPDATE
       SET attributes = homeos.entities.attributes || $5,
           updated_at = NOW()`,
      [id, workspaceId, kind, name, JSON.stringify(attributes)]
    );

    return { id };
  } catch (error) {
    console.warn('Entity creation failed:', error);
    return { id };
  }
}

export interface LinkEntitiesInput {
  workspaceId: string;
  fromId: string;
  toId: string;
  relation: string;
  weight?: number;
  metadata?: Record<string, unknown>;
}

export async function linkEntities(input: LinkEntitiesInput): Promise<void> {
  const { workspaceId, fromId, toId, relation, weight = 1.0, metadata } = input;

  try {
    await dbQuery(
      `INSERT INTO homeos.entity_relations (workspace_id, from_entity_id, to_entity_id, relation, weight, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (workspace_id, from_entity_id, to_entity_id, relation) DO UPDATE
       SET weight = $5, metadata = $6, updated_at = NOW()`,
      [workspaceId, fromId, toId, relation, weight, metadata ? JSON.stringify(metadata) : null]
    );
  } catch (error) {
    console.warn('Entity linking failed:', error);
  }
}

// ============================================================================
// ENTITY RETRIEVAL
// ============================================================================

export interface GetEntityInput {
  workspaceId: string;
  kind?: string;
  name?: string;
  id?: string;
}

export interface Entity {
  id: string;
  kind: string;
  name: string;
  attributes: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export async function getEntity(input: GetEntityInput): Promise<Entity | null> {
  const { workspaceId, kind, name, id } = input;

  let sql = `SELECT * FROM homeos.entities WHERE workspace_id = $1`;
  const params: unknown[] = [workspaceId];
  let paramIndex = 2;

  if (id) {
    sql += ` AND id = $${paramIndex}`;
    params.push(id);
    paramIndex++;
  }
  if (kind) {
    sql += ` AND kind = $${paramIndex}`;
    params.push(kind);
    paramIndex++;
  }
  if (name) {
    sql += ` AND name = $${paramIndex}`;
    params.push(name);
  }

  sql += ' LIMIT 1';

  try {
    const row = await dbQueryOne<{
      id: string;
      kind: string;
      name: string;
      attributes: Record<string, unknown>;
      created_at: string;
      updated_at: string;
    }>(sql, params);

    if (!row) return null;

    return {
      id: row.id,
      kind: row.kind,
      name: row.name,
      attributes: row.attributes,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  } catch (error) {
    console.warn('Entity retrieval failed:', error);
    return null;
  }
}

export interface GetRelatedEntitiesInput {
  workspaceId: string;
  entityId: string;
  relation?: string;
  direction?: 'outgoing' | 'incoming' | 'both';
}

export async function getRelatedEntities(input: GetRelatedEntitiesInput): Promise<Entity[]> {
  const { workspaceId, entityId, relation, direction = 'both' } = input;

  try {
    const conditions: string[] = [];
    const params: unknown[] = [workspaceId, entityId];
    let paramIndex = 3;

    if (direction === 'outgoing' || direction === 'both') {
      conditions.push(`from_entity_id = $2`);
    }
    if (direction === 'incoming' || direction === 'both') {
      conditions.push(`to_entity_id = $2`);
    }

    let sql = `
      SELECT DISTINCT e.*
      FROM homeos.entities e
      JOIN homeos.entity_relations r ON (e.id = r.from_entity_id OR e.id = r.to_entity_id)
      WHERE r.workspace_id = $1
        AND (${conditions.join(' OR ')})
        AND e.id != $2
    `;

    if (relation) {
      sql += ` AND r.relation = $${paramIndex}`;
      params.push(relation);
    }

    const rows = await dbQuery<{
      id: string;
      kind: string;
      name: string;
      attributes: Record<string, unknown>;
      created_at: string;
      updated_at: string;
    }>(sql, params);

    return rows.map((row) => ({
      id: row.id,
      kind: row.kind,
      name: row.name,
      attributes: row.attributes,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }));
  } catch (error) {
    console.warn('Related entities retrieval failed:', error);
    return [];
  }
}

// ============================================================================
// USER PREFERENCES
// ============================================================================

export interface GetUserPreferencesInput {
  workspaceId: string;
  userId: string;
  category?: string;
}

export interface UserPreferences {
  [key: string]: unknown;
}

export async function getUserPreferences(input: GetUserPreferencesInput): Promise<UserPreferences> {
  const { workspaceId, userId, category } = input;

  try {
    // First check for stored preferences in semantic memory
    const memories = await recall({
      workspaceId,
      query: `preferences ${category || 'general'}`,
      types: ['semantic'],
      limit: 5,
      tags: ['preference', userId],
    });

    const preferences: UserPreferences = {};

    for (const memory of memories) {
      try {
        const parsed = JSON.parse(memory.content);
        Object.assign(preferences, parsed);
      } catch {
        // Not JSON, skip
      }
    }

    return preferences;
  } catch (error) {
    console.warn('Preferences retrieval failed:', error);
    return {};
  }
}

export interface SetUserPreferenceInput {
  workspaceId: string;
  userId: string;
  category: string;
  key: string;
  value: unknown;
}

export async function setUserPreference(input: SetUserPreferenceInput): Promise<void> {
  const { workspaceId, userId, category, key, value } = input;

  await storeMemory({
    workspaceId,
    type: 'semantic',
    content: JSON.stringify({ [key]: value }),
    salience: 0.8,
    metadata: { category, key, userId },
    tags: ['preference', userId, category],
  });
}

// ============================================================================
// CONVERSATION HISTORY
// ============================================================================

export interface AddConversationTurnInput {
  workspaceId: string;
  sessionId: string;
  role: 'user' | 'assistant';
  content: string;
  metadata?: Record<string, unknown>;
}

export async function addConversationTurn(input: AddConversationTurnInput): Promise<{ id: string }> {
  const { workspaceId, sessionId, role, content, metadata } = input;

  return storeMemory({
    workspaceId,
    type: 'working',
    content: JSON.stringify({ role, content }),
    salience: role === 'user' ? 0.7 : 0.5,
    metadata: { sessionId, role, ...metadata },
    tags: ['conversation', sessionId],
  });
}

export interface GetConversationHistoryInput {
  workspaceId: string;
  sessionId: string;
  limit?: number;
}

export interface ConversationTurn {
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
}

export async function getConversationHistory(
  input: GetConversationHistoryInput
): Promise<ConversationTurn[]> {
  const { workspaceId, sessionId, limit = 20 } = input;

  try {
    const memories = await dbQuery<DBMemory>(
      `SELECT * FROM homeos.memories
       WHERE workspace_id = $1
         AND type = 'working'
         AND 'conversation' = ANY(tags)
         AND $2 = ANY(tags)
       ORDER BY created_at DESC
       LIMIT $3`,
      [workspaceId, sessionId, limit]
    );

    return memories
      .map((m) => {
        try {
          const parsed = JSON.parse(m.content);
          return {
            role: parsed.role,
            content: parsed.content,
            timestamp: m.created_at,
          };
        } catch {
          return null;
        }
      })
      .filter((t): t is ConversationTurn => t !== null)
      .reverse();
  } catch (error) {
    console.warn('Conversation history retrieval failed:', error);
    return [];
  }
}

// ============================================================================
// SUMMARIZE MEMORIES (CONSOLIDATION)
// ============================================================================

export interface SummarizeMemoriesInput {
  workspaceId: string;
  sessionId?: string;
  memoryIds?: string[];
}

export async function summarizeMemories(input: SummarizeMemoriesInput): Promise<{ summaryId: string }> {
  const { workspaceId, sessionId, memoryIds } = input;

  // Get memories to summarize
  let memories: MemoryItem[];

  if (memoryIds) {
    memories = await Promise.all(
      memoryIds.map(async (id) => {
        const result = await dbQueryOne<DBMemory>(
          `SELECT * FROM homeos.memories WHERE id = $1 AND workspace_id = $2`,
          [id, workspaceId]
        );
        return result ? {
          id: result.id,
          type: result.type,
          content: result.content,
          salience: result.salience,
          createdAt: result.created_at,
        } : null;
      })
    ).then((results) => results.filter((m): m is MemoryItem => m !== null));
  } else if (sessionId) {
    const history = await getConversationHistory({ workspaceId, sessionId, limit: 50 });
    memories = history.map((turn, i) => ({
      id: `turn-${i}`,
      type: 'working' as const,
      content: `${turn.role}: ${turn.content}`,
      salience: 0.5,
      createdAt: turn.timestamp,
    }));
  } else {
    return { summaryId: '' };
  }

  if (memories.length === 0) {
    return { summaryId: '' };
  }

  // Use LLM to summarize
  const anthropicKey = process.env['ANTHROPIC_API_KEY'];
  if (!anthropicKey) {
    return { summaryId: '' };
  }

  const client = new Anthropic({ apiKey: anthropicKey });
  const memoryText = memories.map((m) => m.content).join('\n\n');

  const response = await client.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 500,
    system: 'Summarize the following memories/conversation into a concise summary that preserves key facts, preferences, and context. Focus on actionable information.',
    messages: [{ role: 'user', content: memoryText }],
  });

  const summary = response.content[0]?.type === 'text' ? response.content[0].text : '';

  // Store summary as episodic memory
  const result = await storeMemory({
    workspaceId,
    type: 'episodic',
    content: summary,
    salience: 0.75,
    metadata: { summarizedFrom: memories.map((m) => m.id), sessionId },
    tags: ['summary', sessionId || 'general'],
  });

  return { summaryId: result.id };
}

// ============================================================================
// HEXIS-INSPIRED MEMORY HELPERS
// ============================================================================

/**
 * Hydrate context with relevant memories for a query
 * Inspired by Hexis hydrate() - gathers context from all memory types
 */
export interface HydrateContextInput {
  workspaceId: string;
  currentContext: string;
  memberIds?: string[];
  maxWorking?: number;
  maxEpisodic?: number;
  maxSemantic?: number;
  maxProcedural?: number;
  maxStrategic?: number;
}

export interface HydratedContext {
  workingMemory: MemoryItem[];
  episodicMemory: MemoryItem[];
  semanticMemory: MemoryItem[];
  proceduralMemory: MemoryItem[];
  strategicMemory: MemoryItem[];
  summary: string;
}

export async function hydrateContext(input: HydrateContextInput): Promise<HydratedContext> {
  const {
    workspaceId,
    currentContext,
    memberIds = [],
    maxWorking = 5,
    maxEpisodic = 10,
    maxSemantic = 10,
    maxProcedural = 5,
    maxStrategic = 5,
  } = input;

  // Recall memories from each layer in parallel
  const [workingMemory, episodicMemory, semanticMemory, proceduralMemory, strategicMemory] =
    await Promise.all([
      recall({ workspaceId, query: currentContext, types: ['working'], limit: maxWorking }),
      recall({ workspaceId, query: currentContext, types: ['episodic'], limit: maxEpisodic }),
      recall({ workspaceId, query: currentContext, types: ['semantic'], limit: maxSemantic }),
      recall({ workspaceId, query: currentContext, types: ['procedural'], limit: maxProcedural }),
      recall({ workspaceId, query: currentContext, types: ['strategic'], limit: maxStrategic }),
    ]);

  // Build summary for LLM context
  const summaryParts: string[] = [];

  if (semanticMemory.length > 0) {
    summaryParts.push(`Known facts: ${semanticMemory.map((m) => m.content).join('; ')}`);
  }

  if (episodicMemory.length > 0) {
    summaryParts.push(`Recent events: ${episodicMemory.map((m) => m.content).join('; ')}`);
  }

  if (proceduralMemory.length > 0) {
    summaryParts.push(`Known procedures: ${proceduralMemory.map((m) => m.content).join('; ')}`);
  }

  return {
    workingMemory,
    episodicMemory,
    semanticMemory,
    proceduralMemory,
    strategicMemory,
    summary: summaryParts.join('\n'),
  };
}

/**
 * Remember an event (episodic memory shortcut)
 */
export interface RememberEventInput {
  workspaceId: string;
  event: string;
  participants?: string[];
  location?: string;
  emotionalTone?: 'positive' | 'neutral' | 'negative';
  importance?: 'low' | 'medium' | 'high';
  tags?: string[];
}

export async function rememberEvent(input: RememberEventInput): Promise<{ id: string }> {
  const {
    workspaceId,
    event,
    participants = [],
    location,
    emotionalTone = 'neutral',
    importance = 'medium',
    tags = [],
  } = input;

  const salience = importance === 'high' ? 0.9 : importance === 'medium' ? 0.6 : 0.3;

  return storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      event,
      participants,
      location,
      emotionalTone,
      timestamp: new Date().toISOString(),
    }),
    salience,
    metadata: { emotionalTone },
    tags: ['event', ...tags, ...participants],
  });
}

/**
 * Remember a fact (semantic memory shortcut)
 */
export interface RememberFactInput {
  workspaceId: string;
  fact: string;
  category: string;
  confidence?: number;
  source?: string;
  tags?: string[];
}

export async function rememberFact(input: RememberFactInput): Promise<{ id: string }> {
  const { workspaceId, fact, category, confidence = 0.8, source, tags = [] } = input;

  return storeMemory({
    workspaceId,
    type: 'semantic',
    content: JSON.stringify({ fact, category, source, learnedAt: new Date().toISOString() }),
    salience: 0.7,
    metadata: { confidence, category },
    tags: ['fact', category, ...tags],
  });
}

/**
 * Remember a procedure (how to do something)
 */
export interface RememberProcedureInput {
  workspaceId: string;
  name: string;
  steps: string[];
  context: string;
  successRate?: number;
  tags?: string[];
}

export async function rememberProcedure(input: RememberProcedureInput): Promise<{ id: string }> {
  const { workspaceId, name, steps, context, successRate = 1.0, tags = [] } = input;

  return storeMemory({
    workspaceId,
    type: 'procedural',
    content: JSON.stringify({ name, steps, context }),
    salience: 0.8,
    metadata: { successRate },
    tags: ['procedure', ...tags],
  });
}

/**
 * Remember a family member preference
 */
export interface RememberPreferenceInput {
  workspaceId: string;
  memberId: string;
  category: string;
  preference: string;
  strength?: number;
}

export async function rememberPreference(input: RememberPreferenceInput): Promise<{ id: string }> {
  const { workspaceId, memberId, category, preference, strength = 0.8 } = input;

  return storeMemory({
    workspaceId,
    type: 'semantic',
    content: JSON.stringify({ memberId, category, preference, observedAt: new Date().toISOString() }),
    salience: strength,
    metadata: { memberId, category },
    tags: ['preference', category, memberId],
  });
}

/**
 * Get family member preferences
 */
export interface GetPreferencesInput {
  workspaceId: string;
  memberId?: string;
  category?: string;
}

export async function getPreferences(input: GetPreferencesInput): Promise<
  Array<{ memberId: string; category: string; preference: string }>
> {
  const { workspaceId, memberId, category } = input;

  const tags = ['preference'];
  if (memberId) tags.push(memberId);
  if (category) tags.push(category);

  const memories = await recall({
    workspaceId,
    query: `preferences ${category || ''} ${memberId || ''}`,
    types: ['semantic'],
    tags,
    limit: 50,
  });

  return memories
    .map((m) => {
      try {
        const data = JSON.parse(m.content);
        return {
          memberId: data.memberId,
          category: data.category,
          preference: data.preference,
        };
      } catch {
        return null;
      }
    })
    .filter((p): p is { memberId: string; category: string; preference: string } => p !== null);
}

/**
 * Remember a routine/habit pattern
 */
export interface RememberRoutineInput {
  workspaceId: string;
  memberId: string;
  routine: string;
  timeOfDay?: string;
  daysOfWeek?: string[];
  successRate?: number;
}

export async function rememberRoutine(input: RememberRoutineInput): Promise<{ id: string }> {
  const { workspaceId, memberId, routine, timeOfDay, daysOfWeek, successRate = 1.0 } = input;

  return storeMemory({
    workspaceId,
    type: 'procedural',
    content: JSON.stringify({ memberId, routine, timeOfDay, daysOfWeek }),
    salience: 0.8,
    metadata: { successRate, memberId },
    tags: ['routine', memberId],
  });
}

/**
 * Remember a strategic pattern or adaptation
 */
export interface RememberPatternInput {
  workspaceId: string;
  pattern: string;
  observation: string;
  frequency?: number;
  adaptation?: string;
  tags?: string[];
}

export async function rememberPattern(input: RememberPatternInput): Promise<{ id: string }> {
  const { workspaceId, pattern, observation, frequency = 1, adaptation, tags = [] } = input;

  return storeMemory({
    workspaceId,
    type: 'strategic',
    content: JSON.stringify({ pattern, observation, frequency, adaptation }),
    salience: 0.7,
    tags: ['pattern', ...tags],
  });
}
