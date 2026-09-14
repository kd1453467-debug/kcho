import 'package:flutter/cupertino.dart';

/// Warm "paper notebook" (帳) palette — centralized so the theme can be
/// adjusted from one place.
///
/// This is a fixed light palette rather than an adaptive one: the design is
/// meant to always read as warm paper, regardless of system appearance.
abstract final class AppColors {
  /// Main screen background — warm cream paper.
  static const Color paperBackground = Color(0xFFF5EFE1);

  /// Cards, list rows, flashcard face — lighter paper.
  static const Color cardBackground = Color(0xFFFFFBF3);

  /// Primary text — warm dark brown, not pure black.
  static const Color inkPrimary = Color(0xFF3A2E27);

  /// Secondary text — readings, hints, labels.
  static const Color inkSecondary = Color(0xFF8A7B6C);

  /// Primary accent — buttons, selected tab/segment, progress highlights.
  /// Evokes a hanko (判子) seal stamp.
  static const Color hankoRed = Color(0xFFB33F3F);

  /// Dividers, card borders, ruled-paper-style lines.
  static const Color borderLine = Color(0xFFE0D5C0);

  /// Correct quiz answer highlight — muted, not neon.
  static const Color successGreen = Color(0xFF6B8E4E);

  /// Wrong quiz answer highlight.
  static const Color errorRed = Color(0xFFA83232);
}
