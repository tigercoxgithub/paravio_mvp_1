import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/chat_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChatScreen shows initial empty conversation state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: ChatScreen()));

    expect(find.text('Paravio Chat (Web)'), findsOneWidget);
    expect(find.text('Send a message to start chatting.'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });
}
