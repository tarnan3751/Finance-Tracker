// The import flow on the test seed, as of 24 October 2026: Settings opens it; a Chase
// export is picked (the fake picker), its columns mapped, reviewed and imported into
// the checking account, and lands there as `import` rows; the same header again is
// mapped by its preset and every row is a likely duplicate, skipped until the switch
// says otherwise; the undo asks first and deletes the rows; ambiguous dates are shown
// read both ways; back steps back through the flow; the transaction list's menu opens
// it too; an imported row says so in the editor; and a file too large, unopenable, not
// text, or with no table is told.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/backup_picker.dart';
import 'package:finance_tracker/core/platform/csv_picker_provider.dart';
import 'package:finance_tracker/core/platform/fake_backup_picker.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/util/stream_current.dart';
import 'package:finance_tracker/features/import/application/import_providers.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';
import '../fixtures.dart';

late InMemoryStore _store;

/// The in-memory transactions, whose queries fail while [failing].
final class _FailingQueries extends InMemoryTransactionRepository {
  _FailingQueries(super.store) : super(recorder: const NoChangeRecorder());

  bool failing = false;

  @override
  Stream<List<Transaction>> watch(TransactionQuery query) => failing
      ? Stream<List<Transaction>>.error(StateError('the database closed'))
      : super.watch(query);
}

/// A picker whose file's reads wait for [release].
final class _HeldPicker implements BackupPicker {
  _HeldPicker(this.bytes);

  final Uint8List bytes;
  final Completer<void> release = Completer<void>();
  int closed = 0;

  @override
  Future<PickedFile?> pick() async => _HeldFile(this);
}

final class _HeldFile implements PickedFile {
  _HeldFile(this._picker);

  final _HeldPicker _picker;

  @override
  String? get name => 'held.csv';

  @override
  int get length => _picker.bytes.length;

  @override
  Future<Uint8List> read([int start = 0, int? end]) async {
    await _picker.release.future;
    return Uint8List.sublistView(_picker.bytes, start, end);
  }

  @override
  Future<void> close() async => _picker.closed++;
}

Future<FakeBackupPicker> _open(
  WidgetTester tester, {
  Uint8List? file,
  String name = 'chase_checking.csv',
  String location = '/settings/import',
}) async {
  final FakeBackupPicker picker = FakeBackupPicker(
    file: file ?? importFixture('chase_checking.csv'),
    name: name,
  );
  await pumpApp(
    tester,
    overrides: [
      storeOverride(_store),
      csvPickerProvider.overrideWithValue(picker),
    ],
    initialLocation: location,
  );
  return picker;
}

// Scrolls the screen's list until [finder] is built (the list builds lazily).
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(
          of: find.byType(Scaffold).last,
          matching: find.byType(Scrollable),
        )
        .first,
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

// Opens the dropdown labelled [label] and picks the option whose text starts with
// [option].
Future<void> _choose(WidgetTester tester, String label, String option) async {
  await _reveal(tester, find.text(label));
  await _tap(
    tester,
    find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is DropdownButtonFormField),
    ),
  );
  await tester.tap(find.textContaining(option).last);
  await tester.pumpAndSettle();
}

Future<void> _mapChase(WidgetTester tester) async {
  await _choose(tester, 'Date', 'Posting Date');
  await _choose(tester, 'Description', 'Description');
  await _choose(tester, 'Amount', 'Amount');
  await _choose(tester, 'Import into', 'Everyday Checking');
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

Future<List<Transaction>> _imported(WidgetTester tester) async => [
  for (final Transaction t in await currentValue(
    _container(tester)
        .read(transactionRepositoryProvider)
        .watch(TransactionQuery()),
  ))
    if (t.source == DataSource.import) t,
];

void main() {
  setUp(() => _store = seededStore());
  tearDown(() => _store.close());

  testWidgets('Settings opens the import', (tester) async {
    await _open(tester, location: '/settings');
    await tester.scrollUntilVisible(
      find.text('Import transactions'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await _tap(tester, find.text('Import transactions'));
    expect(find.text('Choose a CSV file'), findsOneWidget);
    expect(find.text('Nothing imported yet'), findsOneWidget);
  });

  testWidgets('pick, map, review and import a Chase export', (tester) async {
    final FakeBackupPicker picker = await _open(tester);
    await _tap(tester, find.text('Choose a CSV file'));
    expect(picker.closed, 1);
    await _reveal(tester, find.text('Review'));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Review'))
          .onPressed,
      isNull,
    );
    await _mapChase(tester);
    expect(find.text('MM/dd/yyyy'), findsOneWidget);
    await _tap(tester, find.text('Review'));

    expect(find.text('6 transactions to import'), findsOneWidget);
    expect(find.text('From Oct 13, 2026 to Oct 28, 2026'), findsOneWidget);
    expect(find.text(r'$1,850.00'), findsWidgets);
    await _tap(tester, find.text('Import 6 transactions'));

    expect(
      find.text('Imported 6 transactions into Everyday Checking.'),
      findsOneWidget,
    );
    final List<Transaction> rows = await _imported(tester);
    expect(rows, hasLength(6));
    expect(rows.map((t) => t.accountId).toSet(), {checkingId});
    expect(find.text('chase_checking.csv'), findsOneWidget);
    expect(find.text('6 transactions, Oct 24, 2026'), findsOneWidget);
    expect(find.text('Undo this import'), findsOneWidget);
  });

  testWidgets('the preset and the duplicates switch on a second import', (
    tester,
  ) async {
    await _open(tester);
    await _tap(tester, find.text('Choose a CSV file'));
    await _mapChase(tester);
    await _tap(tester, find.text('Review'));
    await _tap(tester, find.text('Import 6 transactions'));
    await _tap(tester, find.text('Import another file'));

    await _tap(tester, find.text('Choose a CSV file'));
    expect(
      find.text('Mapped as you mapped this layout last time.'),
      findsOneWidget,
    );
    await _tap(tester, find.text('Review'));
    expect(find.text('No transactions to import'), findsOneWidget);
    expect(find.text('You have imported this file before.'), findsOneWidget);
    expect(find.text('Likely duplicate'), findsWidgets);
    final Finder import0 = find.widgetWithText(
      FilledButton,
      'Import 0 transactions',
    );
    expect(tester.widget<FilledButton>(import0).onPressed, isNull);
    await _tap(tester, find.text('Import 6 likely duplicates anyway'));
    await _tap(tester, find.text('Import 6 transactions'));
    expect(await _imported(tester), hasLength(12));
  });

  testWidgets('undo asks first, then deletes the rows', (tester) async {
    await _open(tester);
    await _tap(tester, find.text('Choose a CSV file'));
    await _mapChase(tester);
    await _tap(tester, find.text('Review'));
    await _tap(tester, find.text('Import 6 transactions'));

    await _tap(tester, find.text('Undo this import'));
    expect(
      find.text(
        'This deletes the 6 transactions this import added, including any '
        'you have edited since.',
      ),
      findsOneWidget,
    );
    await _tap(tester, find.text('Cancel'));
    expect(await _imported(tester), hasLength(6));
    await _tap(tester, find.text('Undo this import'));
    await _tap(tester, find.text('Undo import'));
    expect(find.text('Import undone'), findsOneWidget);
    expect(await _imported(tester), isEmpty);
    expect(find.text('6 transactions, Oct 24, 2026, undone'), findsOneWidget);
    expect(find.text('Undo this import'), findsNothing);
  });

  testWidgets('ambiguous dates are shown both ways; back steps back', (
    tester,
  ) async {
    await _open(
      tester,
      file: Uint8List.fromList(
        utf8.encode(
          'Date,Name,Amount\n03/10/2026,Coffee,-3.20\n04/10/2026,Pay,2100.00\n',
        ),
      ),
    );
    await _tap(tester, find.text('Choose a CSV file'));
    await _choose(tester, 'Date', 'Date');
    expect(
      find.text(
        'These dates can be read two ways. Choose the one your bank uses.',
      ),
      findsOneWidget,
    );
    expect(find.text('03/10/2026 is Mar 10, 2026'), findsOneWidget);
    expect(find.text('03/10/2026 is Oct 3, 2026'), findsOneWidget);
    await _tap(tester, find.text('dd/MM/yyyy'));
    await _choose(tester, 'Description', 'Name');
    await _choose(tester, 'Amount', 'Amount');
    await _choose(tester, 'Import into', 'Everyday Checking');
    await _tap(tester, find.text('Review'));
    expect(find.text('From Oct 3, 2026 to Oct 4, 2026'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _reveal(tester, find.text('Review'));
    expect(find.text('Review'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Choose a CSV file'), findsOneWidget);
  });

  testWidgets('a header past the twentieth row is offered', (tester) async {
    final String preamble = [for (int i = 0; i < 25; i++) 'Note $i\n'].join();
    await _open(
      tester,
      file: Uint8List.fromList(
        utf8.encode('${preamble}Date,Name,Amount\n2026-10-01,Coffee,-3.20\n'),
      ),
    );
    await _tap(tester, find.text('Choose a CSV file'));
    expect(find.text('Row 26: Date,Name,Amount'), findsOneWidget);
  });

  testWidgets('back is held while the file is read; a read that ends after '
      'the screen is gone is dropped', (tester) async {
    final _HeldPicker picker = _HeldPicker(importFixture('chase_checking.csv'));
    await pumpApp(
      tester,
      overrides: [
        storeOverride(_store),
        csvPickerProvider.overrideWithValue(picker),
      ],
      initialLocation: '/settings/import',
    );
    await tester.tap(find.text('Choose a CSV file'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    expect(find.text('Choose a CSV file'), findsOneWidget);

    GoRouter.of(tester.element(find.text('Choose a CSV file'))).go('/settings');
    await tester.pumpAndSettle();
    expect(find.text('Choose a CSV file'), findsNothing);
    picker.release.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(picker.closed, 1);
  });

  testWidgets('a review that fails is told, and back works again', (
    tester,
  ) async {
    final _FailingQueries transactions = _FailingQueries(_store);
    await pumpApp(
      tester,
      overrides: [
        storeOverride(_store),
        csvPickerProvider.overrideWithValue(
          FakeBackupPicker(file: importFixture('chase_checking.csv')),
        ),
        transactionRepositoryProvider.overrideWithValue(transactions),
      ],
      initialLocation: '/settings/import',
    );
    await _tap(tester, find.text('Choose a CSV file'));
    await _mapChase(tester);
    transactions.failing = true;
    await _tap(tester, find.text('Review'));
    expect(
      find.text(
        'The rows could not be read for review. Try again, or go back and '
        'choose another file.',
      ),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('6 transactions to import'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Choose a CSV file'), findsOneWidget);
  });

  testWidgets('a new manual account', (tester) async {
    await _open(tester);
    await _tap(tester, find.text('Choose a CSV file'));
    await _choose(tester, 'Date', 'Posting Date');
    await _choose(tester, 'Description', 'Description');
    await _choose(tester, 'Amount', 'Amount');
    await _choose(tester, 'Import into', 'New manual account');
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Old bank');
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Review'));
    await _tap(tester, find.text('Import 6 transactions'));
    expect(find.text('Imported 6 transactions into Old bank.'), findsOneWidget);
    final List<Account> accounts = await currentValue(
      _container(tester).read(accountRepositoryProvider).watchAll(),
    );
    final Account created = accounts.singleWhere((a) => a.name == 'Old bank');
    expect(created.itemId, isNull);
    expect((await _imported(tester)).map((t) => t.accountId).toSet(), {
      created.id,
    });
  });

  testWidgets('the transaction list menu opens the import', (tester) async {
    await _open(tester, location: '/transactions');
    await _tap(tester, find.byIcon(Icons.more_vert));
    await _tap(tester, find.text('Import transactions'));
    expect(find.text('Choose a CSV file'), findsOneWidget);
  });

  testWidgets('an imported transaction says so in the editor', (tester) async {
    final DateTime at = testClock.nowUtc();
    _store.upsertTransaction(
      Transaction(
        id: 'imported-1',
        accountId: checkingId,
        amount: Money(-475, 'USD'),
        date: testClock.today(),
        pending: false,
        name: 'CONTOSO COFFEE',
        source: DataSource.import,
        createdAt: at,
        updatedAt: at,
        syncVersion: 0,
      ),
    );
    await _open(tester, location: '/transactions/imported-1');
    expect(find.text('Imported from a file'), findsOneWidget);
  });

  testWidgets('a manual transaction carries no caption', (tester) async {
    _store.upsertTransaction(testTransaction('manual-1'));
    await _open(tester, location: '/transactions/manual-1');
    expect(find.text('Imported from a file'), findsNothing);
  });

  group('failures are told', () {
    Future<void> pickWith(
      WidgetTester tester,
      BackupPicker picker,
      String message,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          storeOverride(_store),
          csvPickerProvider.overrideWithValue(picker),
        ],
        initialLocation: '/settings/import',
      );
      await _tap(tester, find.text('Choose a CSV file'));
      expect(find.text(message), findsOneWidget);
      expect(find.text('Choose a CSV file'), findsOneWidget);
    }

    testWidgets('too large', (tester) async {
      await pickWith(
        tester,
        FakeBackupPicker(file: Uint8List(1), length: maxImportBytes + 1),
        'This file is over 20 MB, more than an import reads.',
      );
    });

    testWidgets('not opened', (tester) async {
      await pickWith(
        tester,
        FakeBackupPicker(failure: const BackupPickFailedException()),
        'The file could not be opened.',
      );
    });

    testWidgets('not text', (tester) async {
      await pickWith(
        tester,
        FakeBackupPicker(
          file: Uint8List.fromList([0xEF, 0xBB, 0xBF, 0xC3, 0x28, 0x2C]),
        ),
        'The file could not be read as text.',
      );
    });

    testWidgets('no table', (tester) async {
      await pickWith(
        tester,
        FakeBackupPicker(
          file: Uint8List.fromList(utf8.encode('just,one\nline,here\n')),
        ),
        'No table of transactions was found in this file.',
      );
    });
  });
}
