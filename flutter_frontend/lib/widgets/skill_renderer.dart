import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/models/skill_payload.dart';
import 'package:flutter_frontend/rendering/skill_document_builder.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SkillActionEvent {
  SkillActionEvent({
    required this.name,
    required this.payload,
    required this.rawMessage,
  });

  final String name;
  final Map<String, dynamic>? payload;
  final String rawMessage;
}

class SkillRenderer extends StatefulWidget {
  const SkillRenderer({
    required this.payload,
    super.key,
    this.onAction,
    this.bridgeChannel = 'ParavioBridgeChannel',
  });

  final SkillPayload payload;
  final ValueChanged<SkillActionEvent>? onAction;
  final String bridgeChannel;

  @override
  State<SkillRenderer> createState() => _SkillRendererState();
}

class _SkillRendererState extends State<SkillRenderer> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final WebViewController controller = WebViewController();

    // webview_flutter_web currently does not implement all controller APIs
    // (such as setBackgroundColor / setJavaScriptMode / JavaScript channels),
    // so gate mobile-only
    // configuration to avoid runtime UnimplementedError on Flutter Web.
    if (!kIsWeb) {
      controller.setBackgroundColor(const Color(0x00000000));
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      controller.addJavaScriptChannel(
        widget.bridgeChannel,
        onMessageReceived: _handleBridgeMessage,
      );
    }

    _controller = controller;
    _loadPayload();
  }

  @override
  void didUpdateWidget(covariant SkillRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payload.toJson().toString() !=
        widget.payload.toJson().toString()) {
      _loadPayload();
    }
  }

  Future<void> _loadPayload() {
    final String doc = SkillDocumentBuilder.composeDocument(
      payload: widget.payload,
      bridgeChannel: widget.bridgeChannel,
    );
    return _controller.loadHtmlString(doc);
  }

  void _handleBridgeMessage(JavaScriptMessage message) {
    final String raw = message.message;
    try {
      final dynamic parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) {
        return;
      }
      final String name = parsed['name']?.toString() ?? 'unknown_action';
      final dynamic payloadRaw = parsed['payload'];
      final Map<String, dynamic>? payload = payloadRaw is Map<String, dynamic>
          ? payloadRaw
          : null;
      widget.onAction?.call(
        SkillActionEvent(name: name, payload: payload, rawMessage: raw),
      );
    } catch (_) {
      widget.onAction?.call(
        SkillActionEvent(
          name: 'invalid_bridge_message',
          payload: null,
          rawMessage: raw,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
