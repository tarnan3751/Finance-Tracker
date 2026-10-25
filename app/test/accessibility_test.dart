// The accessibility baseline for every screen, in light and dark: tap targets are large
// enough and labelled, text has enough contrast, and nothing overflows at twice the text
// size. The shell's tabs and the linked banks are checked empty; every screen is also
// checked on the demo seed (two accounts, twelve transactions, the system categories, two
// rules and the three test budgets) with the linked test data (the three test banks, two
// linked accounts, Plaid transactions), and the filter sheet, the category picker, the
// transaction editor's menu, the budget alerts sheet and the transaction list's
// selection mode open over their screens. The sign-in and registration screens are
// checked signed out; their text scale is checked with their errors showing, in
// test/features/auth/auth_screens_test.dart.
import 'package:finance_tracker/features/transactions/presentation/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'helpers/budget_seed.dart';
import 'helpers/pump_app.dart';
import 'helpers/rule_seed.dart';
import 'helpers/seed.dart';

/// A screen to check: where it is, whether it runs on the seed, and what to do after it
/// opens (open a sheet or a picker).
typedef _Screen = ({
  String location,
  bool seeded,
  Future<void> Function(WidgetTester)? open,
});

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

final Map<String, _Screen> _screens = {
  'Accounts (empty)': (location: '/accounts', seeded: false, open: null),
  'Transactions (empty)': (
    location: '/transactions',
    seeded: false,
    open: null,
  ),
  'Budgets (empty)': (location: '/budgets', seeded: false, open: null),
  'Settings': (location: '/settings', seeded: false, open: null),
  'Linked banks (empty)': (
    location: '/accounts/linked-banks',
    seeded: false,
    open: null,
  ),
  'Linked banks': (
    location: '/accounts/linked-banks',
    seeded: true,
    open: null,
  ),
  'Unlink dialog': (
    location: '/accounts/linked-banks',
    seeded: true,
    open: (tester) => _tapAndSettle(tester, find.text('Unlink').first),
  ),
  'Accounts': (location: '/accounts', seeded: true, open: null),
  'Account detail': (
    location: '/accounts/$checkingId',
    seeded: true,
    open: null,
  ),
  'Linked account detail': (
    location: '/accounts/$linkedCheckingId',
    seeded: true,
    open: null,
  ),
  'New account': (location: '/accounts/new', seeded: true, open: null),
  'Edit account': (
    location: '/accounts/$checkingId/edit',
    seeded: true,
    open: null,
  ),
  'Transactions': (location: '/transactions', seeded: true, open: null),
  'Transactions, selecting': (
    location: '/transactions',
    seeded: true,
    open: (tester) async {
      await tester.longPress(find.byType(TransactionTile).first);
      await tester.pumpAndSettle();
    },
  ),
  'Filter sheet': (
    location: '/transactions',
    seeded: true,
    open: (tester) => _tapAndSettle(tester, find.byTooltip('Filters')),
  ),
  'New transaction': (location: '/transactions/new', seeded: true, open: null),
  'Transaction': (
    location: '/transactions/demo-txn-04',
    seeded: true,
    open: null,
  ),
  'Category picker': (
    location: '/transactions/demo-txn-04',
    seeded: true,
    open: (tester) => _tapAndSettle(tester, find.text('Category')),
  ),
  'Budgets': (location: '/budgets', seeded: true, open: null),
  'Past budgets': (
    location: '/budgets',
    seeded: true,
    open: (tester) => _tapAndSettle(tester, find.byTooltip('Previous period')),
  ),
  'Future budgets': (
    location: '/budgets',
    seeded: true,
    open: (tester) => _tapAndSettle(tester, find.byTooltip('Next period')),
  ),
  'Alerts sheet': (location: '/budgets', seeded: true, open: openTestAlerts),
  'New budget': (location: '/budgets/new', seeded: true, open: null),
  'Budget': (location: '/budgets/budget-food', seeded: true, open: null),
  'Budget transactions': (
    location: '/budgets/budget-food/transactions',
    seeded: true,
    open: null,
  ),
  'Categories': (location: '/settings/categories', seeded: true, open: null),
  'Rules (empty)': (location: '/settings/rules', seeded: false, open: null),
  'Rules': (location: '/settings/rules', seeded: true, open: null),
  'New rule': (location: '/settings/rules/new', seeded: true, open: null),
  'Rule': (location: '/settings/rules/rule-every', seeded: true, open: null),
  'Transaction menu': (
    location: '/transactions/demo-txn-04',
    seeded: true,
    open: (tester) => _tapAndSettle(tester, find.byTooltip('More options')),
  ),
  'New category': (
    location: '/settings/categories/new',
    seeded: true,
    open: null,
  ),
  'System category': (
    location: '/settings/categories/plaid:FOOD_AND_DRINK',
    seeded: true,
    open: null,
  ),
};

List<Override> _overrides(_Screen screen) => screen.seeded
    ? [
        storeOverride(linkedStore(manual: true)),
        rulesOverride(seededRules()),
        budgetsOverride(seededBudgets()),
      ]
    : const [];

/// The auth screens, which only a signed-out user sees.
const Map<String, String> _authScreens = {
  'Sign in': '/sign-in',
  'Register': '/register',
};

void main() {
  for (final MapEntry(key: String name, value: String location)
      in _authScreens.entries) {
    for (final Brightness brightness in Brightness.values) {
      testWidgets('$name (${brightness.name}) meets the Android and contrast '
          'guidelines', (tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          await pumpApp(
            tester,
            initialLocation: location,
            brightness: brightness,
            signedIn: false,
          );
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  for (final MapEntry(key: String name, value: _Screen screen)
      in _screens.entries) {
    for (final Brightness brightness in Brightness.values) {
      testWidgets('$name (${brightness.name}) meets the Android and contrast '
          'guidelines', (tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        // Disposed in `finally`, not through addTearDown: flutter_test checks for live
        // semantics handles before tear-downs run, so a failing guideline would add a
        // leak failure on top of its own.
        try {
          await pumpApp(
            tester,
            initialLocation: screen.location,
            brightness: brightness,
            overrides: _overrides(screen),
          );
          await screen.open?.call(tester);

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        } finally {
          semantics.dispose();
        }
      });
    }

    testWidgets('$name lays out at text scale 2.0 without overflow', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialLocation: screen.location,
        textScale: 2,
        overrides: _overrides(screen),
      );
      await screen.open?.call(tester);

      expect(tester.takeException(), isNull);
      expect(
        MediaQuery.textScalerOf(tester.element(find.byType(Scaffold).last))
            .scale(10),
        20,
      );
    });
  }
}
