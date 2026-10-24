// The account editor: the name is required; a new account gets the device locale's
// currency and an optional opening balance that becomes a manual transaction dated today
// (or the picked date); input with too many decimals is an error, never rounded; the
// currency is fixed once the account has transactions; edits are saved.
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/data/in_memory_account_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('a name is required', (tester) async {
    final InMemoryStore store = seededStore(seed: const DemoSeed.empty());
    await pumpApp(
      tester,
      initialLocation: '/accounts/new',
      overrides: [storeOverride(store)],
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a name'), findsOneWidget);
    expect(store.accounts(), isEmpty);
  });

  testWidgets('creates an account with its opening balance as a transaction', (
    tester,
  ) async {
    final InMemoryStore store = seededStore(seed: const DemoSeed.empty());
    await pumpApp(
      tester,
      initialLocation: '/accounts',
      overrides: [storeOverride(store)],
    );
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Name'), 'Wallet');
    await tester.tap(find.text('Other'));
    expect(find.text(r'USD ($)'), findsOneWidget);
    await tester.enterText(_field('Opening balance (optional)'), '1,250.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final Account account = store.accounts().single;
    expect(account.name, 'Wallet');
    expect(account.type, AccountType.other);
    expect(account.currencyCode, 'USD');
    expect(account.currentBalance, isNull);
    final Transaction opening = store.transactions(TransactionQuery.all).single;
    expect(opening.accountId, account.id);
    expect(opening.amount, Money(125050, 'USD'));
    expect(opening.name, 'Opening balance');
    expect(opening.source, DataSource.manual);
    expect(opening.date, testClock.today());
    expect(opening.createdAt, testClock.nowUtc());
    // Back on the list, with the derived balance.
    expect(find.text(r'$1,250.50'), findsOneWidget);
  });

  testWidgets('no opening balance, no transaction', (tester) async {
    final InMemoryStore store = seededStore(seed: const DemoSeed.empty());
    await pumpApp(
      tester,
      initialLocation: '/accounts/new',
      overrides: [storeOverride(store)],
    );

    await tester.enterText(_field('Name'), 'Empty');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(store.accounts(), hasLength(1));
    expect(store.transactions(TransactionQuery.all), isEmpty);
  });

  testWidgets('an over-precise opening balance is an error, not rounded', (
    tester,
  ) async {
    final InMemoryStore store = seededStore(seed: const DemoSeed.empty());
    await pumpApp(
      tester,
      initialLocation: '/accounts/new',
      overrides: [storeOverride(store)],
    );

    await tester.enterText(_field('Name'), 'Wallet');
    await tester.enterText(_field('Opening balance (optional)'), '10.005');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an amount such as 1,234.56'), findsOneWidget);
    expect(store.accounts(), isEmpty);
  });

  testWidgets('the opening balance date can be picked', (tester) async {
    final InMemoryStore store = seededStore(seed: const DemoSeed.empty());
    await pumpApp(
      tester,
      initialLocation: '/accounts/new',
      overrides: [storeOverride(store)],
    );

    await tester.enterText(_field('Name'), 'Wallet');
    await tester.enterText(_field('Opening balance (optional)'), '5');
    await tester.tap(find.text('Opening balance date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Oct 3, 2026'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      store.transactions(TransactionQuery.all).single.date,
      LocalDate(2026, 10, 3),
    );
  });

  testWidgets('the currency picker searches and sets the currency', (
    tester,
  ) async {
    final InMemoryStore store = seededStore(seed: const DemoSeed.empty());
    await pumpApp(
      tester,
      initialLocation: '/accounts/new',
      overrides: [storeOverride(store)],
    );

    await tester.tap(find.text('Currency'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'jp');
    await tester.pumpAndSettle();
    await tester.tap(find.text('JPY'));
    await tester.pumpAndSettle();
    expect(find.text('JPY (¥)'), findsOneWidget);

    await tester.enterText(_field('Name'), 'Yen');
    await tester.enterText(_field('Opening balance (optional)'), '1.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    // JPY has no minor unit: 1.5 is refused.
    expect(find.text('Enter an amount such as 1,234'), findsOneWidget);

    await tester.enterText(_field('Opening balance (optional)'), '1500');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.accounts().single.currencyCode, 'JPY');
    expect(
      store.transactions(TransactionQuery.all).single.amount,
      Money(1500, 'JPY'),
    );
  });

  testWidgets('an account with transactions keeps its currency; edits save', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    await pumpApp(
      tester,
      initialLocation: '/accounts/$checkingId',
      overrides: [storeOverride(store)],
    );
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit account'), findsOneWidget);
    expect(find.text('Opening balance (optional)'), findsNothing);
    expect(
      find.text(r"USD ($). It can't change once the account has transactions."),
      findsOneWidget,
    );
    final ListTile currency = tester.widget(
      find.widgetWithText(ListTile, 'Currency'),
    );
    expect(currency.enabled, isFalse);

    await tester.enterText(_field('Name'), 'Main checking');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(store.account(checkingId)!.name, 'Main checking');
    expect(find.widgetWithText(AppBar, 'Main checking'), findsOneWidget);
  });

  testWidgets('a refused create is reported and the editor stays', (
    tester,
  ) async {
    final InMemoryStore store = seededStore(seed: const DemoSeed.empty());
    await pumpApp(
      tester,
      initialLocation: '/accounts/new',
      overrides: [
        storeOverride(store),
        accountRepositoryProvider.overrideWith(
          (ref) => _RefusingAccountRepository(store),
        ),
      ],
    );

    await tester.enterText(_field('Name'), 'Wallet');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.text("The currency can't change: this account has transactions."),
      findsOneWidget,
    );
    expect(find.text('New account'), findsOneWidget);
    expect(store.accounts(), isEmpty);
  });
}

/// An account repository whose create always fails, as a refused write does.
final class _RefusingAccountRepository extends InMemoryAccountRepository {
  _RefusingAccountRepository(super.store)
    : super(recorder: const NoChangeRecorder());

  @override
  Future<void> create(Account account, {Transaction? openingBalance}) async =>
      throw const CurrencyMismatchException('USD', 'EUR');
}
