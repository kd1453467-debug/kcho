import 'dart:math';

import '../models/entry.dart';
import 'entry_repository.dart';

/// One quiz question: a term plus its shuffled 4-choice Myanmar-meaning
/// options and which index is correct.
class QuizQuestion {
  QuizQuestion({
    required this.entry,
    required this.options,
    required this.correctIndex,
  });

  final Entry entry;
  final List<String> options;
  final int correctIndex;
}

/// Builds quiz sessions.
///
/// Selection is prioritized by spaced-repetition due date (see
/// [Entry.nextReviewDate], updated by `Sm2Service`): entries that are
/// overdue for review fill the session first, most-overdue first, since
/// those are the ones about to be forgotten. If that doesn't fill the
/// session, remaining slots are filled with entries that aren't due yet,
/// soonest-due first — so a session always has up to [sessionSize]
/// questions even before any review history has built up.
class QuizService {
  QuizService._();

  static const int sessionSize = 50;

  static List<QuizQuestion> buildSession(EntryRepository repo, {Random? random}) {
    final rng = random ?? Random();
    final pool = repo.all().where((e) => e.meaningMy.trim().isNotEmpty).toList();
    if (pool.isEmpty) return [];

    final now = DateTime.now();
    final due = pool.where((e) => !e.nextReviewDate.isAfter(now)).toList()
      ..sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
    final notDue = pool.where((e) => e.nextReviewDate.isAfter(now)).toList()
      ..sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));

    final prioritized = [...due, ...notDue];
    final take = min(sessionSize, prioritized.length);
    // Selection order is due-priority; presentation order within the
    // session is shuffled so the quiz doesn't visibly run "most overdue
    // first, then least overdue".
    final chosen = prioritized.take(take).toList()..shuffle(rng);

    return chosen.map((entry) {
      final distractors = pool
          .where((e) => e.id != entry.id && e.meaningMy.trim() != entry.meaningMy.trim())
          .map((e) => e.meaningMy.trim())
          .toSet()
          .toList()
        ..shuffle(rng);

      final options = <String>[entry.meaningMy.trim(), ...distractors.take(3)]..shuffle(rng);

      return QuizQuestion(
        entry: entry,
        options: options,
        correctIndex: options.indexOf(entry.meaningMy.trim()),
      );
    }).toList();
  }
}
