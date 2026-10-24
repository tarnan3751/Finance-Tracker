// Goldens of the Phase 1 screens, light and dark at phone size, on the demo seed (two USD
// accounts, twelve transactions, the system categories) dated to the test clock: the
// account list (with data and empty), an account's detail, the transaction list, the
// transaction editor, the filter sheet, the category list and the category editor. Tagged
// `golden`; see test/flutter_test_config.dart for where the files go and how to update
// them.
import 'package:alchemist/alchemist.dart';
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import '../helpers/seed.dart';

Widget _app(String location, Brightness brightness, {DemoSeed? seed}) =>
    SizedBox.fromSize(
      size: phoneSize,
      child: buildTestApp(
        initialLocation: location,
        brightness: brightness,
        overrides: [storeOverride(seededStore(seed: seed))],
      ),
    );

const Map<String, String> _screens = {
  'accounts_list': '/accounts',
  'account_detail': '/accounts/$checkingId',
  'transactions_list': '/transactions',
  'transaction_editor': '/transactions/demo-txn-04',
  'categories_list': '/settings/categories',
  'category_editor': '/settings/categories/plaid:FOOD_AND_DRINK',
};

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final Brightness brightness in Brightness.values) {
    for (final MapEntry(key: String name, value: String location)
        in _screens.entries) {
      goldenTest(
        'the $name screen, ${brightness.name}',
        fileName: '${name}_${brightness.name}',
        constraints: BoxConstraints.tight(phoneSize),
        builder: () => _app(location, brightness),
      );
    }

    goldenTest(
      'the empty account list, ${brightness.name}',
      fileName: 'accounts_empty_${brightness.name}',
      constraints: BoxConstraints.tight(phoneSize),
      builder: () =>
          _app('/accounts', brightness, seed: const DemoSeed.empty()),
    );

    goldenTest(
      'the filter sheet, ${brightness.name}',
      fileName: 'filter_sheet_${brightness.name}',
      constraints: BoxConstraints.tight(phoneSize),
      builder: () => _app('/transactions', brightness),
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Filters'));
        await tester.pumpAndSettle();
      },
    );
  }
}
