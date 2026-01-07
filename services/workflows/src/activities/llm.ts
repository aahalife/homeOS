import Anthropic from '@anthropic-ai/sdk';
import OpenAI from 'openai';

/**
 * Strip markdown code blocks from LLM response text
 */
function stripMarkdownCodeBlocks(text: string): string {
  return text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
}

interface LLMConfig {
  provider: 'anthropic' | 'openai';
  apiKey: string;
  model?: string;
}

async function getLLMConfig(workspaceId: string): Promise<LLMConfig> {
  // TODO: Fetch from control plane
  // For now, use environment variables
  const anthropicKey = process.env['ANTHROPIC_API_KEY'];
  const openaiKey = process.env['OPENAI_API_KEY'];

  if (anthropicKey) {
    return { provider: 'anthropic', apiKey: anthropicKey, model: 'claude-sonnet-4-20250514' };
  }
  if (openaiKey) {
    return { provider: 'openai', apiKey: openaiKey, model: 'gpt-4o' };
  }

  throw new Error('No LLM API key configured');
}

export interface UnderstandInput {
  workspaceId: string;
  userId: string;
  message: string;
  sessionId?: string;
}

export interface UnderstandOutput {
  intent: string;
  entities: Record<string, unknown>;
  confidence: number;
  needsClarification: boolean;
  clarificationQuestions?: string[];
}

export async function understand(input: UnderstandInput): Promise<UnderstandOutput> {
  const config = await getLLMConfig(input.workspaceId);

  const systemPrompt = `You are analyzing a user message to understand their intent.
Extract:
- intent: What does the user want to accomplish?
- entities: Named entities like names, dates, locations, items
- confidence: How confident are you in this understanding (0-1)?
- needsClarification: Does this need clarification before proceeding?
- clarificationQuestions: If clarification is needed, what questions?

Respond in JSON format.`;

  if (config.provider === 'anthropic') {
    const client = new Anthropic({ apiKey: config.apiKey });
    const response = await client.messages.create({
      model: config.model ?? 'claude-sonnet-4-20250514',
      max_tokens: 1024,
      system: systemPrompt,
      messages: [{ role: 'user', content: input.message }],
    });

    const text = response.content[0]?.type === 'text' ? response.content[0].text : '';
    return JSON.parse(stripMarkdownCodeBlocks(text));
  } else {
    const client = new OpenAI({ apiKey: config.apiKey });
    const response = await client.chat.completions.create({
      model: config.model ?? 'gpt-4o',
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: input.message },
      ],
    });

    return JSON.parse(stripMarkdownCodeBlocks(response.choices[0]?.message?.content ?? '{}'));
  }
}

export interface PlanInput {
  workspaceId: string;
  userId: string;
  understanding: UnderstandOutput;
  memories: unknown[];
}

export interface PlanStep {
  intent: string;
  toolName: string;
  inputs: Record<string, unknown>;
  riskLevel: 'low' | 'medium' | 'high';
  requiresApproval: boolean;
}

export interface PlanOutput {
  steps: PlanStep[];
  reasoning: string;
}

export async function plan(input: PlanInput): Promise<PlanOutput> {
  const config = await getLLMConfig(input.workspaceId);

  const systemPrompt = `You are a planning agent. Given the user's intent and relevant memories,
create a step-by-step plan to accomplish their goal.

For each step, specify:
- intent: What this step accomplishes
- toolName: Which tool to use
- inputs: The inputs for the tool
- riskLevel: low, medium, or high
- requiresApproval: Whether user approval is needed

High-risk actions that ALWAYS require approval:
- Spending money (checkout, deposits, payments)
- External communications (calls, messages, emails)
- Public posting (marketplace listings, social media)
- Sharing PII (address, phone, personal info)
- Deleting or modifying data

Respond in JSON format with { steps: [...], reasoning: "..." }`;

  const userContent = JSON.stringify({
    understanding: input.understanding,
    memories: input.memories,
  });

  if (config.provider === 'anthropic') {
    const client = new Anthropic({ apiKey: config.apiKey });
    const response = await client.messages.create({
      model: config.model ?? 'claude-sonnet-4-20250514',
      max_tokens: 2048,
      system: systemPrompt,
      messages: [{ role: 'user', content: userContent }],
    });

    const text = response.content[0]?.type === 'text' ? response.content[0].text : '';
    return JSON.parse(stripMarkdownCodeBlocks(text));
  } else {
    const client = new OpenAI({ apiKey: config.apiKey });
    const response = await client.chat.completions.create({
      model: config.model ?? 'gpt-4o',
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userContent },
      ],
    });

    return JSON.parse(stripMarkdownCodeBlocks(response.choices[0]?.message?.content ?? '{}'));
  }
}

export interface ReflectInput {
  workspaceId: string;
  step: PlanStep;
  result: unknown;
}

export async function reflect(input: ReflectInput): Promise<{
  success: boolean;
  issues?: string[];
  shouldRetry?: boolean;
}> {
  const config = await getLLMConfig(input.workspaceId);

  const systemPrompt = `You are validating the result of a tool execution.
Check if the result matches expectations and identify any issues.

Respond in JSON: { success: boolean, issues?: string[], shouldRetry?: boolean }`;

  const userContent = JSON.stringify({
    step: input.step,
    result: input.result,
  });

  if (config.provider === 'anthropic') {
    const client = new Anthropic({ apiKey: config.apiKey });
    const response = await client.messages.create({
      model: config.model ?? 'claude-sonnet-4-20250514',
      max_tokens: 512,
      system: systemPrompt,
      messages: [{ role: 'user', content: userContent }],
    });

    const text = response.content[0]?.type === 'text' ? response.content[0].text : '';
    return JSON.parse(stripMarkdownCodeBlocks(text));
  } else {
    const client = new OpenAI({ apiKey: config.apiKey });
    const response = await client.chat.completions.create({
      model: config.model ?? 'gpt-4o',
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userContent },
      ],
    });

    return JSON.parse(stripMarkdownCodeBlocks(response.choices[0]?.message?.content ?? '{}'));
  }
}

export interface WritebackInput {
  workspaceId: string;
  userId: string;
  sessionId?: string;
  understanding: UnderstandOutput;
  executedActions: string[];
}

export async function writeback(input: WritebackInput): Promise<{ content: string }> {
  const config = await getLLMConfig(input.workspaceId);

  const systemPrompt = `You are generating a response to the user summarizing what was done.
Be concise and friendly. Use bullet points for multiple actions.`;

  const userContent = JSON.stringify({
    intent: input.understanding.intent,
    actions: input.executedActions,
  });

  if (config.provider === 'anthropic') {
    const client = new Anthropic({ apiKey: config.apiKey });
    const response = await client.messages.create({
      model: config.model ?? 'claude-sonnet-4-20250514',
      max_tokens: 1024,
      system: systemPrompt,
      messages: [{ role: 'user', content: userContent }],
    });

    const text = response.content[0]?.type === 'text' ? response.content[0].text : '';
    return { content: text };
  } else {
    const client = new OpenAI({ apiKey: config.apiKey });
    const response = await client.chat.completions.create({
      model: config.model ?? 'gpt-4o',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userContent },
      ],
    });

    return { content: response.choices[0]?.message?.content ?? '' };
  }
}
