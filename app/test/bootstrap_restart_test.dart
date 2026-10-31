// bootstrap's restart (the one a restore runs under) closing the database while its
// query streams are still settling: a stream whose subscription ends with the container,
// just before the close, which Drift removes on a timer, and a read still in flight,
// paused by its asyncMap, which holds the close back until the timer has run. Drift's
// store iterates its streams across that wait; the restart still stops the app, runs the
// work and starts it again. A close raced five times in a row fails with the race. Its
// own file: the test binding's frames do not carry over from the other bootstrap tests.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/backup/application/backup_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'core/api/support/fake_api.dart';
import 'helpers/wipe_support.dart';

void main() {
  testWidgets('the restart closes the database under a read still in flight', (
    tester,
  ) async {
    final InMemoryTokenStore tokens = InMemoryTokenStore();
    await tester.runAsync(
      () => startApp(
        AppConfig.demo(),
        overrides: wipeTestOverrides(
          newFakeServer(),
          tokens,
          TestWipe(tokens),
          database: (ref) {
            final AppDatabase database = AppDatabase(NativeDatabase.memory());
            // A subscription that ends with the container, right before the close.
            final StreamSubscription<Object> rows = database
                .select(database.accounts)
                .watch()
                .listen((_) {});
            ref.onDispose(rows.cancel);
            ref.onDispose(() => databaseClosing[database] = database.close());
            return database;
          },
        ),
      ),
    );
    await settleWipe(tester);
    final ProviderContainer first = ProviderScope.containerOf(
      tester.element(find.byType(FinanceTrackerApp)),
    );
    final AppDatabase database = first.read(databaseProvider);

    // A job's one-shot read, paused in its asyncMap until [held] completes.
    final Completer<void> held = Completer<void>();
    bool read = false;
    unawaited(
      database
          .select(database.categories)
          .watch()
          .asyncMap((rows) async {
            read = true;
            await held.future;
            return rows;
          })
          .first
          .then((_) {}, onError: (Object _) {}),
    );
    await settleWipe(tester);
    expect(read, isTrue);

    Object? failure;
    bool restarted = false;
    unawaited(
      first
          .read(appRestartProvider)((_) async {})
          .then(
            (_) => restarted = true,
            onError: (Object e) {
              failure = e;
              return false;
            },
          ),
    );
    // The old tree goes, the container is disposed and the close starts; Drift's
    // removal timer runs while the read holds it back.
    await settleWipe(tester);
    expect(restarted, isFalse);
    held.complete();
    await settleWipe(tester);

    expect(failure, isNull);
    expect(restarted, isTrue);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => databaseClosing[database]!);
    final ProviderContainer second = ProviderScope.containerOf(
      tester.element(find.byType(FinanceTrackerApp)),
    );
    expect(second, isNot(same(first)));
    expect(second.read(databaseProvider), isNot(same(database)));

    await tester.runAsync(stopApp);
    await tester.pumpWidget(const SizedBox());
  });

  test('a close raced five times in a row fails with the race', () async {
    int passes = 0;
    await expectLater(
      closeAgainOnRace(() async {
        passes++;
        throw ConcurrentModificationError();
      }),
      throwsA(isA<ConcurrentModificationError>()),
    );
    expect(passes, 5);

    passes = 0;
    await closeAgainOnRace(() async {
      if (++passes < 5) throw ConcurrentModificationError();
    });
    expect(passes, 5);
  });
}
