import 'package:flutter/cupertino.dart';

import '../models/entry.dart';
import '../theme/app_colors.dart';

/// A single row in the Home list: term + reading on the left,
/// Myanmar meaning on the right.
class EntryTile extends StatelessWidget {
  const EntryTile({required this.entry, required this.onTap, super.key});

  final Entry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasReading = entry.reading != null && entry.reading!.trim().isNotEmpty;
    return CupertinoListTile(
      onTap: onTap,
      title: Text(
        entry.term,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: AppColors.inkPrimary,
        ),
      ),
      subtitle: hasReading
          ? Text(
              entry.reading!,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSecondary),
            )
          : null,
      additionalInfo: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 170),
        child: Text(
          entry.meaningMy,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: const TextStyle(color: AppColors.inkSecondary),
        ),
      ),
      trailing: const CupertinoListTileChevron(),
    );
  }
}
