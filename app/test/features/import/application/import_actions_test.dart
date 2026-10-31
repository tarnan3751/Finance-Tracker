// The import's work on the in-memory repositories: a picked file read in ranges and
// closed, a file over the cap refused unread; the review's rows as `import` transactions
// with their merchants, notes, tags and categories matched by name, the duplicates found
// against the account's rows, the same file warned of; the write in one batch stamped
// now, the rules applied on arrival, today's snapshots rewritten, the preset saved and
// the import recorded; a new manual account created, and deleted again when the batch is
// refused; and the undo deleting the batch's rows, an edited one too, and marking it.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/fake_backup_picker.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/util/stream_current.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/import/application/import_providers.dart';
import 'package:finance_tracker/features/import/domain/csv_reader.dart';
import 'package:finance_tracker/features/import/domain/date_formats.dart';
import 'package:finance_tracker/features/import/domain/import_mapping.dart';
import 'package:finance_tracker/features/import/domain/import_records.dart';
import 'package:finance_tracker/features/import/domain/row_conversion.dart';
import 'package:finance_tracker/features/lock/application/lock_hold.dart';
import 'package:finance_tracker/features/net_worth/application/snapshot_writer.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/rule_seed.dart';
import '../../../helpers/seed.dart';
import '../import_support.dart';

/// An app_meta store whose writes of [key] fail from the [failFrom]th on.
final class _FailingMeta implements AppMetaStore {
  _FailingMeta(this.key, this.failFrom);

  final String key;
  final int failFrom;
  final InMemoryAppMetaStore _inner = InMemoryAppMetaStore();
  int writes = 0;

  @override
  Future<String?> read(String key) => _inner.read(key);

  @override
  Future<void> write(String key, String value) async {
    if (key == this.key && ++writes >= failFrom) {
      throw StateError('the store is full');
    }
    return _inner.write(key, value);
  }
}

/// Records what the history holds when the batch is written.
final class _ObservedTransactions extends InMemoryTransactionRepository {
  _ObservedTransactions(super.store, this._history)
    : super(recorder: const NoChangeRecorder());

  final Future<List<ImportBatch>> Function() _history;
  List<ImportBatch>? seenAtWrite;

  @override
  Future<void> upsertAll(List<Transaction> batch) async {
    seenAtWrite = await _history();
    return super.upsertAll(batch);
  }
}

/// Refuses every batch, as a repository does when a row is refused.
final class _RefusingTransactions extends InMemoryTransactionRepository {
  _RefusingTransactions(super.store)
    : super(recorder: const NoChangeRecorder());

  @override
  Future<void> upsertAll(List<Transaction> batch) =>
      throw ArgumentError('refused');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryStore store;
  late ProviderContainer container;

  ProviderContainer build({List<Override> extra = const []}) {
    final ProviderContainer c = ProviderContainer.test(
      overrides: testOverrides(
        overrides: [
          storeOverride(store),
          rulesOverride(seededRules(rules: [rentRule])),
          ...extra,
        ],
      ),
    );
    return c;
  }

  setUp(() {
    store = seededStore();
    container = build();
  });
  tearDown(() => store.close());

  ImportActions actions() => container.read(importActionsProvider);

  Future<Account> checking() async => (await currentValue<Account?>(
    container.read(accountRepositoryProvider).watchById(checkingId),
  ))!;

  Future<List<Transaction>> imported() async => [
    for (final Transaction t in await currentValue(
      container.read(transactionRepositoryProvider).watch(TransactionQuery()),
    ))
      if (t.source == DataSource.import) t,
  ];

  Future<ImportReview> review(
    PickedCsv file, {
    ImportMapping? mapping,
    ImportTarget? target,
  }) async {
    final CsvTable table = await actions().read(file);
    return actions().review(
      file: file,
      table: table,
      headerRow: 0,
      mapping: mapping ?? plainMapping(),
      target: target ?? ExistingAccount(await checking()),
    );
  }

  group('pick', () {
    test('reads the file in ranges, hashes it and closes it', () async {
      final FakeBackupPicker picker = FakeBackupPicker(
        file: Uint8List(importReadChunk * 2 + 5),
        name: 'big.csv',
      );
      final PickedCsv file = (await actions().pick(picker))!;
      expect(file.name, 'big.csv');
      expect(file.bytes, hasLength(importReadChunk * 2 + 5));
      expect(file.sha256, hasLength(64));
      expect(picker.reads, [
        (0, importReadChunk),
        (importReadChunk, importReadChunk * 2),
        (importReadChunk * 2, importReadChunk * 2 + 5),
      ]);
      expect(picker.closed, 1);
    });

    test('nothing chosen is null; over the cap is refused unread', () async {
      expect(await actions().pick(FakeBackupPicker()), isNull);
      final FakeBackupPicker big = FakeBackupPicker(
        file: Uint8List(1),
        length: maxImportBytes + 1,
      );
      await expectLater(
        actions().pick(big),
        throwsA(isA<ImportTooLargeException>()),
      );
      expect(big.reads, isEmpty);
      expect(big.closed, 1);
    });
  });

  group('review and write', () {
    const String file =
        'Date,Description,Amount,Merchant,Notes,Category,Tags\n'
        '2026-10-20,RENT OCTOBER,-1500.00,,Paid early,,\n'
        '2026-10-21,CONTOSO COFFEE 0193,-4.75,Contoso,,{category},work\n'
        '2026-10-22,Bad row,ten,,,,\n'
        '2026-10-23,FABRIKAM PAYROLL,1850.00,,,,salary;monthly\n';

    test('the rows as import transactions, written in one batch', () async {
      final List<Category> categories = await currentValue(
        container.read(categoryRepositoryProvider).watchAll(),
      );
      final Category coffee = categories.firstWhere(
        (c) => categories.where((d) => d.name == c.name).length == 1,
      );
      final Money before = (await currentValue(
        container
            .read(accountRepositoryProvider)
            .watchDerivedBalance(checkingId),
      ))!;
      final ImportReview r = await review(
        pickedCsv(file.replaceFirst('{category}', coffee.name.toUpperCase())),
        mapping: plainMapping({
          ImportRole.merchant: 3,
          ImportRole.notes: 4,
          ImportRole.category: 5,
          ImportRole.tags: 6,
        }),
      );
      expect(r.incoming, hasLength(3));
      expect(r.failures, [(row: 4, problem: RowProblem.badAmount)]);
      expect(r.duplicates, isEmpty);
      expect(r.importedBefore, isFalse);
      expect(r.incoming[1].merchantName, 'Contoso');
      expect(r.incoming[1].userCategoryId, coffee.id);
      expect(r.incoming[0].notes, 'Paid early');
      expect(r.incoming[2].tags, ['salary', 'monthly']);

      final ImportResult result = await actions().write(
        r,
        includeDuplicates: false,
      );
      expect(result.skipped, 0);
      expect(result.account.id, checkingId);
      final List<Transaction> rows = await imported();
      expect(rows, hasLength(3));
      for (final Transaction t in rows) {
        expect(t.source, DataSource.import);
        expect(t.pending, isFalse);
        expect(t.syncVersion, 0);
        expect(t.accountId, checkingId);
        expect(t.createdAt, testClock.nowUtc());
        expect(t.updatedAt, testClock.nowUtc());
      }
      // The rules ran on arrival: the rent rule tags the rent.
      expect(
        rows.firstWhere((t) => t.name == 'RENT OCTOBER').tags,
        contains('home'),
      );
      final Money after = (await currentValue(
        container
            .read(accountRepositoryProvider)
            .watchDerivedBalance(checkingId),
      ))!;
      expect(after - before, Money(-150000 - 475 + 185000, 'USD'));
      // Today's snapshots were rewritten with the new balance.
      final List<BalanceSnapshot> snapshots = await currentValue(
        container
            .read(balanceSnapshotRepositoryProvider)
            .watchByAccount(checkingId),
      );
      expect(
        snapshots.singleWhere((s) => s.date == testClock.today()).current,
        after,
      );

      final AppMetaStore meta = container.read(appMetaStoreProvider);
      final ImportBatch batch = decodeHistory(
        await meta.read(AppMetaKeys.importHistory),
      ).single;
      expect(batch.count, 3);
      expect(batch.fileName, 'export.csv');
      expect(batch.sha256, r.file.sha256);
      expect(batch.accountId, checkingId);
      expect(batch.importedAt, testClock.nowUtc());
      expect(batch.transactionIds.toSet(), {for (final t in rows) t.id});
      final ImportPreset preset = decodePresets(
        await meta.read(AppMetaKeys.importPresets),
      ).single;
      expect(preset.accountId, checkingId);
      expect(
        await actions().presetFor(
          'Date,Description,Amount,Merchant,Notes,Category,Tags'.split(','),
        ),
        isNotNull,
      );
      expect(await actions().presetFor(['Other', 'header', 'row']), isNull);
    });

    test('the same file again: warned, every row a duplicate', () async {
      final PickedCsv picked = pickedCsv(file.replaceFirst('{category}', ''));
      await actions().write(await review(picked), includeDuplicates: false);
      final ImportReview again = await review(picked);
      expect(again.importedBefore, isTrue);
      expect(again.duplicates, {for (final t in again.incoming) t.id});
      final ImportResult skipped = await actions().write(
        again,
        includeDuplicates: false,
      );
      expect(skipped.skipped, 3);
      expect(skipped.batch.count, 0);
      expect(await imported(), hasLength(3));
      // With the switch on, they are written anyway.
      final ImportReview third = await review(picked);
      await actions().write(third, includeDuplicates: true);
      expect(await imported(), hasLength(6));
    });

    test('a new manual account is created for the rows', () async {
      final ImportReview r = await review(
        pickedCsv(file.replaceFirst('{category}', '')),
        target: const NewAccount(
          name: 'Old checking',
          type: AccountType.depository,
          currencyCode: 'EUR',
        ),
      );
      expect(r.incoming.first.amount.currencyCode, 'EUR');
      final ImportResult result = await actions().write(
        r,
        includeDuplicates: false,
      );
      expect(result.account.name, 'Old checking');
      expect(result.account.itemId, isNull);
      expect(result.account.currencyCode, 'EUR');
      final List<Transaction> rows = await imported();
      expect(rows.map((t) => t.accountId).toSet(), {result.account.id});
      final ImportPreset preset = decodePresets(
        await container
            .read(appMetaStoreProvider)
            .read(AppMetaKeys.importPresets),
      ).single;
      expect(preset.accountId, result.account.id);
    });

    test('a refused batch leaves no new account behind', () async {
      container.dispose();
      container = build(
        extra: [
          transactionRepositoryProvider.overrideWith(
            (ref) => _RefusingTransactions(store),
          ),
        ],
      );
      final List<Account> before = await currentValue(
        container.read(accountRepositoryProvider).watchAll(),
      );
      final ImportReview r = await review(
        pickedCsv(file.replaceFirst('{category}', '')),
        target: const NewAccount(
          name: 'Old checking',
          type: AccountType.depository,
          currencyCode: 'USD',
        ),
      );
      await expectLater(
        actions().write(r, includeDuplicates: false),
        throwsArgumentError,
      );
      expect(
        await currentValue(
          container.read(accountRepositoryProvider).watchAll(),
        ),
        before,
      );
      expect(
        decodeHistory(
          await container
              .read(appMetaStoreProvider)
              .read(AppMetaKeys.importHistory),
        ),
        isEmpty,
      );
    });
  });

  test(
    'undo deletes the batch, edited and deleted rows too, and marks it',
    () async {
      const String file =
          'Date,Description,Amount\n'
          '2026-10-20,One,-1.00\n'
          '2026-10-21,Two,-2.00\n'
          '2026-10-22,Three,-3.00\n';
      final PickedCsv picked = pickedCsv(file);
      final ImportResult result = await actions().write(
        await review(picked),
        includeDuplicates: false,
      );
      final List<Transaction> rows = await imported();
      final repository = container.read(transactionRepositoryProvider);
      await repository.upsert(
        rows.firstWhere((t) => t.name == 'One').copyWith(notes: 'edited'),
      );
      await repository.delete(rows.firstWhere((t) => t.name == 'Two').id);
      await actions().undo(result.batch);
      expect(await imported(), isEmpty);
      final ImportBatch undone = decodeHistory(
        await container
            .read(appMetaStoreProvider)
            .read(AppMetaKeys.importHistory),
      ).single;
      expect(undone.undoneAt, testClock.nowUtc());
      expect((await review(picked)).importedBefore, isFalse);
      expect(await container.read(importHistoryProvider.future), [
        isA<ImportBatch>().having((b) => b.undoneAt, 'undoneAt', isNotNull),
      ]);
    },
  );

  test('the column values and the date format to start with', () async {
    final CsvTable table = await readCsv(
      utf8.encode('Date,Amount\n03/10/2026,1\n,2\n04/10/2026\n'),
    );
    expect(columnValues(table, 0, 0), ['03/10/2026', '04/10/2026']);
    expect(columnValues(table, 0, 1), ['1', '2']);
    const List<ImportDateFormat> both = [
      ImportDateFormat.us,
      ImportDateFormat.day,
    ];
    expect(
      preferredDateFormat(both, localePattern: 'M/d/y'),
      ImportDateFormat.us,
    );
    expect(
      preferredDateFormat(both, localePattern: 'dd/MM/y'),
      ImportDateFormat.day,
    );
    expect(
      preferredDateFormat(both, localePattern: 'd.M.y'),
      ImportDateFormat.day,
    );
    expect(
      preferredDateFormat([ImportDateFormat.iso], localePattern: 'dd/MM/y'),
      ImportDateFormat.iso,
    );
    expect(preferredDateFormat(const [], localePattern: 'M/d/y'), isNull);
  });

  test(
    'the actions outlive their provider: snapshots are still written',
    () async {
      final List<String> warnings = [];
      final StreamSubscription<LogRecord> logs = Logger.root.onRecord.listen((
        r,
      ) {
        if (r.loggerName == 'import' && r.level >= Level.WARNING) {
          warnings.add(r.message);
        }
      });
      addTearDown(logs.cancel);
      final SnapshotWriterRunner runner = container.read(
        snapshotWriterRunnerProvider.notifier,
      );
      await runner.settled();
      final ImportActions held = actions();
      final ImportReview r = await review(
        pickedCsv('Date,Description,Amount\n2026-10-20,One,-100.00\n'),
      );
      // Nothing listens to the provider: it goes, and the actions carry on.
      container.invalidate(importActionsProvider);
      await Future<void>.delayed(Duration.zero);
      await held.write(r, includeDuplicates: false);
      final Money balance = (await currentValue(
        container
            .read(accountRepositoryProvider)
            .watchDerivedBalance(checkingId),
      ))!;
      final List<BalanceSnapshot> snapshots = await currentValue(
        container
            .read(balanceSnapshotRepositoryProvider)
            .watchByAccount(checkingId),
      );
      expect(
        snapshots.singleWhere((s) => s.date == testClock.today()).current,
        balance,
      );
      await held.undo(
        decodeHistory(
          await container
              .read(appMetaStoreProvider)
              .read(AppMetaKeys.importHistory),
        ).single,
      );
      expect(
        (await currentValue(
          container
              .read(balanceSnapshotRepositoryProvider)
              .watchByAccount(checkingId),
        )).singleWhere((s) => s.date == testClock.today()).current,
        balance + Money(10000, 'USD'),
      );
      expect(warnings, isEmpty);
    },
  );

  group('the record of an import', () {
    test('is written pending before the rows, complete after', () async {
      final ImportReview r = await review(
        pickedCsv('Date,Description,Amount\n2026-10-20,One,-1.00\n'),
      );
      final AppMetaStore meta = container.read(appMetaStoreProvider);
      final _ObservedTransactions observed = _ObservedTransactions(
        store,
        () async => decodeHistory(await meta.read(AppMetaKeys.importHistory)),
      );
      container.dispose();
      container = build(
        extra: [
          appMetaStoreProvider.overrideWithValue(meta),
          transactionRepositoryProvider.overrideWith((ref) => observed),
        ],
      );
      final ImportResult result = await actions().write(
        r,
        includeDuplicates: false,
      );
      expect(observed.seenAtWrite!.single.pending, isTrue);
      expect(observed.seenAtWrite!.single.id, result.batch.id);
      expect(result.historySaved, isTrue);
      final ImportBatch stored = decodeHistory(
        await meta.read(AppMetaKeys.importHistory),
      ).single;
      expect(stored.pending, isFalse);
      expect(stored.transactionIds, result.batch.transactionIds);
    });

    test(
      'a failure after the rows are in reports the history unsaved',
      () async {
        final _FailingMeta meta = _FailingMeta(AppMetaKeys.importHistory, 2);
        container.dispose();
        container = build(
          extra: [appMetaStoreProvider.overrideWithValue(meta)],
        );
        final ImportResult result = await actions().write(
          await review(
            pickedCsv('Date,Description,Amount\n2026-10-20,One,-1.00\n'),
          ),
          includeDuplicates: false,
        );
        expect(result.historySaved, isFalse);
        expect(await imported(), hasLength(1));
        // The pending record stays, with its ids: the next read marks it complete.
        final ImportBatch left = decodeHistory(
          await meta.read(AppMetaKeys.importHistory),
        ).single;
        expect(left.pending, isTrue);
        final InMemoryAppMetaStore fresh = InMemoryAppMetaStore();
        await fresh.write(AppMetaKeys.importHistory, encodeHistoryList([left]));
        final ImportActions again = ImportActions(
          transactions: container.read(transactionRepositoryProvider),
          accounts: container.read(accountRepositoryProvider),
          accountActions: container.read(accountActionsProvider),
          transactionActions: container.read(transactionActionsProvider),
          categories: container.read(categoryRepositoryProvider),
          arrival: container.read(arrivalProcessorProvider),
          meta: fresh,
          clock: testClock,
          lockHold: LockHold(),
          writeSnapshots: () async {},
        );
        final ImportBatch recovered = (await again.history()).single;
        expect(recovered.id, left.id);
        expect(recovered.pending, isFalse);
      },
    );

    test('a pending record whose rows never landed is dropped once it is '
        'older than the grace, kept while younger', () async {
      final AppMetaStore meta = container.read(appMetaStoreProvider);
      final DateTime now = testClock.nowUtc();
      ImportBatch pending(String id, Duration age) => ImportBatch(
        id: id,
        importedAt: now.subtract(age),
        fileName: '$id.csv',
        sha256: 'ab' * 32,
        accountId: checkingId,
        count: 1,
        transactionIds: ['$id-row'],
        pending: true,
      );
      await meta.write(
        AppMetaKeys.importHistory,
        encodeHistoryList([
          pending('young', pendingGrace - const Duration(seconds: 1)),
          pending('old', pendingGrace + const Duration(seconds: 1)),
          ImportBatch(
            id: 'done',
            importedAt: now,
            fileName: 'b.csv',
            sha256: 'cd' * 32,
            accountId: checkingId,
            count: 0,
            transactionIds: const [],
          ),
        ]),
      );
      final List<ImportBatch> read = await container.read(
        importHistoryProvider.future,
      );
      expect(read.map((b) => (b.id, b.pending)), [
        ('young', true),
        ('done', false),
      ]);
      expect(
        decodeHistory(await meta.read(AppMetaKeys.importHistory))
            .map((b) => b.id),
        ['young', 'done'],
      );
    });
  });

  test('the review sums what each choice writes, once', () async {
    final ImportReview r = await review(
      pickedCsv(
        'Date,Description,Amount\n'
        '2026-10-20,One,-1.00\n'
        '2026-10-22,Two,5.00\n',
      ),
    );
    final ImportSummary all = r.summary(includeDuplicates: true);
    expect(all.count, 2);
    expect(all.first, LocalDate(2026, 10, 20));
    expect(all.last, LocalDate(2026, 10, 22));
    expect(all.moneyIn, Money(500, 'USD'));
    expect(all.moneyOut, Money(-100, 'USD'));
    expect(identical(all, r.summary(includeDuplicates: true)), isTrue);
  });

  test('past the isolate threshold the review gives the same rows', () async {
    final PickedCsv file = pickedCsv(
      'Date,Description,Amount\n2026-10-20,One,-1.00\n2026-10-21,Two,-2.00\n',
    );
    final CsvTable table = await actions().read(file);
    Future<ImportReview> at(int threshold) async => actions().review(
      file: file,
      table: table,
      headerRow: 0,
      mapping: plainMapping(),
      target: ExistingAccount(await checking()),
      isolateThreshold: threshold,
    );
    final ImportReview inline = await at(importIsolateThreshold);
    final ImportReview isolated = await at(0);
    expect(
      isolated.incoming.map((t) => (t.date, t.amount, t.name, t.source)),
      inline.incoming.map((t) => (t.date, t.amount, t.name, t.source)),
    );
  });

  test('a damaged history or preset list reads as empty', () async {
    final AppMetaStore meta = container.read(appMetaStoreProvider);
    await meta.write(AppMetaKeys.importHistory, 'not json');
    await meta.write(AppMetaKeys.importPresets, '[1]');
    expect(await container.read(importHistoryProvider.future), isEmpty);
    expect(await actions().presetFor(['a', 'b', 'c']), isNull);
    final ImportResult result = await actions().write(
      await review(
        pickedCsv('Date,Description,Amount\n2026-10-20,One,-1.00\n'),
      ),
      includeDuplicates: false,
    );
    expect(
      decodeHistory(await meta.read(AppMetaKeys.importHistory)).single.id,
      result.batch.id,
    );
  });
}
