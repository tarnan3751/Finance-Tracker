// Test doubles more than one test file uses: a clock the test moves, a device id it
// changes, a sync controller it finishes, and a mocked secure storage.
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

/// A clock that reads [utc], which the test moves, in [location] (UTC by default).
final class MovableClock implements Clock {
  MovableClock(this.utc, [tz.Location? location])
    : location = location ?? tz.UTC;

  DateTime utc;

  @override
  final tz.Location location;

  @override
  DateTime nowUtc() => utc;

  @override
  DateTime todayLocalMidnight() {
    final tz.TZDateTime local = tz.TZDateTime.from(utc, location);
    return tz.TZDateTime(location, local.year, local.month, local.day);
  }

  @override
  LocalDate today() => LocalDate.fromDateTime(todayLocalMidnight());
}

/// The session's device id, `dev-a` until the test changes it, as a sign-out and
/// sign-in change it.
final class SettableDeviceId extends Notifier<String?> {
  @override
  String? build() => 'dev-a';

  void set(String? id) => state = id;
}

/// A sync controller that is signed out until the test finishes a session.
final class FinishingSync extends SyncController {
  @override
  SyncStatus build() => SyncStatus.signedOut;

  /// A session finished [at].
  void finish(DateTime at) =>
      state = SyncStatus(phase: SyncPhase.idle, lastSyncAt: at);
}

/// A secure storage whose answers the test scripts.
class MockSecureStorage extends Mock implements FlutterSecureStorage {}
