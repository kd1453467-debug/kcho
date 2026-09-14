import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app_scope.dart';
import 'models/entry.dart';
import 'screens/root_tabs.dart';
import 'services/entry_repository.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(EntryAdapter());
  final box = await Hive.openBox<Entry>(EntryRepository.boxName);

  final repository = EntryRepository(box);
  await repository.seedIfEmpty();

  runApp(KchoApp(repository: repository));
}

class KchoApp extends StatelessWidget {
  const KchoApp({required this.repository, super.key});

  final EntryRepository repository;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: repository,
      child: const CupertinoApp(
        title: 'K帳',
        debugShowCheckedModeBanner: false,
        theme: CupertinoThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: AppColors.paperBackground,
          barBackgroundColor: AppColors.cardBackground,
          primaryColor: AppColors.hankoRed,
          primaryContrastingColor: CupertinoColors.white,
          textTheme: CupertinoTextThemeData(
            primaryColor: AppColors.hankoRed,
            textStyle: TextStyle(color: AppColors.inkPrimary, fontSize: 17),
            navTitleTextStyle: TextStyle(
              color: AppColors.inkPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            navLargeTitleTextStyle: TextStyle(
              color: AppColors.inkPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        home: RootTabs(),
      ),
    );
  }
}
