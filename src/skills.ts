import type { ChatCompletionTool } from "openai/resources/chat/completions";
import type { SkillWithTools } from "./types";

const VISUAL_OUTPUT_RULES = `Visual Output Contract:
When a skill needs to produce a UI, return ONLY a single JSON object with this exact shape:
{
  "type": "html_app",
  "html": "<body content only, no html/head/body tags>",
  "css": "plain CSS string",
  "js": "plain JavaScript string",
  "assets": {},
  "actions": []
}

Rules:
- Do not include any prose before or after the JSON object.
- Do not include <html>, <head>, or <body> wrapper tags in "html".
- Do not reference external CDN URLs unless they are declared in "assets".`;

export function buildSystemPrompt(
  characterPrompt: string,
  skills: SkillWithTools[]
): string {
  if (skills.length === 0) return characterPrompt;

  const skillDescriptions = skills
    .map((s) => `- **${s.name}** (/${s.slug}): ${s.description}`)
    .join("\n");

  const skillInstructions = skills
    .map((s) => `### ${s.name}\n${s.instructions}`)
    .join("\n\n");

  return `${characterPrompt}

Available Skills:
${skillDescriptions}

Skill Instructions:
${skillInstructions}

${VISUAL_OUTPUT_RULES}`;
}

export function buildToolDefinitions(
  skills: SkillWithTools[]
): ChatCompletionTool[] {
  const tools: ChatCompletionTool[] = [];

  for (const skill of skills) {
    for (const tool of skill.tools) {
      tools.push({
        type: "function",
        function: {
          name: tool.name,
          description: tool.description,
          parameters: tool.parameters_schema as Record<string, unknown>,
        },
      });
    }
  }

  return tools;
}
