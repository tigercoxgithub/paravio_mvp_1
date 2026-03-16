export interface Account {
  id: string;
  name: string;
  created_at: Date;
}

export interface Character {
  id: string;
  account_id: string;
  name: string;
  slug: string;
  system_prompt: string;
  model: string;
  created_at: Date;
}

export interface Skill {
  id: string;
  character_id: string;
  name: string;
  slug: string;
  description: string;
  instructions: string;
  created_at: Date;
}

export interface SkillTool {
  id: string;
  skill_id: string;
  name: string;
  description: string;
  parameters_schema: Record<string, unknown>;
  created_at: Date;
}

export interface SkillWithTools extends Skill {
  tools: SkillTool[];
}

export interface Conversation {
  id: string;
  account_id: string;
  character_id: string;
  user_id: string;
  created_at: Date;
}

export interface Message {
  id: string;
  conversation_id: string;
  role: "system" | "user" | "assistant" | "tool";
  content: string | null;
  tool_calls: unknown | null;
  tool_call_id: string | null;
  name: string | null;
  created_at: Date;
}

export interface ChatRequest {
  character_id: string;
  user_id: string;
  message: string;
  conversation_id?: string;
}

export interface ChatResponse {
  conversation_id: string;
  response: string;
  tool_calls_made: string[];
}

export interface Env {
  HYPERDRIVE: Hyperdrive;
  GROQ_API_KEY: string;
}
