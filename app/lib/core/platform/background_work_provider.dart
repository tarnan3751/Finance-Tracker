/// Which [BackgroundWork] schedules the background sync: the fake by default (the demo
/// flavor, which never schedules, and the tests), `workmanager` in dev and prod
/// (`overridesFor`).
library;

import 'package:finance_tracker/core/platform/background_work.dart';
import 'package:finance_tracker/core/platform/fake_background_work.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'background_work_provider.g.dart';

/// The background work.
@Riverpod(keepAlive: true)
BackgroundWork backgroundWork(Ref ref) => FakeBackgroundWork();
