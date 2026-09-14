import '../models/entry.dart';

/// The classic SuperMemo SM-2 spaced-repetition algorithm.
///
/// Our quiz is multiple-choice (a binary correct/wrong answer), not SM-2's
/// usual 0-5 self-rating, so [review] maps that onto the quality scale
/// itself: a correct answer counts as quality 5 ("perfect response"), a
/// wrong one as quality 2 ("incorrect, but the right answer felt familiar").
///
/// This only updates [Entry.easeFactor]/[Entry.interval]/[Entry.repetitions]/
/// [Entry.nextReviewDate] — it does not touch correctCount/wrongCount or
/// lastReviewed, which the Progress screen's stats rely on separately.
class Sm2Service {
  Sm2Service._();

  static const int _qualityCorrect = 5;
  static const int _qualityWrong = 2;
  static const double _minEaseFactor = 1.3;

  /// Applies one SM-2 review step to [entry] based on whether the quiz
  /// answer was [correct].
  static void review(Entry entry, {required bool correct}) {
    final quality = correct ? _qualityCorrect : _qualityWrong;

    if (quality < 3) {
      entry.repetitions = 0;
      entry.interval = 1;
    } else {
      if (entry.repetitions == 0) {
        entry.interval = 1;
      } else if (entry.repetitions == 1) {
        entry.interval = 6;
      } else {
        entry.interval = (entry.interval * entry.easeFactor).round();
      }
      entry.repetitions += 1;
    }

    final q = quality.toDouble();
    final newEase = entry.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    entry.easeFactor = newEase < _minEaseFactor ? _minEaseFactor : newEase;

    entry.nextReviewDate = DateTime.now().add(Duration(days: entry.interval));
  }
}
