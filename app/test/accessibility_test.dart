// The accessibility baseline for every screen, in light and dark: tap targets are large
// enough and labelled, text has enough contrast, and nothing overflows at twice the text
// size. The shell's tabs are checked empty; every screen is also checked on the demo seed
// (two accounts, twelve transactions, the system categories), and the filter sheet and the
// category picker open over their screens.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';
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
  'Settings': (location: '/settings', seeded: false, open: null),
  'Accounts': (location: '/accounts', seeded: true, open: null),
  'Account detail': (
    location: '/accounts/$checkingId',
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
  'Categories': (location: '/settings/categories', seeded: true, open: null),
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

List<Override> _overrides(_Screen screen) =>
    screen.seeded ? [storeOverride(seededStore())] : const [];

void main() {
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
