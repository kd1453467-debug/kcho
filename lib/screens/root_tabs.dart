import 'package:flutter/cupertino.dart';

import '../theme/app_colors.dart';
import 'flashcard_screen.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';

/// Bottom tab bar that hosts the main sections of the app.
class RootTabs extends StatelessWidget {
  const RootTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: AppColors.hankoRed,
        inactiveColor: AppColors.inkSecondary,
        backgroundColor: AppColors.cardBackground,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.rectangle_stack),
            label: 'Flashcards',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.checkmark_circle),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(builder: (_) => const HomeScreen());
          case 1:
            return CupertinoTabView(builder: (_) => const FlashcardScreen());
          case 2:
            return CupertinoTabView(builder: (_) => const QuizScreen());
          case 3:
            return CupertinoTabView(builder: (_) => const ProgressScreen());
          case 4:
          default:
            return CupertinoTabView(builder: (_) => const SettingsScreen());
        }
      },
    );
  }
}
