import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/entry.dart';

/// Reading/meaning/example suggested by Groq for one term.
class GroqAutoFillResult {
  GroqAutoFillResult({
    required this.reading,
    required this.meaningMy,
    required this.exampleSentence,
  });

  /// Only populated for [EntryType.tango]; grammar patterns have no reading.
  final String? reading;
  final String meaningMy;
  final String exampleSentence;
}

/// Calls the Groq API (OpenAI-compatible) directly from the app to auto-fill
/// a new entry's reading / Myanmar meaning / example sentence from just its
/// term.
///
/// The API key lives in on-device settings (see [SettingsStore]), not in
/// source control. Calling Groq straight from the client means the key ships
/// inside the app bundle — acceptable while this is a local prototype, but
/// it should move behind a backend proxy before any public release so the
/// key can't be extracted from the app and abused.
class GroqService {
  GroqService._();

  static const String _model = 'openai/gpt-oss-20b';
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  /// Asks Groq to fill in the fields for [term]. Throws on any
  /// network/API/parse failure — callers should surface the error rather
  /// than silently leaving fields blank, since a wrong auto-fill is worse
  /// than none.
  static Future<GroqAutoFillResult> autoFill({
    required String apiKey,
    required EntryType type,
    required String term,
  }) async {
    final isTango = type == EntryType.tango;
    final prompt = isTango
        ? '日本語の単語「$term」について、次のJSONだけを返してください。説明文は付けないこと。\n'
            '{"reading": "ひらがなのよみかた", "meaningMy": "ミャンマー語での意味", '
            '"exampleSentence": "その単語を使った自然な日本語の例文"}'
        : '日本語の文法パターン「$term」について、次のJSONだけを返してください。説明文は付けないこと。\n'
            '{"meaningMy": "ミャンマー語でのこの文法の意味・使い方", '
            '"exampleSentence": "そのパターンを使った自然な日本語の例文"}';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw GroqServiceException(
        'Groq API がエラーを返しました (${response.statusCode})。APIキーを確認してください。',
      );
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw GroqServiceException('Groq からの応答を解析できませんでした。');
    }

    String text;
    Map<String, dynamic> parsed;
    try {
      final choices = body['choices'] as List<dynamic>;
      final message = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>;
      text = message['content'] as String;
      parsed = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      throw GroqServiceException('Groq からの応答を解析できませんでした。');
    }

    return GroqAutoFillResult(
      reading: isTango ? parsed['reading'] as String? : null,
      meaningMy: (parsed['meaningMy'] as String?)?.trim() ?? '',
      exampleSentence: (parsed['exampleSentence'] as String?)?.trim() ?? '',
    );
  }
}

/// A user-facing error from [GroqService] — the message is already in
/// Japanese and safe to show directly in an alert.
class GroqServiceException implements Exception {
  GroqServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
