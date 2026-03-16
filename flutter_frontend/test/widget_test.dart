import 'package:flutter/material.dart';
import 'package:flutter_frontend/models/chat_response.dart';
import 'package:flutter_frontend/screens/chat_screen.dart';
import 'package:flutter_frontend/widgets/skill_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ResponseView renders text fallback for plain responses', (
    WidgetTester tester,
  ) async {
    final ChatResponse response = ChatResponse(
      conversationId: 'conv-1',
      response: 'Plain text response',
      toolCallsMade: const <String>[],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponseView(
            response: response,
            onAction: (SkillActionEvent _) {},
          ),
        ),
      ),
    );

    expect(find.text('Plain text response'), findsOneWidget);
  });
}
