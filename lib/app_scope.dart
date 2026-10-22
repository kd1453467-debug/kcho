import 'package:flutter/widgets.dart';

import 'services/entry_repository.dart';
import 'services/reading_repository.dart';

/// Makes the shared [EntryRepository] and [ReadingRepository] available to
/// the whole widget tree.
class AppScope extends InheritedWidget {
  const AppScope({
    required this.repository,
    required this.readingRepository,
    required super.child,
    super.key,
  });

  final EntryRepository repository;
  final ReadingRepository readingRepository;

  static EntryRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree');
    return scope!.repository;
  }

  static ReadingRepository readingOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree');
    return scope!.readingRepository;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.repository != repository || oldWidget.readingRepository != readingRepository;
}
