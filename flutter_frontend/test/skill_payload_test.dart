import 'package:flutter_frontend/models/skill_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SkillPayload.fromJson parses valid html_app payload', () {
    final SkillPayload payload = SkillPayload.fromJson(<String, dynamic>{
      'type': 'html_app',
      'html': '<div id="chart"></div>',
      'css': '#chart { color: red; }',
      'js': 'console.log("ok");',
      'assets': <String, dynamic>{},
      'actions': <Map<String, dynamic>>[
        <String, dynamic>{'name': 'emitEvent', 'payload': <String, dynamic>{}},
      ],
    });

    expect(payload.type, 'html_app');
    expect(payload.html, contains('chart'));
  });

  test('SkillPayload.fromJson rejects wrapper tags in html', () {
    expect(
      () => SkillPayload.fromJson(<String, dynamic>{
        'type': 'html_app',
        'html': '<body>bad</body>',
        'css': '',
        'js': '',
        'assets': <String, dynamic>{},
        'actions': <Map<String, dynamic>>[],
      }),
      throwsA(isA<SkillPayloadValidationException>()),
    );
  });
}
