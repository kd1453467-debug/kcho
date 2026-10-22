import 'dart:convert';

import 'package:hive/hive.dart';

/// One multiple-choice comprehension question about a [ReadingPassage].
class ReadingQuestion {
  ReadingQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final String question;
  final List<String> options;
  final int correctIndex;

  factory ReadingQuestion.fromJson(Map<String, dynamic> json) => ReadingQuestion(
        question: json['question'] as String,
        options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
        correctIndex: json['correctIndex'] as int,
      );

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
      };
}

/// An AI-generated JLPT reading-comprehension passage with its questions.
///
/// [questions] is stored as a single JSON-encoded string field rather than a
/// nested Hive type, to keep the hand-written adapter simple — matching
/// [Entry]'s approach of avoiding build_runner / codegen.
class ReadingPassage extends HiveObject {
  ReadingPassage({
    required this.id,
    required this.level,
    required this.passage,
    required this.questions,
    required this.createdAt,
  });

  /// Stable UUID, also used as the Hive key.
  final String id;

  /// JLPT level this was generated for, e.g. "N5".
  String level;

  String passage;
  List<ReadingQuestion> questions;
  final DateTime createdAt;
}

/// Hand-written Hive adapter (keeps the project free of build_runner / codegen).
class ReadingPassageAdapter extends TypeAdapter<ReadingPassage> {
  @override
  final int typeId = 1;

  @override
  ReadingPassage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final questionsJson = jsonDecode(fields[3] as String) as List<dynamic>;
    return ReadingPassage(
      id: fields[0] as String,
      level: fields[1] as String,
      passage: fields[2] as String,
      questions: questionsJson
          .map((e) => ReadingQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingPassage obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.passage)
      ..writeByte(3)
      ..write(jsonEncode(obj.questions.map((q) => q.toJson()).toList()))
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingPassageAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
