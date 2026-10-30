// The accessibility baseline for every screen, in light and dark: tap targets are large
// enough and labelled, text has enough contrast, and nothing overflows at twice the text
// size. The shell's tabs and the linked banks are checked empty; every screen is also
// checked on the demo seed (two accounts, twelve transactions, the system categories, two
// rules, the three test budgets, the test streams, the test bills and the test goals)
// with the linked test data (the three test banks, two linked accounts, Plaid
// transactions), and the filter sheet, the category picker, the transaction list's menu
// and selection mode, the transaction editor's menu, the budget alerts sheet, the rule
// editor's menu and the apply confirmation, the subscriptions' folded sections, a
// stream's menu, the paused bills and the bill calendar open over their screens, the
// archived goals unfolded, the Reports' export sheet, and the editor's receipt (a photo
// from the fake image source) and its full-screen view. The forecast's chart, table and
// account sheet are checked on the forecast household through ForecastScreen, and the
// investments' allocation, value table, holdings and transactions on the test investments
// through InvestmentsScreen, with its empty state on the seed, and the net worth chart,
// table and liabilities on the net worth household through NetWorthScreen. The lock
// screen (the lock enabled in app_meta), the Security section of Settings and its "Lock
// after" dialog are checked on the fake device check. The sign-in
// and registration screens are checked signed out; their text scale is checked with their
// errors showing, in test/features/auth/auth_screens_test.dart.
import 'dart:io';

import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/fake_image_source.dart';
import 'package:finance_tracker/core/platform/image_source.dart';
import 'package:finance_tracker/core/platform/image_source_provider.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/bills/data/in_memory_bill_repository.dart';
import 'package:finance_tracker/features/lock/application/device_auth_provider.dart';
import 'package:finance_tracker/features/lock/data/fake_device_auth.dart';
import 'package:finance_tracker/features/transactions/presentation/receipt_view.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'helpers/bill_seed.dart';
import 'helpers/budget_seed.dart';
import 'helpers/forecast_seed.dart';
import 'helpers/goal_seed.dart';
import 'helpers/investment_seed.dart';
import 'helpers/net_worth_seed.dart';
import 'helpers/pump_app.dart';
import 'helpers/rule_seed.dart';
import 'helpers/seed.dart';
import 'helpers/stream_seed.dart';

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

// Scrolls the transaction editor to its receipt section and attaches a photo.
Future<void> _attachReceipt(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Take photo'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await _tapAndSettle(tester, find.text('Take photo'));
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
  'Transactions menu': (
    location: '/transactions',
    seeded: true,
    open: (tester) => _tapAndSettle(tester, find.byType(PopupMenuButton<void>)),
  ),
  'Duplicates': (
    location: '/transactions/duplicates',
    seeded: true,
    open: null,
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
  'Bills (empty)': (location: '/bills', seeded: false, open: null),
  'Bills': (location: '/bills', seeded: true, open: null),
  'Bills, paused open': (
    location: '/bills',
    seeded: true,
    open: (tester) async {
      await tester.scrollUntilVisible(
        find.text('Paused (1)'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await _tapAndSettle(tester, find.text('Paused (1)'));
    },
  ),
  'Bills calendar': (
    location: '/bills',
    seeded: true,
    open: (tester) => _tapAndSettle(tester, find.byTooltip('Calendar')),
  ),
  'New bill': (location: '/bills/new', seeded: true, open: null),
  'Forecast': (location: '/forecast', seeded: true, open: null),
  'Net worth': (location: '/net-worth', seeded: true, open: null),
  'Reports': (location: '/reports', seeded: true, open: null),
  'Weekly summary': (location: '/reports/weekly', seeded: true, open: null),
  'Reports, tables': (
    location: '/reports',
    seeded: true,
    open: (tester) => _tapAndSettle(tester, find.text('Tables')),
  ),
  'Reports export sheet': (
    location: '/reports',
    seeded: true,
    open: (tester) async {
      await _tapAndSettle(tester, find.byTooltip('Show menu'));
      await _tapAndSettle(tester, find.text('Export this month as PDF'));
    },
  ),
  'Export': (location: '/settings/export', seeded: true, open: null),
  'Backup': (location: '/settings/backup', seeded: false, open: null),
  'Devices': (location: '/settings/devices', seeded: false, open: null),
  'Delete account': (
    location: '/settings/delete-account',
    seeded: false,
    open: null,
  ),
  'Subscriptions': (location: '/bills/subscriptions', seeded: true, open: null),
  'Subscriptions, folded sections open': (
    location: '/bills/subscriptions',
    seeded: true,
    open: (tester) async {
      for (final String section in ['Muted (1)', 'Other recurring (1)']) {
        await tester.scrollUntilVisible(
          find.text(section),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await _tapAndSettle(tester, find.text(section));
      }
    },
  ),
  'Stream menu': (
    location: '/bills/subscriptions',
    seeded: true,
    open: (tester) =>
        _tapAndSettle(tester, find.byTooltip('Actions for Netflix')),
  ),
  'New bill from a stream': (
    location: '/bills/new?stream-id=stream-netflix',
    seeded: true,
    open: null,
  ),
  'Budget': (location: '/budgets/budget-food', seeded: true, open: null),
  'Budget transactions': (
    location: '/budgets/budget-food/transactions',
    seeded: true,
    open: null,
  ),
  'Transaction receipt': (
    location: '/transactions/demo-txn-04',
    seeded: true,
    open: _attachReceipt,
  ),
  'Receipt view': (
    location: '/transactions/demo-txn-04',
    seeded: true,
    open: (tester) async {
      await _attachReceipt(tester);
      await _tapAndSettle(
        tester,
        find.descendant(
          of: find.byType(ReceiptSection),
          matching: find.byType(Image),
        ),
      );
    },
  ),
  'Goals (empty)': (location: '/goals', seeded: false, open: null),
  'Goals': (location: '/goals', seeded: true, open: null),
  'Goals archived': (
    location: '/goals',
    seeded: true,
    open: (tester) async {
      await tester.scrollUntilVisible(
        find.text('Archived (1)'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await _tapAndSettle(tester, find.text('Archived (1)'));
    },
  ),
  'Goal (balance)': (location: '/goals/goal-fund', seeded: true, open: null),
  'Goal (contributions)': (
    location: '/goals/goal-trip',
    seeded: true,
    open: null,
  ),
  'New goal': (location: '/goals/new', seeded: true, open: null),
  'Edit goal': (location: '/goals/goal-trip/edit', seeded: true, open: null),
  'Add contribution': (
    location: '/goals/goal-trip/contribute',
    seeded: true,
    open: null,
  ),
  'Categories': (location: '/settings/categories', seeded: true, open: null),
  'Rules (empty)': (location: '/settings/rules', seeded: false, open: null),
  'Rules': (location: '/settings/rules', seeded: true, open: null),
  'New rule': (location: '/settings/rules/new', seeded: true, open: null),
  'Rule': (location: '/settings/rules/rule-every', seeded: true, open: null),
  'Rule menu': (
    location: '/settings/rules/rule-every',
    seeded: true,
    open: (tester) => _tapAndSettle(tester, find.byTooltip('More options')),
  ),
  'Rule apply dialog': (
    location: '/settings/rules',
    seeded: true,
    open: (tester) async {
      await _tapAndSettle(
        tester,
        find.byTooltip('More options for “Coffee on the card”'),
      );
      await _tapAndSettle(tester, find.text('Apply to existing transactions'));
    },
  ),
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
        streamsOverride(seededStreams()),
        billRepositoryProvider.overrideWithValue(
          InMemoryBillRepository(
            testClock,
            recorder: const NoChangeRecorder(),
            initial: testBills(),
          ),
        ),
        goalsOverride(),
        imageSourceProvider.overrideWithValue(
          FakeImageSource(
            () async => PickedImage(
              File('test/fixtures/receipts/plain.jpg').readAsBytesSync(),
            ),
          ),
        ),
      ]
    : const [];

/// The net worth screen's views: its chart, its table, and its liabilities scrolled to.
final Map<String, Future<void> Function(WidgetTester)?> _netWorthViews = {
  'Net worth chart': null,
  'Net worth table': (tester) => _tapAndSettle(tester, find.text('Table')),
  'Net worth liabilities': (tester) async {
    await tester.scrollUntilVisible(
      find.text('Enter payment'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  },
};

/// The forecast's views, opened from its chart.
final Map<String, Future<void> Function(WidgetTester)?> _forecastViews = {
  'Forecast chart': null,
  'Forecast table': (tester) => _tapAndSettle(tester, find.text('Table')),
  'Forecast accounts': (tester) =>
      _tapAndSettle(tester, find.byTooltip('Choose accounts')),
};

/// Scrolls the screen until [finder] is at the top.
Future<void> _scrollToTop(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder));
  await tester.pumpAndSettle();
}

/// The investments' views: the overrides they run on and what to do after they open.
final Map<
  String,
  ({
    List<Override> Function() overrides,
    Future<void> Function(WidgetTester)? open,
  })
>
_investmentsViews = {
  'Investments allocation': (overrides: investmentOverrides, open: null),
  'Investments value table': (
    overrides: investmentOverrides,
    open: (tester) async {
      await _scrollToTop(tester, find.text('Value over time'));
      await _tapAndSettle(tester, find.text('Table'));
    },
  ),
  'Investments holdings': (
    overrides: investmentOverrides,
    open: (tester) => _scrollToTop(tester, find.text('Holdings').first),
  ),
  'Investments transactions': (
    overrides: investmentOverrides,
    open: (tester) =>
        _scrollToTop(tester, find.text('Investment transactions').first),
  ),
  'Investments, empty': (
    overrides: () => [storeOverride(seededStore())],
    open: null,
  ),
};

/// The app_meta of a device whose lock is enabled.
InMemoryAppMetaStore _lockedMeta() =>
    InMemoryAppMetaStore()..write(AppMetaKeys.lockEnabled, 'true');

/// The lock's views: where each opens, its overrides, and what to do after it opens.
final Map<
  String,
  ({
    String location,
    List<Override> Function() overrides,
    Future<void> Function(WidgetTester)? open,
  })
>
_lockViews = {
  'Lock screen': (
    location: '/accounts',
    overrides: () => [
      appMetaStoreProvider.overrideWithValue(_lockedMeta()),
      deviceAuthProvider.overrideWithValue(FakeDeviceAuth()),
    ],
    open: null,
  ),
  'Security section': (
    location: '/settings',
    overrides: () => [deviceAuthProvider.overrideWithValue(FakeDeviceAuth())],
    open: (tester) async {
      await tester.scrollUntilVisible(
        find.text('Block screenshots'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    },
  ),
  'Lock after dialog': (
    location: '/settings',
    overrides: () => [
      appMetaStoreProvider.overrideWithValue(_lockedMeta()),
      deviceAuthProvider.overrideWithValue(FakeDeviceAuth()),
    ],
    open: (tester) async {
      await _tapAndSettle(tester, find.text('Unlock'));
      await tester.scrollUntilVisible(
        find.text('Lock after'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await _tapAndSettle(tester, find.text('Lock after'));
    },
  ),
};

/// The auth screens, which only a signed-out user sees.
const Map<String, String> _authScreens = {
  'Sign in': '/sign-in',
  'Register': '/register',
};

void main() {
  for (final MapEntry(key: String name, value: view) in _lockViews.entries) {
    for (final Brightness brightness in Brightness.values) {
      testWidgets('$name (${brightness.name}) meets the Android and contrast '
          'guidelines', (tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          await pumpApp(
            tester,
            initialLocation: view.location,
            brightness: brightness,
            overrides: view.overrides(),
          );
          await view.open?.call(tester);

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
        initialLocation: view.location,
        textScale: 2,
        overrides: view.overrides(),
      );
      await view.open?.call(tester);

      expect(tester.takeException(), isNull);
    });
  }

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

  for (final MapEntry(key: String name, value: open)
      in _forecastViews.entries) {
    for (final Brightness brightness in Brightness.values) {
      testWidgets('$name (${brightness.name}) meets the Android and contrast '
          'guidelines', (tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          await pumpApp(
            tester,
            brightness: brightness,
            overrides: forecastOverrides(),
            router: forecastRouter,
          );
          await open?.call(tester);

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
        textScale: 2,
        overrides: forecastOverrides(),
        router: forecastRouter,
      );
      await open?.call(tester);

      expect(tester.takeException(), isNull);
    });
  }

  for (final MapEntry(key: String name, value: view)
      in _investmentsViews.entries) {
    for (final Brightness brightness in Brightness.values) {
      testWidgets('$name (${brightness.name}) meets the Android and contrast '
          'guidelines', (tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          await pumpApp(
            tester,
            brightness: brightness,
            overrides: view.overrides(),
            router: investmentsRouter,
          );
          await view.open?.call(tester);

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
        textScale: 2,
        overrides: view.overrides(),
        router: investmentsRouter,
      );
      await view.open?.call(tester);

      expect(tester.takeException(), isNull);
    });
  }

  for (final MapEntry(key: String name, value: open)
      in _netWorthViews.entries) {
    for (final Brightness brightness in Brightness.values) {
      testWidgets('$name (${brightness.name}) meets the Android and contrast '
          'guidelines', (tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          await pumpApp(
            tester,
            brightness: brightness,
            overrides: netWorthOverrides(),
            router: netWorthRouter,
          );
          await open?.call(tester);

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
        textScale: 2,
        overrides: netWorthOverrides(),
        router: netWorthRouter,
      );
      await open?.call(tester);

      expect(tester.takeException(), isNull);
    });
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
