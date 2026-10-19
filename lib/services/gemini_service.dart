import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/entry.dart';

/// Reading/meaning/example suggested by Gemini for one term.
class GeminiAutoFillResult {
  GeminiAutoFillResult({
    required this.reading,
    required this.meaningMy,
    required this.exampleSentence,
  });

  /// Only populated for [EntryType.tango]; grammar patterns have no reading.
  final String? reading;
  final String meaningMy;
  final String exampleSentence;
}

/// Calls the Gemini API directly from the app to auto-fill a new entry's
/// reading / Myanmar meaning / example sentence from just its term.
///
/// The API key lives in on-device settings (see [SettingsStore]), not in
/// source control. Calling Gemini straight from the client means the key
/// ships inside the app bundle — acceptable while this is a local prototype,
/// but it should move behind a backend proxy before any public release so
/// the key can't be extracted from the app and abused.
class GeminiService {
  GeminiService._();

  static const String _model = 'gemini-2.0-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  /// Asks Gemini to fill in the fields for [term]. Throws on any
  /// network/API/parse failure — callers should surface the error rather
  /// than silently leaving fields blank, since a wrong auto-fill is worse
  /// than none.
  static Future<GeminiAutoFillResult> autoFill({
    required String apiKey,
    required EntryType type,
    required String term,
  }) async {
    final isTango = type == EntryType.tango;
    final prompt = isTango
        ? '日本語の単語「$term」について、次のJSONだけを返してください。説明文やコードブロックの記号は付けないこと。\n'
            '{"reading": "ひらがなのよみかた", "meaningMy": "ミャンマー語での意味", '
            '"exampleSentence": "その単語を使った自然な日本語の例文"}'
        : '日本語の文法パターン「$term」について、次のJSONだけを返してください。説明文やコードブロックの記号は付けないこと。\n'
            '{"meaningMy": "ミャンマー語でのこの文法の意味・使い方", '
            '"exampleSentence": "そのパターンを使った自然な日本語の例文"}';

    final response = await http.post(
      Uri.parse('$_endpoint?key=$apiKey'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'responseMimeType': 'application/json'},
      }),
    );

    if (response.statusCode != 200) {
      throw GeminiServiceException(
        'Gemini API がエラーを返しました (${response.statusCode})。APIキーを確認してください。',
      );
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw GeminiServiceException('Gemini からの応答を解析できませんでした。');
    }

    final candidates = body['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw GeminiServiceException('Gemini から応答がありませんでした。');
    }

    String text;
    Map<String, dynamic> parsed;
    try {
      final content = (candidates.first as Map<String, dynamic>)['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      text = (parts.first as Map<String, dynamic>)['text'] as String;
      parsed = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      throw GeminiServiceException('Gemini からの応答を解析できませんでした。');
    }

    return GeminiAutoFillResult(
      reading: isTango ? parsed['reading'] as String? : null,
      meaningMy: (parsed['meaningMy'] as String?)?.trim() ?? '',
      exampleSentence: (parsed['exampleSentence'] as String?)?.trim() ?? '',
    );
  }
}

/// A user-facing error from [GeminiService] — the message is already in
/// Japanese and safe to show directly in an alert.
class GeminiServiceException implements Exception {
  GeminiServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
