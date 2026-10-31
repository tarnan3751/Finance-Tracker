// The list beside its detail on an expanded window (core/layout/two_pane.dart): the
// Accounts, Transactions, Bills and Settings lists with what to choose beside them, a
// detail opened from the list replacing the one beside it, Back closing it, a deep link
// showing both, another tab's detail opening beside the list it was opened from, the
// Plan tab's other segments and the compact window unchanged, and a window that changes
// class keeping the detail open.
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/layout/two_pane.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/presentation/account_detail_screen.dart';
import 'package:finance_tracker/features/accounts/presentation/accounts_screen.dart';
import 'package:finance_tracker/features/bills/data/in_memory_bill_repository.dart';
import 'package:finance_tracker/features/bills/presentation/bill_editor_screen.dart';
import 'package:finance_tracker/features/bills/presentation/bills_screen.dart';
import 'package:finance_tracker/features/categories/presentation/categories_screen.dart';
import 'package:finance_tracker/features/settings/presentation/settings_screen.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_tile.dart';
import 'package:finance_tracker/features/transactions/presentation/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/bill_seed.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

Finder _inStart(Finder finder) => find.descendant(
  of: find.byWidgetPredicate((w) => w is PaneScope && w.role == PaneRole.start),
  matching: finder,
);

Finder _inEnd(Finder finder) => find.descendant(
  of: find.byWidgetPredicate((w) => w is PaneScope && w.role == PaneRole.end),
  matching: finder,
);

/// The transaction list's rows, the vertical scrollable (the search field has one too).
final Finder _rows = find.descendant(
  of: find.byType(TransactionsScreen),
  matching: find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  ),
);

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first)).state.uri.path;

Future<void> _pump(
  WidgetTester tester, {
  String location = '/accounts',
  Size size = expandedSize,
}) => pumpApp(
  tester,
  initialLocation: location,
  size: size,
  overrides: [
    storeOverride(seededStore()),
    billRepositoryProvider.overrideWithValue(
      InMemoryBillRepository(
        testClock,
        recorder: const NoChangeRecorder(),
        initial: testBills(),
      ),
    ),
  ],
);

void main() {
  testWidgets('the accounts with what to choose beside them', (tester) async {
    await _pump(tester);

    expect(_inStart(find.byType(AccountsScreen)), findsOneWidget);
    expect(_inEnd(find.text('Choose an account to see it here')), findsOne);
    expect(find.byType(AccountsScreen), findsOneWidget);
  });

  testWidgets(
    'a screen reader reads the list, then the detail, then the rail',
    (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await _pump(tester, location: '/accounts/$checkingId');

        final List<String> labels = [
          for (final SemanticsNode node
              in tester.semantics.simulatedAccessibilityTraversal())
            node.label,
        ];
        final int list = labels.indexOf('Accounts');
        final int detail = labels.indexWhere(
          (l) => l.contains('Running balance'),
        );
        final int rail = labels.indexWhere((l) => l.startsWith('Settings\n'));
        expect(list, isNonNegative, reason: 'the list is read');
        expect(detail, greaterThan(list));
        expect(rail, greaterThan(detail));
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('an account opens beside the list, another replaces it, and Back '
      'closes it', (tester) async {
    await _pump(tester);

    final Finder cards = _inStart(find.byType(Card));
    await tester.tap(cards.first);
    await tester.pumpAndSettle();
    expect(_inEnd(find.byType(AccountDetailScreen)), findsOneWidget);
    expect(_inStart(find.byType(AccountsScreen)), findsOneWidget);
    final String first = _location(tester);
    expect(first, startsWith('/accounts/'));

    await tester.tap(cards.at(1));
    await tester.pumpAndSettle();
    final String second = _location(tester);
    expect(second, isNot(first));
    expect(find.byType(AccountDetailScreen), findsOneWidget);

    await tester.tap(_inEnd(find.byType(BackButton)));
    await tester.pumpAndSettle();
    expect(_location(tester), '/accounts');
    expect(find.byType(AccountDetailScreen), findsNothing);
    expect(_inEnd(find.text('Choose an account to see it here')), findsOne);
  });

  testWidgets('a deep link to an account shows the list and the account', (
    tester,
  ) async {
    await _pump(tester, location: '/accounts/$checkingId');

    expect(_inStart(find.byType(AccountsScreen)), findsOneWidget);
    expect(_inEnd(find.byType(AccountDetailScreen)), findsOneWidget);
    expect(
      _inStart(find.byType(BackButton)),
      findsNothing,
      reason: 'the list is not a page to go back from',
    );
  });

  testWidgets("an account's transaction opens beside the accounts", (
    tester,
  ) async {
    await _pump(tester, location: '/accounts/$checkingId');

    await tester.tap(_inEnd(find.byType(TransactionTile)).first);
    await tester.pumpAndSettle();
    expect(_inEnd(find.byType(TransactionEditorScreen)), findsOneWidget);
    expect(_inStart(find.byType(AccountsScreen)), findsOneWidget);
    expect(find.byType(TransactionsScreen), findsNothing);

    await tester.tap(_inEnd(find.byType(BackButton)));
    await tester.pumpAndSettle();
    expect(_inEnd(find.byType(AccountDetailScreen)), findsOneWidget);
  });

  testWidgets('a transaction and a new one open beside the transactions', (
    tester,
  ) async {
    await _pump(tester, location: '/transactions');
    expect(_inEnd(find.text('Choose a transaction to see it here')), findsOne);

    await tester.tap(_inStart(find.byType(TransactionTile)).first);
    await tester.pumpAndSettle();
    expect(_inEnd(find.byType(TransactionEditorScreen)), findsOneWidget);

    await tester.tap(_inStart(find.byType(FloatingActionButton)));
    await tester.pumpAndSettle();
    expect(_location(tester), '/transactions/new');
    expect(_inEnd(find.byType(TransactionEditorScreen)), findsOneWidget);
    expect(_inStart(find.byType(TransactionsScreen)), findsOneWidget);
  });

  testWidgets('a bill opens beside the bills; the budgets fill the tab', (
    tester,
  ) async {
    await _pump(tester, location: '/bills');
    expect(_inStart(find.byType(BillsScreen)), findsOneWidget);
    expect(_inEnd(find.text('Choose a bill to edit it here')), findsOne);

    await tester.tap(_inStart(find.byType(ListTile)).first);
    await tester.pumpAndSettle();
    expect(_inEnd(find.byType(BillEditorScreen)), findsOneWidget);

    await tester.tap(_inStart(find.text('Budgets')));
    await tester.pumpAndSettle();
    expect(find.byType(PaneScope), findsNothing);
    expect(find.byType(BillsScreen), findsNothing);
  });

  testWidgets('a setting opens beside the settings', (tester) async {
    await _pump(tester, location: '/settings');
    expect(_inEnd(find.text('Choose a setting to open it here')), findsOne);

    await tester.scrollUntilVisible(
      _inStart(find.text('Categories')),
      200,
      scrollable: _inStart(find.byType(Scrollable)).first,
    );
    await tester.ensureVisible(_inStart(find.text('Categories')));
    await tester.pumpAndSettle();
    await tester.tap(_inStart(find.text('Categories')));
    await tester.pumpAndSettle();
    expect(_inEnd(find.byType(CategoriesScreen)), findsOneWidget);
    expect(_inStart(find.byType(SettingsScreen)), findsOneWidget);
    expect(_location(tester), '/settings/categories');
  });

  for (final (String name, Size size) in [
    ('compact', phoneSize),
    ('medium', mediumSize),
  ]) {
    testWidgets('a $name window pushes the detail over the list', (
      tester,
    ) async {
      await _pump(tester, location: '/accounts/$checkingId', size: size);

      expect(find.byType(PaneScope), findsNothing);
      expect(find.byType(AccountDetailScreen), findsOneWidget);
      expect(find.byType(AccountsScreen), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(AccountsScreen), findsOneWidget);
    });
  }

  testWidgets('the list keeps its search and its scroll across classes', (
    tester,
  ) async {
    // Short windows, so the list scrolls in each class.
    await _pump(tester, location: '/transactions', size: const Size(412, 360));

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pumpAndSettle();
    final ScrollableState list = tester.state(_rows);
    list.position.jumpTo(40);
    await tester.pump();
    final State<StatefulWidget> before = tester.state(
      find.byType(TransactionsScreen),
    );

    for (final Size size in const [
      Size(900, 360),
      Size(412, 360),
      Size(900, 360),
    ]) {
      tester.view.physicalSize = size * tester.view.devicePixelRatio;
      await tester.pumpAndSettle();
      expect(
        tester.state(find.byType(TransactionsScreen)),
        same(before),
        reason: 'one list element in every class',
      );
      final TextField field = tester.widget(
        find.descendant(
          of: find.byType(TransactionsScreen),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, 'a');
      final ScrollableState now = tester.state(_rows);
      expect(now.position.pixels, 40);
    }
    expect(_inStart(find.byType(TransactionsScreen)), findsOneWidget);
  });

  testWidgets('a snack bar shows once, in the pane that showed it', (
    tester,
  ) async {
    await _pump(tester, location: '/accounts/$checkingId');

    ScaffoldMessenger.of(tester.element(find.byType(AccountDetailScreen)))
        .showSnackBar(const SnackBar(content: Text('From the detail')));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(_inEnd(find.byType(SnackBar)), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(AccountDetailScreen)))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();

    ScaffoldMessenger.of(tester.element(find.byType(AccountsScreen)))
        .showSnackBar(const SnackBar(content: Text('From the list')));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(_inStart(find.byType(SnackBar)), findsOneWidget);
  });

  testWidgets('the linked banks replace the account beside the accounts', (
    tester,
  ) async {
    await _pump(tester, location: '/accounts/$checkingId');
    await tester.tap(_inStart(find.byTooltip('Linked banks')));
    await tester.pumpAndSettle();
    expect(_location(tester), '/accounts/linked-banks');
    await tester.tap(_inEnd(find.byType(BackButton)));
    await tester.pumpAndSettle();
    expect(_location(tester), '/accounts', reason: 'it replaced the account');
  });

  testWidgets("another tab's page opens beside the list it was opened from", (
    tester,
  ) async {
    await _pump(tester, location: '/settings/categories');
    await tester.tap(_inStart(find.text('Linked banks')));
    await tester.pumpAndSettle();
    expect(_location(tester), '/accounts/linked-banks');
    expect(_inStart(find.byType(SettingsScreen)), findsOneWidget);
    await tester.tap(_inEnd(find.byType(BackButton)));
    await tester.pumpAndSettle();
    expect(
      _location(tester),
      '/settings',
      reason: 'it replaced the categories',
    );
    expect(_inEnd(find.text('Choose a setting to open it here')), findsOne);
  });

  testWidgets("another tab's page opened twice in one frame opens once", (
    tester,
  ) async {
    await _pump(tester, location: '/settings/categories');
    await tester.scrollUntilVisible(
      _inStart(find.text('Linked banks')),
      200,
      scrollable: _inStart(find.byType(Scrollable)).first,
    );
    final BuildContext list = tester.element(
      _inStart(find.text('Linked banks')),
    );
    openDetail(list, '/accounts/linked-banks');
    openDetail(list, '/accounts/linked-banks');
    await tester.pumpAndSettle();
    expect(_location(tester), '/accounts/linked-banks');

    await tester.tap(_inEnd(find.byType(BackButton)));
    await tester.pumpAndSettle();
    expect(_location(tester), '/settings', reason: 'the page was pushed once');
  });

  testWidgets('a rail that leaves too little room shows one pane', (
    tester,
  ) async {
    // An expanded window just wide enough, the rail's labels at twice the text size.
    await pumpApp(
      tester,
      initialLocation: '/accounts/$checkingId',
      size: foldSize,
      textScale: 2,
      overrides: [storeOverride(seededStore())],
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(PaneScope), findsNothing);
    expect(find.byType(AccountDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a window that changes class keeps the detail open', (
    tester,
  ) async {
    await _pump(tester, location: '/accounts/$checkingId');

    tester.view.physicalSize = phoneSize * tester.view.devicePixelRatio;
    await tester.pumpAndSettle();
    expect(find.byType(AccountDetailScreen), findsOneWidget);
    expect(find.byType(AccountsScreen), findsNothing);

    tester.view.physicalSize = expandedSize * tester.view.devicePixelRatio;
    await tester.pumpAndSettle();
    expect(_inEnd(find.byType(AccountDetailScreen)), findsOneWidget);
    expect(_inStart(find.byType(AccountsScreen)), findsOneWidget);
  });
}
