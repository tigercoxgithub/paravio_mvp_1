class SkillPayloadValidationException implements Exception {
  SkillPayloadValidationException(this.message);

  final String message;

  @override
  String toString() => 'SkillPayloadValidationException: $message';
}

class SkillPayload {
  SkillPayload({
    required this.type,
    required this.html,
    required this.css,
    required this.js,
    required this.assets,
    required this.actions,
  });

  final String type;
  final String html;
  final String css;
  final String js;
  final Map<String, dynamic> assets;
  final List<Map<String, dynamic>> actions;

  static final RegExp _forbiddenWrapperTags = RegExp(
    r'<\s*\/?\s*(html|head|body)\b',
    caseSensitive: false,
  );

  factory SkillPayload.fromJson(Map<String, dynamic> json) {
    final dynamic type = json['type'];
    final dynamic html = json['html'];
    final dynamic css = json['css'];
    final dynamic js = json['js'];
    final dynamic assets = json['assets'];
    final dynamic actions = json['actions'];

    if (type != 'html_app') {
      throw SkillPayloadValidationException(
        'Expected "type" to be "html_app".',
      );
    }
    if (html is! String || css is! String || js is! String) {
      throw SkillPayloadValidationException(
        '"html", "css", and "js" must all be strings.',
      );
    }
    if (_forbiddenWrapperTags.hasMatch(html)) {
      throw SkillPayloadValidationException(
        '"html" must not include <html>, <head>, or <body> tags.',
      );
    }
    if (assets is! Map<String, dynamic>) {
      throw SkillPayloadValidationException('"assets" must be an object.');
    }
    if (actions is! List) {
      throw SkillPayloadValidationException('"actions" must be an array.');
    }
    if (actions.any((dynamic item) => item is! Map<String, dynamic>)) {
      throw SkillPayloadValidationException(
        'Every action in "actions" must be an object.',
      );
    }

    return SkillPayload(
      type: type,
      html: html,
      css: css,
      js: js,
      assets: assets,
      actions: List<Map<String, dynamic>>.from(actions),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    'html': html,
    'css': css,
    'js': js,
    'assets': assets,
    'actions': actions,
  };
}
