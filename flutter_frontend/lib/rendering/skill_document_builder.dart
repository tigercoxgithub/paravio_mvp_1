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
      (function () {
        if (typeof window.Chart !== "undefined") return;

        function BasicChart(ctx, config) {
          this.ctx = ctx;
          this.config = config || {};
          this.data = this.config.data || { labels: [], datasets: [] };
          this.options = this.config.options || {};
          this.canvas = ctx && ctx.canvas ? ctx.canvas : null;
          this._bars = [];
          this._initCanvasSize();
          this._draw();
          this._bindClick();
        }

        BasicChart.prototype._initCanvasSize = function () {
          if (!this.canvas) return;
          if (!this.canvas.width || this.canvas.width < 10) {
            this.canvas.width = this.canvas.clientWidth > 0 ? this.canvas.clientWidth : 640;
          }
          if (!this.canvas.height || this.canvas.height < 10) {
            this.canvas.height = this.canvas.clientHeight > 0 ? this.canvas.clientHeight : 320;
          }
        };

        BasicChart.prototype._draw = function () {
          if (!this.ctx || !this.canvas) return;

          const labels = Array.isArray(this.data.labels) ? this.data.labels : [];
          const dataset = Array.isArray(this.data.datasets) && this.data.datasets.length > 0
            ? this.data.datasets[0]
            : { data: [] };
          const values = Array.isArray(dataset.data) ? dataset.data : [];

          const w = this.canvas.width;
          const h = this.canvas.height;
          const pad = 28;
          const topPad = 20;
          const bottomPad = 36;
          const innerW = Math.max(1, w - pad * 2);
          const innerH = Math.max(1, h - topPad - bottomPad);
          const max = Math.max(1, ...values.map((v) => Number(v) || 0));
          const count = Math.max(1, values.length);
          const slot = innerW / count;
          const barW = Math.max(10, slot * 0.66);

          this.ctx.clearRect(0, 0, w, h);
          this.ctx.fillStyle = "#101a2d";
          this.ctx.fillRect(0, 0, w, h);

          this.ctx.strokeStyle = "#304463";
          this.ctx.beginPath();
          this.ctx.moveTo(pad, h - bottomPad);
          this.ctx.lineTo(w - pad, h - bottomPad);
          this.ctx.stroke();

          this.ctx.font = "12px sans-serif";
          this.ctx.textAlign = "center";
          this._bars = [];

          for (let i = 0; i < count; i++) {
            const value = Number(values[i]) || 0;
            const xCenter = pad + slot * i + slot / 2;
            const height = (value / max) * innerH;
            const x = xCenter - barW / 2;
            const y = h - bottomPad - height;

            this.ctx.fillStyle = "#4e71ff";
            this.ctx.fillRect(x, y, barW, height);

            this.ctx.fillStyle = "#9eb1da";
            this.ctx.fillText(String(labels[i] ?? ""), xCenter, h - 14);
            this.ctx.fillStyle = "#e9eefb";
            this.ctx.fillText(String(value), xCenter, Math.max(12, y - 6));

            this._bars.push({ index: i, x: x, y: y, width: barW, height: height });
          }
        };

        BasicChart.prototype._bindClick = function () {
          if (!this.canvas) return;
          this.canvas.addEventListener("click", (evt) => {
            const rect = this.canvas.getBoundingClientRect();
            const x = evt.clientX - rect.left;
            const y = evt.clientY - rect.top;
            let hitIndex = -1;
            for (const bar of this._bars) {
              const withinX = x >= bar.x && x <= bar.x + bar.width;
              const withinY = y >= bar.y && y <= bar.y + bar.height;
              if (withinX && withinY) {
                hitIndex = bar.index;
                break;
              }
            }
            if (hitIndex >= 0 && this.options && typeof this.options.onClick === "function") {
              this.options.onClick(evt, [{ index: hitIndex }]);
            }
          });
        };

        window.Chart = function (ctx, config) {
          return new BasicChart(ctx, config);
        };
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
