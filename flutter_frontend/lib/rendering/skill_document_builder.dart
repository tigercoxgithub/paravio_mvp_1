import 'dart:convert';

import 'package:flutter_frontend/models/skill_payload.dart';

class SkillDocumentBuilder {
  static String composeDocument({
    required SkillPayload payload,
    required String bridgeChannel,
  }) {
    final String html = _sanitizeHtml(payload.html);
    final String css = _sanitizeCss(payload.css);
    final String js = _sanitizeJs(payload.js);
    final String actionsJson = jsonEncode(payload.actions);

    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
      :root {
        --pv-bg: #0b1220;
        --pv-surface: #111b2f;
        --pv-text: #e9eefb;
        --pv-muted: #9eb1da;
        --pv-accent: #4e71ff;
        --pv-font: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      }
      html, body {
        margin: 0;
        padding: 0;
        background: var(--pv-bg);
        color: var(--pv-text);
        font-family: var(--pv-font);
      }
      #pv-root {
        min-height: 100vh;
        padding: 16px;
        box-sizing: border-box;
      }
      $css
    </style>
  </head>
  <body>
    <div id="pv-root">$html</div>
    <script>
      (function () {
        const declaredActions = $actionsJson;
        const bridgeName = ${jsonEncode(bridgeChannel)};
        function postAction(name, payload) {
          if (!Array.isArray(declaredActions)) return;
          const exists = declaredActions.some((item) => item && item.name === name);
          if (!exists) return;
          const bridge = window[bridgeName];
          if (!bridge || typeof bridge.postMessage !== "function") return;
          bridge.postMessage(JSON.stringify({ name, payload: payload ?? null }));
        }
        window.ParavioBridge = { postAction };
      })();
    </script>
    <script>
      $js
    </script>
  </body>
</html>
''';
  }

  static String _sanitizeHtml(String input) {
    return input
        .replaceAll(RegExp(r'<\s*script\b[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<\s*/\s*script\s*>', caseSensitive: false), '');
  }

  static String _sanitizeCss(String input) {
    return input.replaceAll('</style', '<\\/style');
  }

  static String _sanitizeJs(String input) {
    return input.replaceAll('</script', '<\\/script');
  }
}
