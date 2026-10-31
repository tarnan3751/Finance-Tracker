/// The [AppShortcuts] of the tests: no launcher, every list recorded.
library;

import 'package:finance_tracker/core/platform/app_shortcuts.dart';

/// App shortcuts without a platform.
final class FakeAppShortcuts implements AppShortcuts {
  /// Every list [set] was given, in order.
  final List<List<AppShortcut>> calls = [];

  @override
  Future<void> set(List<AppShortcut> shortcuts) async => calls.add(shortcuts);
}
