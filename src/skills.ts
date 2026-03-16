import type { ChatCompletionTool } from "openai/resources/chat/completions";
import type { SkillWithTools } from "./types";

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
${skillInstructions}`;
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
