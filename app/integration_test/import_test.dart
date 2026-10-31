// The CSV import on a device, in the demo flavor. Run on the harness's emulator with
//
//   tools/emulator_tests.sh integration -- integration_test/import_test.dart
//
// First the demo as main_demo.dart starts it: Settings, Import transactions, whatever is
// picked is the demo's sample export, mapped into a new manual account; its rows land as
// `import`, the account's balance on the Accounts tab is their sum, and "Undo this
// import" takes it back to zero. Then the demo started again with the fake picker holding
// a Chase export (the shape of test/features/import/fixtures/chase_checking.csv, written
// here since the test files are not on the device), imported into another new account
// whose balance moves by the file's total. Either test fails on a warning from the
// import's logger (a snapshot not written, a history not saved).
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/csv_picker_provider.dart';
import 'package:finance_tracker/core/platform/fake_backup_picker.dart';
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';

const String _chase =
    'Details,Posting Date,Description,Amount,Type,Balance,Check or Slip #\n'
    'DEBIT,10/28/2026,"NORTHWIND GROCERS #4411, SPRINGFIELD",-82.17,DEBIT_CARD,2417.83,,\n'
    'DEBIT,10/27/2026,CONTOSO COFFEE 0193,-4.75,DEBIT_CARD,2500.00,,\n'
    'CREDIT,10/25/2026,FABRIKAM INC PAYROLL PPD ID: 000111,1850.00,ACH_CREDIT,2504.75,,\n'
    'CHECK,10/22/2026,CHECK 1042,-120.00,CHECK_PAID,654.75,1042,\n'
    'DEBIT,10/20/2026,ADVENTURE WORKS FUEL,-41.30,DEBIT_CARD,774.75,,\n'
    'DEBIT,10/13/2026,CONTOSO COFFEE 0193,-4.75,DEBIT_CARD,816.05,,\n';

Finder _tab(String name) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(name));

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

// From Settings, through the mapping of [date], [description] and [amount] into a new
// manual account named [account], to the result.
Future<void> _import(
  WidgetTester tester, {
  required String date,
  required String description,
  required String amount,
  required String account,
}) async {
  await _tap(tester, _tab('Settings'));
  await _tap(tester, find.text('Import transactions'));
  await _tap(tester, find.text('Choose a CSV file'));
  await _choose(tester, 'Date', date);
  await _choose(tester, 'Description', description);
  await _choose(tester, 'Amount', amount);
  await _choose(tester, 'Import into', 'New manual account');
  await tester.enterText(find.widgetWithText(TextField, 'Name'), account);
  await tester.pumpAndSettle();
  // The keyboard down first: it covers the button while it closes.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await _tap(tester, find.text('Review'));
  await _tap(tester, find.textContaining(RegExp(r'^Import \d+ transaction')));
  expect(find.textContaining('into $account.'), findsOneWidget);
}

Future<(Account, List<Transaction>)> _stored(
  ProviderContainer container,
  String name,
) async {
  final Account account =
      (await container.read(accountRepositoryProvider).watchAll().first)
          .singleWhere((a) => a.name == name);
  final List<Transaction> rows = await container
      .read(transactionRepositoryProvider)
      .watch(TransactionQuery(accountIds: {account.id}))
      .first;
  return (account, rows);
}

Future<void> _expectBalance(
  WidgetTester tester,
  String account,
  Money balance,
) async {
  await _tap(tester, _tab('Accounts'));
  await _reveal(tester, find.text(account));
  final Finder card = find.ancestor(
    of: find.text(account),
    matching: find.byType(Card),
  );
  expect(
    find.descendant(of: card.first, matching: find.text(balance.format())),
    findsOneWidget,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final List<String> warnings = [];
  late StreamSubscription<LogRecord> logs;
  setUp(() {
    warnings.clear();
    logs = Logger.root.onRecord.listen((r) {
      if (r.loggerName == 'import' && r.level >= Level.WARNING) {
        warnings.add(r.message);
      }
    });
  });
  tearDown(() async {
    await logs.cancel();
    await stopApp();
    expect(warnings, isEmpty);
  });

  testWidgets('demo: the sample export into a new account, then undone', (
    tester,
  ) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );

    await _import(
      tester,
      date: 'Date',
      description: 'Description',
      amount: 'Amount',
      account: 'Sample checking',
    );
    final (Account account, List<Transaction> rows) = await _stored(
      container,
      'Sample checking',
    );
    expect(account.itemId, isNull);
    expect(rows, hasLength(16));
    expect(rows.every((t) => t.source == DataSource.import), isTrue);
    final Money total = Money.sum(
      rows.map((t) => t.amount),
      currencyCode: account.currencyCode,
    );
    expect(total.isZero, isFalse);
    await _expectBalance(tester, 'Sample checking', total);

    await _tap(tester, _tab('Settings'));
    await _tap(tester, find.text('Import transactions'));
    await _tap(tester, find.text('Undo this import'));
    await _tap(tester, find.text('Undo import'));
    expect((await _stored(container, 'Sample checking')).$2, isEmpty);
    await _expectBalance(
      tester,
      'Sample checking',
      Money.zero(account.currencyCode),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('demo: a Chase export through the fake picker', (tester) async {
    await setUpTimeZones();
    final List<Override> overrides = [
      for (final Override o in overridesFor(AppConfig.demo()))
        // ignore: invalid_use_of_visible_for_testing_member
        if (!identical(o.origin, csvPickerProvider)) o,
      csvPickerProvider.overrideWithValue(
        FakeBackupPicker(
          file: Uint8List.fromList(utf8.encode(_chase)),
          name: 'chase_checking.csv',
        ),
      ),
    ];
    await startApp(AppConfig.demo(), overrides: overrides);
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );

    await _import(
      tester,
      date: 'Posting Date',
      description: 'Description',
      amount: 'Amount',
      account: 'Old checking',
    );
    final (Account account, List<Transaction> rows) = await _stored(
      container,
      'Old checking',
    );
    expect(rows, hasLength(6));
    expect(rows.every((t) => t.source == DataSource.import), isTrue);
    await _expectBalance(
      tester,
      'Old checking',
      Money(159703, account.currencyCode),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
