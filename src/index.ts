import { handleChat } from "./chat";
import { getCharactersByAccount, getConversation, getDb } from "./db";
import type { ChatRequest, Env } from "./types";

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders(),
    },
  });
}

function errorResponse(message: string, status = 400): Response {
  return jsonResponse({ error: message }, status);
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Handle CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      // POST /api/chat
      if (path === "/api/chat" && request.method === "POST") {
        const body = (await request.json()) as ChatRequest;

        if (!body.character_id || !body.user_id || !body.message) {
          return errorResponse("Missing required fields: character_id, user_id, message");
        }

        const result = await handleChat(env, body);
        return jsonResponse(result);
      }

      // GET /api/characters/:accountId
      const charactersMatch = path.match(/^\/api\/characters\/([^/]+)$/);
      if (charactersMatch && request.method === "GET") {
        const accountId = charactersMatch[1];
        const sql = getDb(env);
        try {
          const characters = await getCharactersByAccount(sql, accountId);
          return jsonResponse({ characters });
        } finally {
          await sql.end();
        }
      }

      // GET /api/conversations/:conversationId
      const conversationsMatch = path.match(/^\/api\/conversations\/([^/]+)$/);
      if (conversationsMatch && request.method === "GET") {
        const conversationId = conversationsMatch[1];
        const sql = getDb(env);
        try {
          const result = await getConversation(sql, conversationId);
          if (!result.conversation) {
            return errorResponse("Conversation not found", 404);
          }
          return jsonResponse(result);
        } finally {
          await sql.end();
        }
      }

      // GET /api/health
      if (path === "/api/health" && request.method === "GET") {
        const sql = getDb(env);
        try {
          await sql`SELECT 1`;
          return jsonResponse({ status: "ok", timestamp: new Date().toISOString() });
        } catch {
          return jsonResponse({ status: "error", message: "Database connection failed" }, 503);
        } finally {
          await sql.end();
        }
      }

      return errorResponse("Not found", 404);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Internal server error";
      console.error("Request error:", err);
      return errorResponse(message, 500);
    }
  },
} satisfies ExportedHandler<Env>;
