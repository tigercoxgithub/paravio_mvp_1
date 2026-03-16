import postgres from "postgres";
import type { Character, Conversation, Env, Message, Skill, SkillTool, SkillWithTools } from "./types";

export function getDb(env: Env) {
  return postgres(env.HYPERDRIVE.connectionString, {
    prepare: false,
  });
}

export async function getCharacter(
  sql: postgres.Sql,
  characterId: string
): Promise<Character | null> {
  const rows = await sql<Character[]>`
    SELECT id, account_id, name, slug, system_prompt, model, created_at
    FROM characters
    WHERE id = ${characterId}
  `;
  return rows[0] ?? null;
}

export async function getCharactersByAccount(
  sql: postgres.Sql,
  accountId: string
): Promise<Character[]> {
  return sql<Character[]>`
    SELECT id, account_id, name, slug, system_prompt, model, created_at
    FROM characters
    WHERE account_id = ${accountId}
    ORDER BY name
  `;
}

export async function getSkillsForCharacter(
  sql: postgres.Sql,
  characterId: string
): Promise<SkillWithTools[]> {
  const skills = await sql<Skill[]>`
    SELECT id, character_id, name, slug, description, instructions, created_at
    FROM skills
    WHERE character_id = ${characterId}
    ORDER BY name
  `;

  const skillIds = skills.map((s) => s.id);
  if (skillIds.length === 0) return [];

  const tools = await sql<SkillTool[]>`
    SELECT id, skill_id, name, description, parameters_schema, created_at
    FROM skill_tools
    WHERE skill_id = ANY(${skillIds})
    ORDER BY name
  `;

  const toolsBySkill = new Map<string, SkillTool[]>();
  for (const tool of tools) {
    const existing = toolsBySkill.get(tool.skill_id) ?? [];
    existing.push(tool);
    toolsBySkill.set(tool.skill_id, existing);
  }

  return skills.map((skill) => ({
    ...skill,
    tools: toolsBySkill.get(skill.id) ?? [],
  }));
}

export async function getOrCreateConversation(
  sql: postgres.Sql,
  accountId: string,
  characterId: string,
  userId: string,
  conversationId?: string
): Promise<Conversation> {
  if (conversationId) {
    const rows = await sql<Conversation[]>`
      SELECT id, account_id, character_id, user_id, created_at
      FROM conversations
      WHERE id = ${conversationId}
    `;
    if (rows[0]) return rows[0];
  }

  const rows = await sql<Conversation[]>`
    INSERT INTO conversations (account_id, character_id, user_id)
    VALUES (${accountId}, ${characterId}, ${userId})
    RETURNING id, account_id, character_id, user_id, created_at
  `;
  return rows[0];
}

export async function getMessages(
  sql: postgres.Sql,
  conversationId: string,
  limit = 20
): Promise<Message[]> {
  return sql<Message[]>`
    SELECT id, conversation_id, role, content, tool_calls, tool_call_id, name, created_at
    FROM messages
    WHERE conversation_id = ${conversationId}
    ORDER BY created_at ASC
    LIMIT ${limit}
  `;
}

export async function getConversation(
  sql: postgres.Sql,
  conversationId: string
): Promise<{ conversation: Conversation | null; messages: Message[] }> {
  const convRows = await sql<Conversation[]>`
    SELECT id, account_id, character_id, user_id, created_at
    FROM conversations
    WHERE id = ${conversationId}
  `;
  const conversation = convRows[0] ?? null;
  if (!conversation) return { conversation: null, messages: [] };

  const messages = await getMessages(sql, conversationId, 100);
  return { conversation, messages };
}

export async function saveMessage(
  sql: postgres.Sql,
  conversationId: string,
  message: {
    role: string;
    content?: string | null;
    tool_calls?: unknown;
    tool_call_id?: string | null;
    name?: string | null;
  }
): Promise<Message> {
  const rows = await sql<Message[]>`
    INSERT INTO messages (conversation_id, role, content, tool_calls, tool_call_id, name)
    VALUES (
      ${conversationId},
      ${message.role},
      ${message.content ?? null},
      ${message.tool_calls ? sql.json(message.tool_calls as Parameters<typeof sql.json>[0]) : null},
      ${message.tool_call_id ?? null},
      ${message.name ?? null}
    )
    RETURNING id, conversation_id, role, content, tool_calls, tool_call_id, name, created_at
  `;
  return rows[0];
}
