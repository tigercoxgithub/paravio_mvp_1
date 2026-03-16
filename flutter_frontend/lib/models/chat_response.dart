import 'package:flutter_frontend/models/skill_payload.dart';

class ChatResponse {
  ChatResponse({
    required this.conversationId,
    required this.response,
    required this.toolCallsMade,
    this.visualPayload,
  });

  final String conversationId;
  final String response;
  final List<String> toolCallsMade;
  final SkillPayload? visualPayload;

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final dynamic toolCallsRaw = json['tool_calls_made'];
    final dynamic visualPayloadRaw = json['visual_payload'];

    SkillPayload? visualPayload;
    if (visualPayloadRaw is Map<String, dynamic>) {
      try {
        visualPayload = SkillPayload.fromJson(visualPayloadRaw);
      } on SkillPayloadValidationException {
        visualPayload = null;
      }
    }

    return ChatResponse(
      conversationId: json['conversation_id'] as String? ?? '',
      response: json['response'] as String? ?? '',
      toolCallsMade: toolCallsRaw is List
          ? toolCallsRaw.map((dynamic call) => call.toString()).toList()
          : <String>[],
      visualPayload: visualPayload,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'conversation_id': conversationId,
    'response': response,
    'tool_calls_made': toolCallsMade,
    'visual_payload': visualPayload?.toJson(),
  };
}
