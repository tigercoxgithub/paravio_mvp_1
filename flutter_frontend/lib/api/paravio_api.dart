import 'dart:convert';

import 'package:flutter_frontend/models/chat_response.dart';
import 'package:http/http.dart' as http;

class ParavioApiException implements Exception {
  ParavioApiException(this.message);
  final String message;

  @override
  String toString() => 'ParavioApiException: $message';
}

class ParavioApi {
  ParavioApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<ChatResponse> sendMessage({
    required String characterId,
    required String userId,
    required String message,
    String? conversationId,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/api/chat');
    final Map<String, dynamic> body = <String, dynamic>{
      'character_id': characterId,
      'user_id': userId,
      'message': message,
      if (conversationId != null && conversationId.isNotEmpty)
        'conversation_id': conversationId,
    };

    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ParavioApiException(
        'Chat request failed with status ${response.statusCode}: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ParavioApiException('API response is not a JSON object.');
    }

    return ChatResponse.fromJson(decoded);
  }
}
