import 'package:flutter/cupertino.dart';

import '../models/entry.dart';
import '../theme/app_colors.dart';

/// Shared 単語/文法 sliding segmented control, styled with the hanko-red
/// thumb so every screen (Home, Add Entry, Flashcard) looks the same.
class TypeSegmentedControl extends StatelessWidget {
  const TypeSegmentedControl({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final EntryType value;
  final ValueChanged<EntryType> onChanged;

  Widget _label(String text, {required bool selected}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          inherit: false,
          color: selected ? CupertinoColors.white : AppColors.inkPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<EntryType>(
      groupValue: value,
      thumbColor: AppColors.hankoRed,
      backgroundColor: AppColors.borderLine.withValues(alpha: 0.5),
      onValueChanged: (newValue) {
        if (newValue != null) onChanged(newValue);
      },
      children: {
        EntryType.tango: _label('単語', selected: value == EntryType.tango),
        EntryType.grammar: _label('文法', selected: value == EntryType.grammar),
      },
    );
  }
}
