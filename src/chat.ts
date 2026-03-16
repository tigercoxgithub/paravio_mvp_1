import OpenAI from "openai";
import type { ChatCompletionMessageParam } from "openai/resources/chat/completions";
import { getCharacter, getDb, getMessages, getOrCreateConversation, getSkillsForCharacter, saveMessage } from "./db";
import { buildSystemPrompt, buildToolDefinitions } from "./skills";
import { executeTool } from "./tool-executor";
import type { ChatRequest, ChatResponse, Env, SkillPayload } from "./types";

const MAX_TOOL_ITERATIONS = 10;
const FORBIDDEN_WRAPPER_TAGS = /<\s*\/?\s*(html|head|body)\b/i;

function toSkillPayload(rawContent: string): SkillPayload | null {
  try {
    const parsed = JSON.parse(rawContent) as Record<string, unknown>;
    const { type, html, css, js, assets, actions } = parsed;

    if (
      type !== "html_app" ||
      typeof html !== "string" ||
      typeof css !== "string" ||
      typeof js !== "string" ||
      !assets ||
      typeof assets !== "object" ||
      Array.isArray(assets) ||
      !Array.isArray(actions)
    ) {
      return null;
    }

    if (FORBIDDEN_WRAPPER_TAGS.test(html)) {
      return null;
    }

    if (!actions.every((action) => action && typeof action === "object" && !Array.isArray(action))) {
      return null;
    }

    return {
      type: "html_app",
      html,
      css,
      js,
      assets: assets as Record<string, unknown>,
      actions: actions as Array<Record<string, unknown>>,
    };
  } catch {
    return null;
  }
}

export async function handleChat(
  env: Env,
  body: ChatRequest
): Promise<ChatResponse> {
  const sql = getDb(env);

  try {
    // 1. Load character
    const character = await getCharacter(sql, body.character_id);
    if (!character) {
      throw new Error(`Character not found: ${body.character_id}`);
    }

    // 2. Load skills and tools for this character
    const skills = await getSkillsForCharacter(sql, character.id);

    // 3. Build system prompt and tool definitions
    const systemPrompt = buildSystemPrompt(character.system_prompt, skills);
    const toolDefs = buildToolDefinitions(skills);

    // 4. Get or create conversation
    const conversation = await getOrCreateConversation(
      sql,
      character.account_id,
      character.id,
      body.user_id,
      body.conversation_id
    );

    // 5. Load recent message history
    const history = await getMessages(sql, conversation.id, 20);

    // 6. Build messages array for LLM
    const messages: ChatCompletionMessageParam[] = [
      { role: "system", content: systemPrompt },
    ];

    for (const msg of history) {
      if (msg.role === "assistant" && msg.tool_calls) {
        messages.push({
          role: "assistant",
          content: msg.content ?? "",
          tool_calls: msg.tool_calls as OpenAI.Chat.Completions.ChatCompletionMessageToolCall[],
        });
      } else if (msg.role === "tool") {
        messages.push({
          role: "tool",
          content: msg.content ?? "",
          tool_call_id: msg.tool_call_id ?? "",
        });
      } else if (msg.role === "user" || msg.role === "assistant") {
        messages.push({
          role: msg.role,
          content: msg.content ?? "",
        });
      }
    }

    // Add the new user message
    messages.push({ role: "user", content: body.message });

    // Save user message to DB
    await saveMessage(sql, conversation.id, {
      role: "user",
      content: body.message,
    });

    // 7. Initialize Groq client (OpenAI-compatible)
    const groq = new OpenAI({
      apiKey: env.GROQ_API_KEY,
      baseURL: "https://api.groq.com/openai/v1",
    });

    // 8. Tool-calling loop
    const toolCallsMade: string[] = [];
    let iterations = 0;

    while (iterations < MAX_TOOL_ITERATIONS) {
      iterations++;

      const completion = await groq.chat.completions.create({
        model: character.model,
        messages,
        tools: toolDefs.length > 0 ? toolDefs : undefined,
        temperature: 0.3,
      });

      const choice = completion.choices[0];
      if (!choice) {
        throw new Error("No response from LLM");
      }

      const assistantMessage = choice.message;

      // If no tool calls, we're done
      if (!assistantMessage.tool_calls || assistantMessage.tool_calls.length === 0) {
        const responseText = assistantMessage.content ?? "";
        const visualPayload = toSkillPayload(responseText);

        // Save final assistant message
        await saveMessage(sql, conversation.id, {
          role: "assistant",
          content: responseText,
        });

        return {
          conversation_id: conversation.id,
          response: responseText,
          tool_calls_made: toolCallsMade,
          visual_payload: visualPayload ?? undefined,
        };
      }

      // Process tool calls
      // Save assistant message with tool calls
      await saveMessage(sql, conversation.id, {
        role: "assistant",
        content: assistantMessage.content,
        tool_calls: assistantMessage.tool_calls,
      });

      messages.push({
        role: "assistant",
        content: assistantMessage.content ?? "",
        tool_calls: assistantMessage.tool_calls,
      });

      // Execute each tool call
      for (const toolCall of assistantMessage.tool_calls) {
        const toolName = toolCall.function.name;
        let toolArgs: Record<string, unknown> = {};

        try {
          toolArgs = JSON.parse(toolCall.function.arguments);
        } catch {
          // If args fail to parse, pass empty object
        }

        toolCallsMade.push(toolName);
        const result = executeTool(toolName, toolArgs);

        // Save tool result to DB
        await saveMessage(sql, conversation.id, {
          role: "tool",
          content: result,
          tool_call_id: toolCall.id,
          name: toolName,
        });

        messages.push({
          role: "tool",
          content: result,
          tool_call_id: toolCall.id,
        });
      }
    }

    // If we exhausted iterations, return the last response
    const lastAssistant = messages
      .filter((m) => m.role === "assistant")
      .pop();

    const fallbackResponse =
      (lastAssistant && "content" in lastAssistant && typeof lastAssistant.content === "string"
        ? lastAssistant.content
        : null) ?? "I apologize, but I was unable to complete your request. Please try again.";

    await saveMessage(sql, conversation.id, {
      role: "assistant",
      content: fallbackResponse,
    });

    return {
      conversation_id: conversation.id,
      response: fallbackResponse,
      tool_calls_made: toolCallsMade,
      visual_payload: undefined,
    };
  } finally {
    await sql.end();
  }
}
