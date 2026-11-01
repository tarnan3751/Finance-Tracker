// The in-app help: Settings → About → Help listing every section; a section opening on
// its own page; each tab's menu opening its own section on top of the tab (the tab kept,
// back returning to it); a slug no section has showing the list; every section under
// about two hundred words, with no amount in it, laid out at twice the text size.
import 'package:finance_tracker/features/help/domain/help_section.dart';
import 'package:finance_tracker/features/help/presentation/help_content.dart';
import 'package:finance_tracker/features/help/presentation/help_screen.dart';
import 'package:finance_tracker/features/help/presentation/help_section_screen.dart';
import 'package:finance_tracker/features/help/presentation/help_widgets.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

// The words of [section], its title included.
List<String> _words(HelpSection section) => [
  helpSectionTitle(l10n, section),
  for (final Widget block in helpSectionBody(l10n, section))
    ...switch (block) {
      HelpHeading(:final String text) => [text],
      HelpParagraph(:final String text) => [text],
      HelpBullets(:final List<String> items) => items,
      _ => throw StateError('$block'),
    },
].expand((t) => t.split(RegExp(r'\s+'))).toList();

Future<void> _openMenuHelp(WidgetTester tester) async {
  await tester.tap(find.byTooltip(l10n.helpMoreOptions).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.helpMenuItem));
  await tester.pumpAndSettle();
}

void main() {
  test('every section is short and names no amount', () {
    for (final HelpSection section in HelpSection.values) {
      final List<String> words = _words(section);
      expect(words.length, lessThan(220), reason: section.name);
      expect(
        words.where((w) => RegExp(r'[$€£]\d|\d+\.\d\d').hasMatch(w)),
        isEmpty,
        reason: section.name,
      );
    }
    expect({
      for (final HelpSection s in HelpSection.values) s.slug,
    }, hasLength(HelpSection.values.length));
  });

  testWidgets('Settings opens the list, the list a section', (tester) async {
    await pumpApp(tester, initialLocation: '/settings/help');
    expect(find.byType(HelpScreen), findsOneWidget);
    for (final HelpSection section in HelpSection.values.take(6)) {
      expect(
        find.descendant(
          of: find.byType(HelpScreen),
          matching: find.text(helpSectionTitle(l10n, section)),
        ),
        findsOneWidget,
      );
    }
    await tester.tap(find.text(l10n.helpBudgetsTitle));
    await tester.pumpAndSettle();
    expect(find.byType(HelpSectionScreen), findsOneWidget);
    expect(find.text(l10n.helpBudgets1), findsOneWidget);
  });

  testWidgets('a slug no section has shows the list', (tester) async {
    await pumpApp(tester, initialLocation: '/settings/help/nowhere');
    expect(find.byType(HelpScreen), findsOneWidget);
  });

  for (final (String location, HelpSection section) in [
    ('/accounts', HelpSection.accounts),
    ('/transactions', HelpSection.transactions),
    ('/budgets', HelpSection.budgets),
    ('/bills', HelpSection.bills),
    ('/forecast', HelpSection.forecast),
    ('/reports', HelpSection.insights),
    ('/goals', HelpSection.insights),
  ]) {
    testWidgets("$location's menu opens ${section.slug}, on the tab", (
      tester,
    ) async {
      await pumpApp(tester, initialLocation: location);
      final int tab = tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .selectedIndex;
      await _openMenuHelp(tester);
      expect(find.byType(HelpSectionScreen), findsOneWidget);
      expect(
        find.widgetWithText(AppBar, helpSectionTitle(l10n, section)),
        findsOneWidget,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        tab,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(HelpSectionScreen), findsNothing);
    });
  }

  for (final HelpSection section in HelpSection.values) {
    testWidgets('${section.slug} lays out at twice the text size', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialLocation: '/settings/help/${section.slug}',
        textScale: 2,
      );
      expect(find.byType(HelpSectionScreen), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
