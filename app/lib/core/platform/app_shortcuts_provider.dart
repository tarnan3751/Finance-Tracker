/// Which [AppShortcuts] sets the launcher's shortcuts: the fake by default (the tests),
/// `quick_actions` in every flavor (`overridesFor`).
library;

import 'package:finance_tracker/core/platform/app_shortcuts.dart';
import 'package:finance_tracker/core/platform/fake_app_shortcuts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_shortcuts_provider.g.dart';

/// The app shortcuts.
@Riverpod(keepAlive: true)
AppShortcuts appShortcuts(Ref ref) => FakeAppShortcuts();
