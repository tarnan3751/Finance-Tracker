// The empty state: the icon printed in blue over its pink copy, offset by the icon's
// misregistration, under a Syne headline; with its goldens, light and dark. Tagged
// `golden` for the goldens; see test/flutter_test_config.dart for where the files go and
// how to update them.
import 'package:alchemist/alchemist.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _state(Brightness brightness) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
  home: Scaffold(
    body: EmptyState(
      icon: Icons.account_balance_outlined,
      headline: 'No accounts yet',
      body: 'Add an account to start tracking.',
      action: FilledButton(onPressed: () {}, child: const Text('Add account')),
    ),
  ),
);

void main() {
  testWidgets('the empty state prints its icon in blue over a pink copy', (
    tester,
  ) async {
    await tester.pumpWidget(_state(Brightness.light));

    final List<Icon> icons = tester
        .widgetList<Icon>(find.byIcon(Icons.account_balance_outlined))
        .toList();
    expect(icons.map((i) => i.color), [
      FinanceColors.light.accent,
      AppTheme.lightScheme.primary,
    ]);
    final List<Offset> corners = [
      for (final Element e
          in find.byIcon(Icons.account_balance_outlined).evaluate())
        tester.getTopLeft(find.byElementPredicate((x) => x == e)),
    ];
    expect(
      corners.first - corners.last,
      const Offset(
        SpendthriftTokens.iconMisregistration,
        SpendthriftTokens.iconMisregistration,
      ),
    );
    final Text headline = tester.widget(find.text('No accounts yet'));
    expect(headline.style?.fontFamily, AppTheme.headingFont);
  });

  for (final Brightness brightness in Brightness.values) {
    goldenTest(
      'the empty state, ${brightness.name}',
      fileName: 'empty_state_${brightness.name}',
      constraints: BoxConstraints.tight(const Size(412, 500)),
      builder: () =>
          SizedBox(width: 412, height: 500, child: _state(brightness)),
    );
  }
}
