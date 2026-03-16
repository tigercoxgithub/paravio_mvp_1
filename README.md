# Paravio MVP 1

A minimal viable AI chat agent built on Cloudflare Workers. No LangChain, no LiteLLM — just a single Worker that dynamically loads skills and tools from PostgreSQL and runs a tool-calling loop against Groq's LLM API.

## Architecture

```
User (HTTP) → Cloudflare Worker (Chat API)
                    ↕
              Hyperdrive → PostgreSQL
                    ↕
              Groq API (LLM inference)
```

**How it works:**

1. A user sends a message to a **Character** (e.g., @flysussex — a flying school assistant)
2. The Worker loads the Character's **Skills** and **Tools** from PostgreSQL
3. A system prompt is assembled from the Character config + Skill instructions
4. The Worker calls Groq's API with the message history and available tools
5. If the LLM requests tool calls, they're executed (mock implementations for MVP) and the results are fed back in a loop (max 10 iterations)
6. The final response is returned and all messages are persisted to PostgreSQL

### Paravio Hierarchy

```
Account (tenant) → Characters (×N) → Skills (×N each) → Tools (×N per skill)
```

Example: Account "FlySussex" → Character @flysussex → Skill "Book Me In" → Tools: check_availability, book_appointment, cancel_booking

## Prerequisites

- [Node.js](https://nodejs.org/) v18+
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/) v3+
- A Cloudflare account
- A [Groq API key](https://console.groq.com/)
- A PostgreSQL database accessible from the internet (e.g., Neon, Supabase, or any cloud-hosted Postgres)

## Setup

### 1. Install dependencies

```bash
git clone https://github.com/tigercoxgithub/paravio_mvp_1.git
cd paravio_mvp_1
npm install
```

### 2. Set up PostgreSQL

Run the schema and seed data against your PostgreSQL database:

```bash
psql -h your-host -U your-user -d your-db -f schema.sql
psql -h your-host -U your-user -d your-db -f seed.sql
```

### 3. Create Hyperdrive

Create a Cloudflare Hyperdrive configuration pointing to your Postgres instance:

```bash
wrangler hyperdrive create paravio-db \
  --connection-string="postgres://user:password@host:5432/paravio"
```

Copy the returned Hyperdrive ID and update `wrangler.jsonc`:

```jsonc
"hyperdrive": [
  {
    "binding": "HYPERDRIVE",
    "id": "YOUR_ACTUAL_HYPERDRIVE_ID"
  }
]
```

### 4. Set secrets

```bash
wrangler secret put GROQ_API_KEY
# Paste your Groq API key when prompted
```

### 5. Local development

```bash
wrangler dev
```

### 6. Deploy

```bash
wrangler deploy
```

## Serve Flutter Web via Cloudflare Worker

This repository can serve both the API and Flutter web app from the same Worker.

### 1. Build Flutter web assets

```bash
npm run build:web
```

This generates static files at `flutter_frontend/build/web`.

### 2. Deploy Worker + assets

```bash
npm run deploy:web
```

### 3. Route behavior

- `/api/*` is handled by the Worker API logic.
- Non-API routes are served from Worker static assets (`flutter_frontend/build/web`).
- SPA fallback is enabled, so routes like `/chat` resolve to `index.html`.

### 4. Verify deployment

```bash
curl https://YOUR_WORKER_DOMAIN/api/health
curl -X POST https://YOUR_WORKER_DOMAIN/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "character_id": "c0000000-0000-0000-0000-000000000001",
    "user_id": "user-123",
    "message": "hello"
  }'
```

Then open `https://YOUR_WORKER_DOMAIN/` in a browser and confirm:
- the Flutter app loads,
- deep links (for example `/chat`) load the app shell,
- frontend calls to `/api/*` succeed.

## API Usage

### Send a message

```bash
curl -X POST http://localhost:8787/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "character_id": "c0000000-0000-0000-0000-000000000001",
    "user_id": "user-123",
    "message": "Hi! Can I book a flying lesson for next Tuesday?"
  }'
```

**Response:**

```json
{
  "conversation_id": "...",
  "response": "Hello! I'd love to help you book a flying lesson...",
  "tool_calls_made": ["check_availability"]
}
```

### Continue a conversation

```bash
curl -X POST http://localhost:8787/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "character_id": "c0000000-0000-0000-0000-000000000001",
    "user_id": "user-123",
    "conversation_id": "CONVERSATION_ID_FROM_ABOVE",
    "message": "The 11am slot with Sarah sounds great!"
  }'
```

### List characters for an account

```bash
curl http://localhost:8787/api/characters/a0000000-0000-0000-0000-000000000001
```

### Get conversation history

```bash
curl http://localhost:8787/api/conversations/CONVERSATION_ID
```

### Health check

```bash
curl http://localhost:8787/api/health
```

## How It Works

### Dynamic Skill Loading

Skills and tools are stored in PostgreSQL and loaded per-request based on the Character. This means:

- Adding a new skill is just an `INSERT` into the `skills` and `skill_tools` tables
- No code changes or redeployments needed to add capabilities
- Each Character can have a different set of skills

### Tool-Calling Loop

The Worker implements a standard tool-calling loop:

1. Send conversation history + available tools to the LLM
2. If the LLM returns tool calls, execute them and append results
3. Send the updated history back to the LLM
4. Repeat until the LLM responds with text (or max 10 iterations)

### Conversation Persistence

All messages (user, assistant, tool calls, tool results) are persisted to PostgreSQL. Pass a `conversation_id` to continue an existing conversation.

## Extending

### Add a new Character

```sql
INSERT INTO characters (account_id, name, slug, system_prompt)
VALUES ('a0000000-0000-0000-0000-000000000001', 'New Bot', 'new_bot', 'You are a helpful bot...');
```

### Add a new Skill

```sql
INSERT INTO skills (character_id, name, slug, description, instructions)
VALUES ('CHARACTER_ID', 'My Skill', 'my_skill', 'Does something useful', 'Instructions for the LLM...');
```

### Add a new Tool

```sql
INSERT INTO skill_tools (skill_id, name, description, parameters_schema)
VALUES ('SKILL_ID', 'my_tool', 'Does a specific thing', '{"type":"object","properties":{"param1":{"type":"string"}},"required":["param1"]}');
```

Then implement the tool in `src/tool-executor.ts` (or replace with real API calls).

## Environment Variables

| Variable | Type | Description |
|---|---|---|
| `HYPERDRIVE` | Binding | Cloudflare Hyperdrive binding to PostgreSQL |
| `GROQ_API_KEY` | Secret | Groq API key (set via `wrangler secret put`) |

## Tech Stack

| Component | Technology |
|---|---|
| Runtime | Cloudflare Workers (TypeScript) |
| Database | PostgreSQL via Cloudflare Hyperdrive |
| DB Driver | `postgres` (Postgres.js) |
| LLM | Groq API (OpenAI-compatible) |
| LLM Client | `openai` npm package |
