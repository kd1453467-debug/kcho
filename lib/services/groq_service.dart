import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/entry.dart';
import '../models/reading_passage.dart';

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

/// An AI-generated JLPT reading passage with its comprehension questions.
class GroqReadingResult {
  GroqReadingResult({required this.passage, required this.questions});

  final String passage;
  final List<ReadingQuestion> questions;
}

/// Calls the Groq API (OpenAI-compatible) directly from the app for the AI
/// features: auto-filling a new entry's fields, and generating JLPT reading
/// passages.
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
    const multiSenseInstruction =
        '複数の意味・用法がある場合は、主なものを全て含め、それぞれの意味の前にどんな場面で'
        '使うかが一目でわかる短い日本語の文脈を（）で付けて'
        '「１）（電話で）ミャンマー語訳　２）（服を）ミャンマー語訳」のように番号を付けて区切ること。'
        '日本語の単語や例文は繰り返さず、文脈タグとミャンマー語訳だけを書くこと。'
        '意味が1つしかない場合は番号も文脈もつけずミャンマー語訳だけを書くこと。';
    final prompt = isTango
        ? '日本語の単語「$term」について、次のJSONだけを返してください。説明文は付けないこと。\n'
            '{"reading": "ひらがなのよみかた", "meaningMy": "ミャンマー語での意味（$multiSenseInstruction）", '
            '"exampleSentence": "その単語を使った自然な日本語の例文"}'
        : '日本語の文法パターン「$term」について、次のJSONだけを返してください。説明文は付けないこと。\n'
            '{"meaningMy": "ミャンマー語でのこの文法の意味・使い方（$multiSenseInstruction）", '
            '"exampleSentence": "そのパターンを使った自然な日本語の例文"}';

    final content = await _complete(apiKey: apiKey, prompt: prompt);
    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw GroqServiceException('Groq からの応答を解析できませんでした。');
    }

    return GroqAutoFillResult(
      reading: isTango ? parsed['reading'] as String? : null,
      meaningMy: (parsed['meaningMy'] as String?)?.trim() ?? '',
      exampleSentence: (parsed['exampleSentence'] as String?)?.trim() ?? '',
    );
  }

  /// Generates one JLPT [level] (e.g. "N5") reading passage with multiple
  /// comprehension questions. Uses a lower reasoning effort than [autoFill]
  /// since a passage + questions is a much larger response — this keeps
  /// token usage low enough to stay comfortably inside Groq's free-tier
  /// per-minute limit.
  static Future<GroqReadingResult> generateReadingPassage({
    required String apiKey,
    required String level,
  }) async {
    final prompt = 'JLPT $levelレベルの読解問題を1つ作成してください。'
        '日本語の文章は100〜200字程度で、$levelの学習者が読める語彙・文法だけを使うこと。'
        '文章の内容について理解を確認する設問を3つ作り、各設問に4つの選択肢と、'
        '正解のインデックス（0始まり）を付けること。'
        '次のJSON形式だけを返してください。説明文は付けないこと。\n'
        '{"passage": "日本語の文章", "questions": ['
        '{"question": "設問文", "options": ["選択肢1","選択肢2","選択肢3","選択肢4"], "correctIndex": 0}'
        ']}';

    final content = await _complete(apiKey: apiKey, prompt: prompt, reasoningEffort: 'low');
    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw GroqServiceException('Groq からの応答を解析できませんでした。');
    }

    try {
      final passage = parsed['passage'] as String;
      final questions = (parsed['questions'] as List<dynamic>)
          .map((e) => ReadingQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
      return GroqReadingResult(passage: passage, questions: questions);
    } catch (_) {
      throw GroqServiceException('Groq からの応答を解析できませんでした。');
    }
  }

  /// Shared request/response handling for both AI features: posts [prompt]
  /// as the sole user message and returns the assistant's raw JSON-string
  /// content. Throws [GroqServiceException] on any HTTP or shape failure;
  /// callers still need to `jsonDecode` the returned string themselves since
  /// each feature expects a different JSON shape back.
  static Future<String> _complete({
    required String apiKey,
    required String prompt,
    String? reasoningEffort,
  }) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'response_format': {'type': 'json_object'},
        if (reasoningEffort != null) 'reasoning_effort': reasoningEffort,
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

    try {
      final choices = body['choices'] as List<dynamic>;
      final message = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>;
      return message['content'] as String;
    } catch (_) {
      throw GroqServiceException('Groq からの応答を解析できませんでした。');
    }
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
