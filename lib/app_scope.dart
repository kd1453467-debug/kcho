import 'package:flutter/widgets.dart';

import 'services/entry_repository.dart';

/// Makes the shared [EntryRepository] available to the whole widget tree.
class AppScope extends InheritedWidget {
  const AppScope({
    required this.repository,
    required super.child,
    super.key,
  });

  final EntryRepository repository;

  static EntryRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.repository != repository;
}
