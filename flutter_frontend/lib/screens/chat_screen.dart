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
    text: 'Check availability for next Tuesday at 11am.',
  );
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  final List<_UiChatMessage> _messages = <_UiChatMessage>[];
  int _messageCounter = 0;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _characterIdController.dispose();
    _userIdController.dispose();
    _conversationIdController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isLoading) {
      return;
    }

    final String userMessageId = _nextMessageId();
    final String loadingMessageId = _nextMessageId();

    setState(() {
      _isLoading = true;
      _messages.add(
        _UiChatMessage(
          id: userMessageId,
          role: _UiChatRole.user,
          text: messageText,
          createdAt: DateTime.now(),
        ),
      );
      _messages.add(
        _UiChatMessage(
          id: loadingMessageId,
          role: _UiChatRole.assistant,
          text: 'Thinking...',
          createdAt: DateTime.now(),
          isLoading: true,
        ),
      );
      _messageController.clear();
    });
    _scrollToBottom();

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
        message: messageText,
      );

      setState(() {
        _replaceMessageById(
          loadingMessageId,
          _UiChatMessage(
            id: loadingMessageId,
            role: _UiChatRole.assistant,
            text: response.response.isEmpty
                ? 'Response was empty.'
                : response.response,
            createdAt: DateTime.now(),
            toolCallsMade: response.toolCallsMade,
            visualPayload: response.visualPayload,
          ),
        );
        _conversationIdController.text = response.conversationId;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _replaceMessageById(
          loadingMessageId,
          _UiChatMessage(
            id: loadingMessageId,
            role: _UiChatRole.assistant,
            text: error.toString(),
            createdAt: DateTime.now(),
            isError: true,
          ),
        );
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Paravio Chat (Web)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            _buildConnectionPanel(theme),
            const SizedBox(height: 12),
            _buildComposer(),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              children: <Widget>[
                Text('Conversation', style: theme.textTheme.titleMedium),
                if (_conversationIdController.text.isNotEmpty)
                  Text(
                    'ID: ${_conversationIdController.text}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _messages.isEmpty
                    ? const Center(
                        child: Text('Send a message to start chatting.'),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (BuildContext context, int index) {
                          final _UiChatMessage message = _messages[index];
                          return Align(
                            alignment: message.role == _UiChatRole.user
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * 0.75,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: _ChatBubble(
                                  message: message,
                                  onAction: _handleSkillAction,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionPanel(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
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
      ),
    );
  }

  Widget _buildComposer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _messageController,
            minLines: 1,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _send(),
          ),
        ),
        const SizedBox(width: 12),
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
      ],
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

  String _nextMessageId() {
    _messageCounter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}-$_messageCounter';
  }

  void _replaceMessageById(String id, _UiChatMessage replacement) {
    final int index = _messages.indexWhere(
      (_UiChatMessage msg) => msg.id == id,
    );
    if (index < 0) {
      _messages.add(replacement);
      return;
    }
    _messages[index] = replacement;
  }

  void _handleSkillAction(String messageId, SkillActionEvent event) {
    setState(() {
      final int index = _messages.indexWhere(
        (_UiChatMessage msg) => msg.id == messageId,
      );
      if (index < 0) {
        return;
      }
      _messages[index] = _messages[index].copyWith(
        lastBridgeEvent:
            '${event.name} ${event.payload ?? <String, dynamic>{}}',
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }
}

enum _UiChatRole { user, assistant }

class _UiChatMessage {
  const _UiChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.toolCallsMade = const <String>[],
    this.visualPayload,
    this.lastBridgeEvent,
    this.isError = false,
    this.isLoading = false,
  });

  final String id;
  final _UiChatRole role;
  final String text;
  final DateTime createdAt;
  final List<String> toolCallsMade;
  final SkillPayload? visualPayload;
  final String? lastBridgeEvent;
  final bool isError;
  final bool isLoading;

  _UiChatMessage copyWith({String? lastBridgeEvent}) {
    return _UiChatMessage(
      id: id,
      role: role,
      text: text,
      createdAt: createdAt,
      toolCallsMade: toolCallsMade,
      visualPayload: visualPayload,
      lastBridgeEvent: lastBridgeEvent ?? this.lastBridgeEvent,
      isError: isError,
      isLoading: isLoading,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.onAction});

  final _UiChatMessage message;
  final void Function(String messageId, SkillActionEvent event) onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isUser = message.role == _UiChatRole.user;
    final Color bubbleColor = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceVariant;
    final Color textColor = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final TimeOfDay time = TimeOfDay.fromDateTime(message.createdAt);
    final String timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isUser ? 'You' : 'Assistant',
              style: theme.textTheme.labelMedium?.copyWith(
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 6),
            if (message.isLoading)
              const Row(
                children: <Widget>[
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Thinking...'),
                ],
              )
            else ...<Widget>[
              SelectableText(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
              if (message.toolCallsMade.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  'Tools used',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: message.toolCallsMade
                      .map(
                        (String tool) => Chip(
                          label: Text(tool),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
              if (message.visualPayload != null) ...<Widget>[
                const SizedBox(height: 10),
                SizedBox(
                  height: 280,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: SkillRenderer(
                        payload: message.visualPayload!,
                        onAction: (SkillActionEvent event) =>
                            onAction(message.id, event),
                      ),
                    ),
                  ),
                ),
              ],
              if (message.lastBridgeEvent != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Bridge: ${message.lastBridgeEvent}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
              if (message.isError) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Request failed',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 8),
            Text(
              timeLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
