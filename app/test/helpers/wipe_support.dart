// What the bootstrap wipe tests share: a wipe that clears the token store and can fail
// or start pending, the prod wiring of the tests for the demo's startup path, and the
// frames the startup, the stop and the wipe need.

import 'package:drift/native.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/auth/application/device_name.dart';
import 'package:finance_tracker/features/backup/application/backup_providers.dart';
import 'package:finance_tracker/features/settings/application/package_info.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';
import 'restore_offer.dart';

/// Clears [tokens] as the real wipe does, failing its first [failures] runs, pending
/// from its start to its end ([pendingReason], which a test may set as a cut left it).
final class TestWipe implements LocalWipe {
  TestWipe(this.tokens, {this.failures = 0, this.pendingReason});

  final InMemoryTokenStore tokens;
  int failures;
  int runs = 0;
  WipeReason? pendingReason;

  @override
  Future<WipeReason?> pending() async => pendingReason;

  @override
  Future<void> wipe(WipeReason reason) async {
    runs++;
    pendingReason = reason;
    if (failures > 0) {
      failures--;
      throw StateError('storage is busy');
    }
    await tokens.clear();
    await tokens.clearInstallUserId();
    pendingReason = null;
  }
}

/// The prod wiring of the tests over [server], [tokens] and [wipe], for the demo's
/// startup path (no database to open), the database in memory if anything reads it
/// ([onDatabase] is told when it is built).
List<Override> wipeTestOverrides(
  FakeServer server,
  InMemoryTokenStore tokens,
  LocalWipe wipe, {
  void Function()? onDatabase,
}) => [
  appConfigProvider.overrideWithValue(AppConfig.prod()),
  clockProvider.overrideWithValue(testClock),
  packageInfoProvider.overrideWith((ref) async => testPackageInfo),
  deviceNameProvider.overrideWith((ref) async => 'Pixel 6'),
  appVersionProvider.overrideWith((ref) async => testPackageInfo.version),
  fakeServerProvider.overrideWithValue(server),
  tokenStoreProvider.overrideWithValue(tokens),
  fakeFinanceApiOverride,
  localWipeProvider.overrideWithValue(wipe),
  restoreOfferProvider.overrideWith(AnsweredRestoreOffer.new),
  // What stopApp closes: the prod wiring reads it.
  databaseProvider.overrideWith((ref) {
    onDatabase?.call();
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    ref.onDispose(database.close);
    return database;
  }),
];

// Frames enough for the app's startup, the stop and the wipe; the app shell keeps a
// progress indicator going, so pumpAndSettle would not return.
Future<void> settleWipe(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
