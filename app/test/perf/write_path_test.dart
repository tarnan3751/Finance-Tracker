// The local write path timed on the dev wiring (docs/reference/performance.md): an
// encrypted database in a temporary file opened by the app's open path (WAL, the busy
// handler, the full-text index), the Drift repositories and the real change recorder.
// Timed: `upsertAll` of 1,000 and of 10,000 generated transactions into an empty
// account, a sync pull of 5,000 transactions (another device's entries) applied through
// the Drift sync store, and the CSV import's read and review of 10,000 rows. Each runs
// FT_PERF_RUNS times (1 by default, as the gate runs it; tools/perf/write_path.sh asks
// for 3) on a fresh database, and the medians, minimums and maximums are printed, the
// last line as the JSON the script records. The ceilings are generous on purpose: the
// baseline is the number printed, not the assertion, which only keeps the path from
// rotting or hanging.
@Tags(['perf'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/device_clock.dart';
import 'package:finance_tracker/features/import/application/import_providers.dart';
import 'package:finance_tracker/features/import/domain/csv_reader.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../contract/repository_fixture.dart';
import '../features/import/import_support.dart';
import '../helpers/dev_wiring.dart';

/// How many times each measurement runs.
final int _runs = int.tryParse(Platform.environment['FT_PERF_RUNS'] ?? '') ?? 1;

const Account _account = Account(
  id: 'perf-checking',
  type: AccountType.depository,
  name: 'Checking',
  currencyCode: 'USD',
  isHidden: false,
  displayOrder: 0,
);

const List<String> _merchants = [
  'NORTHWIND GROCERS',
  'CONTOSO COFFEE',
  'ADVENTURE WORKS FUEL',
  'FABRIKAM PHARMACY',
  'TAILSPIN AIRLINES',
  'WINGTIP TOYS',
  'LITWARE BOOKS',
  'PROSEWARE CINEMA',
];

/// [count] manual transactions on [_account], the same for the same [seed]: eight a
/// day back from 2026-10-24, amounts up to 500.00 out.
List<Transaction> _generated(int count, {int seed = 11, String prefix = 'w'}) {
  final Random random = Random(seed);
  final LocalDate last = LocalDate(2026, 10, 24);
  final DateTime at = DateTime.utc(2026, 10, 24, 15);
  return [
    for (int i = 0; i < count; i++)
      Transaction(
        id: '$prefix-$i',
        accountId: _account.id,
        amount: Money(-(random.nextInt(50000) + 1), 'USD'),
        date: last.addDays(-(i ~/ 8)),
        pending: false,
        name: '${_merchants[random.nextInt(_merchants.length)]} ${i % 97}',
        source: DataSource.manual,
        createdAt: at,
        updatedAt: at,
        syncVersion: 0,
      ),
  ];
}

/// One device on the dev wiring over [database].
ProviderContainer _device(AppDatabase database, String deviceId) =>
    ProviderContainer.test(
      overrides: [
        ...devWiring(),
        ...fakeApiOverrides(signedIn: true),
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(SteppingClock()),
        syncDeviceIdProvider.overrideWithValue(deviceId),
      ],
    );

/// The median, minimum and maximum of [millis], in milliseconds.
Map<String, int> _stats(List<int> millis) {
  final List<int> sorted = [...millis]..sort();
  final int n = sorted.length;
  final int median = n.isOdd
      ? sorted[n ~/ 2]
      : ((sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2).round();
  return {'median_ms': median, 'min_ms': sorted.first, 'max_ms': sorted.last};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  final Map<String, Map<String, int>> results = {};

  setUp(() {
    directory = Directory.systemTemp.createTempSync('spendthrift-perf-');
  });
  tearDown(() => directory.deleteSync(recursive: true));
  tearDownAll(() {
    for (final MapEntry<String, Map<String, int>> e in results.entries) {
      // ignore: avoid_print
      print(
        'perf: ${e.key}: median ${e.value['median_ms']} ms '
        '(min ${e.value['min_ms']}, max ${e.value['max_ms']}, $_runs run(s))',
      );
    }
    // ignore: avoid_print
    print('perf-record: ${jsonEncode({'runs': _runs, 'results': results})}');
  });

  int fileNumber = 0;

  /// A new encrypted database file, opened as the app opens it.
  Future<AppDatabase> open() async {
    final AppDatabase database = AppDatabase(
      await openDatabaseExecutor(
        File('${directory.path}/perf-${fileNumber++}.db'),
        keyStore: InMemoryDatabaseKeyStore(),
      ),
    );
    expect(await database.fullTextSearch, isTrue);
    return database;
  }

  /// Runs [body] [_runs] times, each on a fresh database holding [_account], timing
  /// what it returns a stopwatch for, and records the figures as [name].
  Future<void> measure(
    String name,
    Future<Stopwatch> Function(ProviderContainer device, AppDatabase db) body,
  ) async {
    final List<int> millis = [];
    for (int run = 0; run < _runs; run++) {
      final AppDatabase database = await open();
      final ProviderContainer device = _device(database, 'dev-a');
      try {
        await device.read(accountRepositoryProvider).create(_account);
        millis.add((await body(device, database)).elapsedMilliseconds);
      } finally {
        device.dispose();
        await database.close();
      }
    }
    results[name] = _stats(millis);
  }

  for (final int count in [1000, 10000]) {
    test(
      'upsertAll of $count transactions',
      timeout: Timeout(Duration(minutes: 10 * _runs)),
      () async {
        final List<Transaction> batch = _generated(count);
        await measure('upsert_all_$count', (device, database) async {
          final Stopwatch watch = Stopwatch()..start();
          await device.read(transactionRepositoryProvider).upsertAll(batch);
          watch.stop();
          expect(
            await device
                .read(transactionRepositoryProvider)
                .count(TransactionQuery(accountIds: {_account.id})),
            count,
          );
          expect(watch.elapsed, lessThan(Duration(milliseconds: 48 * count)));
          return watch;
        });
      },
    );
  }

  test(
    'a sync pull of 5,000 transactions through the store',
    timeout: Timeout(Duration(minutes: 5 + 5 * _runs)),
    () async {
      // The other device writes the account and the transactions, recorded as the app
      // records them, and pushes them; it is not timed.
      final SteppingClock relayClock = SteppingClock();
      final InMemorySyncRelay relay = InMemorySyncRelay(
        nowWallMillis: () => relayClock.nowUtc().millisecondsSinceEpoch,
      );
      final AppDatabase other = AppDatabase(NativeDatabase.memory());
      final ProviderContainer writer = _device(other, 'dev-b');
      try {
        await writer.read(accountRepositoryProvider).create(_account);
        await writer
            .read(transactionRepositoryProvider)
            .upsertAll(_generated(5000, seed: 12, prefix: 's'));
        await writer.read(deviceClockProvider).adopt('dev-b');
        final DriftSyncStore store = writer.read(driftSyncStoreProvider);
        final SyncReport pushed = await SyncSession(
          store,
          relay,
          await store.transaction(writer.read(deviceClockProvider).current),
          nowWallMillis: () => relayClock.nowUtc().millisecondsSinceEpoch,
        ).run();
        expect(pushed.pushed, greaterThanOrEqualTo(5001));
      } finally {
        writer.dispose();
        await other.close();
      }

      final List<int> millis = [];
      for (int run = 0; run < _runs; run++) {
        final AppDatabase database = await open();
        try {
          final SteppingClock clock = SteppingClock();
          final DriftSyncStore store = DriftSyncStore(database, clock);
          final DeviceClock deviceClock = DeviceClock(store);
          final Stopwatch watch = Stopwatch()..start();
          await deviceClock.adopt('dev-a');
          final SyncReport report = await SyncSession(
            store,
            relay,
            await store.transaction(deviceClock.current),
            nowWallMillis: () => clock.nowUtc().millisecondsSinceEpoch,
          ).run();
          watch.stop();
          expect(report.pulled, greaterThanOrEqualTo(5001));
          final int rows =
              (await database
                      .customSelect('SELECT count(*) AS n FROM transactions')
                      .getSingle())
                  .read<int>('n');
          expect(rows, 5000);
          expect(watch.elapsed, lessThan(const Duration(minutes: 4)));
          millis.add(watch.elapsedMilliseconds);
        } finally {
          await database.close();
        }
      }
      results['sync_pull_5000'] = _stats(millis);
    },
  );

  test(
    "the import's read and review of 10,000 rows",
    timeout: Timeout(Duration(minutes: 2 * _runs)),
    () async {
      final StringBuffer csv = StringBuffer('Date,Description,Amount\n');
      for (final Transaction t in _generated(10000, seed: 13)) {
        csv.write(
          '${t.date.toIso()},${t.name},'
          '-${-t.amount.minorUnits ~/ 100}.'
          '${(-t.amount.minorUnits % 100).toString().padLeft(2, '0')}\n',
        );
      }
      final PickedCsv file = pickedCsv(csv.toString());
      await measure('import_review_10000', (device, database) async {
        final ImportActions actions = device.read(importActionsProvider);
        final Stopwatch watch = Stopwatch()..start();
        final CsvTable table = await actions.read(file);
        final ImportReview review = await actions.review(
          file: file,
          table: table,
          headerRow: 0,
          mapping: plainMapping(),
          target: const ExistingAccount(_account),
        );
        watch.stop();
        expect(review.failures, isEmpty);
        expect(watch.elapsed, lessThan(const Duration(minutes: 1)));
        return watch;
      });
    },
  );
}
