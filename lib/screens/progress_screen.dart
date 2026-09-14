import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import '../app_scope.dart';
import '../models/entry.dart';
import '../theme/app_colors.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('進捗')),
      child: SafeArea(
        child: ValueListenableBuilder<Box<Entry>>(
          valueListenable: repo.listenable(),
          builder: (context, _, __) {
            final entries = repo.all();
            final total = entries.length;
            final mastered = entries.where((e) => e.isMastered).length;
            final learning = entries.where((e) => e.isLearning).length;
            final notStarted = total - mastered - learning;

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _StatCard(label: '登録数（合計）', value: total),
                _StatCard(label: 'マスター済み', value: mastered),
                _StatCard(label: '学習中', value: learning),
                _StatCard(label: '未着手', value: notStarted),
                const SizedBox(height: 12),
                _StatCard(
                  label: '単語',
                  value: repo.countOfType(EntryType.tango),
                ),
                _StatCard(
                  label: '文法',
                  value: repo.countOfType(EntryType.grammar),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLine),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: AppColors.inkPrimary)),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.hankoRed,
            ),
          ),
        ],
      ),
    );
  }
}
