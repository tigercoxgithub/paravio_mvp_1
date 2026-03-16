import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/chat_screen.dart';

void main() {
  runApp(const ParavioApp());
}

class ParavioApp extends StatelessWidget {
  const ParavioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paravio Visual Renderer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4E71FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
