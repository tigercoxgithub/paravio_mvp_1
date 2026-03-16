import 'package:flutter/material.dart';
import 'package:flutter_frontend/api/paravio_api.dart';
import 'package:flutter_frontend/models/chat_response.dart';
import 'package:flutter_frontend/models/skill_payload.dart';
import 'package:flutter_frontend/widgets/skill_renderer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _characterIdController = TextEditingController(
    text: 'c0000000-0000-0000-0000-000000000001',
  );
  final TextEditingController _userIdController = TextEditingController(
    text: 'user-web-demo',
  );
  final TextEditingController _conversationIdController =
      TextEditingController();
  final TextEditingController _messageController = TextEditingController(
    text: 'Show me weekly lesson demand as a bar chart.',
  );

  bool _isLoading = false;
  String? _error;
  ChatResponse? _lastResponse;
  String _lastBridgeEvent = 'No action events yet';

  @override
  void dispose() {
    _baseUrlController.dispose();
    _characterIdController.dispose();
    _userIdController.dispose();
    _conversationIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ParavioApi api = ParavioApi(
        baseUrl: _baseUrlController.text.trim(),
      );
      final ChatResponse response = await api.sendMessage(
        characterId: _characterIdController.text.trim(),
        userId: _userIdController.text.trim(),
        conversationId: _conversationIdController.text.trim().isEmpty
            ? null
            : _conversationIdController.text.trim(),
        message: _messageController.text.trim(),
      );

      setState(() {
        _lastResponse = response;
        _conversationIdController.text = response.conversationId;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Paravio Skill Renderer (Web)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              runSpacing: 12,
              spacing: 12,
              children: <Widget>[
                _inputField(
                  _baseUrlController,
                  'API Base URL (optional)',
                  width: 320,
                ),
                _inputField(_characterIdController, 'Character ID', width: 360),
                _inputField(_userIdController, 'User ID', width: 220),
                _inputField(
                  _conversationIdController,
                  'Conversation ID',
                  width: 360,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isLoading ? null : _send,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Send'),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Bridge: $_lastBridgeEvent',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ResponseView(
                    response: _lastResponse,
                    onAction: (SkillActionEvent event) {
                      setState(() {
                        _lastBridgeEvent =
                            '${event.name} ${event.payload ?? <String, dynamic>{}}';
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String label, {
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: label.startsWith('API Base URL')
              ? 'Leave blank to use same-origin /api'
              : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class ResponseView extends StatelessWidget {
  const ResponseView({
    required this.response,
    required this.onAction,
    super.key,
  });

  final ChatResponse? response;
  final ValueChanged<SkillActionEvent> onAction;

  @override
  Widget build(BuildContext context) {
    if (response == null) {
      return const Center(child: Text('No response yet.'));
    }

    final SkillPayload? visualPayload = response!.visualPayload;
    if (visualPayload != null) {
      return SkillRenderer(payload: visualPayload, onAction: onAction);
    }

    return SingleChildScrollView(
      child: SelectableText(
        response!.response.isEmpty ? 'Response was empty.' : response!.response,
      ),
    );
  }
}
