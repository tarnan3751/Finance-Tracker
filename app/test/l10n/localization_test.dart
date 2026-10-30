// The localization scaffolding: the Spanish skeleton on a Spanish device, with the keys
// it leaves untranslated in English and amounts and dates in the device's locale; the
// Language choice in dev and demo (System, English, Pseudo), absent in prod, kept in
// app_meta; the pseudo-locale's bracketed, lengthened strings; and a two-pane screen laid
// out right to left.
import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/layout/two_pane.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/features/accounts/presentation/accounts_screen.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat, Intl;
import 'package:shared_models/shared_models.dart';

import '../helpers/pump_app.dart';
import '../helpers/seed.dart';

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Future<void> _openLanguage(WidgetTester tester, String title) =>
    tester.scrollUntilVisible(
      find.text(title),
      200,
      scrollable: find.byType(Scrollable).first,
    );

void main() {
  setUpAll(initializeDateFormatting);
  tearDown(() => Intl.defaultLocale = null);

  testWidgets('a Spanish device sees the skeleton, the rest in English', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es', 'ES')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester, overrides: [storeOverride(seededStore())]);

    expect(_navLabel('Cuentas'), findsOneWidget);
    expect(_navLabel('Movimientos'), findsOneWidget);
    expect(_navLabel('Ajustes'), findsOneWidget);
    expect(
      find.widgetWithText(FloatingActionButton, 'Añadir cuenta'),
      findsOne,
    );
    // Not in the skeleton: shown in English.
    expect(find.byTooltip('Linked banks'), findsOneWidget);
    final BuildContext context = tester.element(find.byType(AccountsScreen));
    expect(Localizations.localeOf(context), const Locale('es'));
    expect(
      MaterialLocalizations.of(context).backButtonTooltip,
      'Atrás',
      reason: "Material's own strings follow the app's locale",
    );
  });

  test('amounts and dates follow intl in the Spanish locale', () {
    Intl.defaultLocale = 'es_ES';
    expect(Money(123456, 'EUR').format(), '1.234,56\u00a0€');
    expect(DateFormat.yMMMd().format(DateTime(2026, 10, 24)), '24 oct 2026');
  });

  test('the plurals the skeleton translates take the count', () {
    final AppLocalizations es = lookupAppLocalizations(const Locale('es'));
    expect(es.accountsHidden(1), '1 cuenta oculta');
    expect(es.accountsHidden(3), '3 cuentas ocultas');
  });

  testWidgets('prod offers no language choice and no pseudo-locale', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/settings');

    expect(find.text('Language'), findsNothing);
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.supportedLocales, isNot(contains(pseudoLocale)));
    expect(
      app.supportedLocales,
      containsAll(const [Locale('en'), Locale('es')]),
    );
  });

  testWidgets('demo chooses the pseudo-locale, the device language again, then '
      'English, and keeps it', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es', 'ES')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.platformDispatcher.localeTestValue = const Locale('es', 'ES');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final InMemoryAppMetaStore meta = InMemoryAppMetaStore();
    await pumpApp(
      tester,
      config: AppConfig.demo(),
      initialLocation: '/settings',
      size: const Size(412, 1600),
      overrides: [appMetaStoreProvider.overrideWithValue(meta)],
    );
    expect(_navLabel('Ajustes'), findsOneWidget);

    await _openLanguage(tester, 'Idioma');
    await tester.tap(find.text('Pseudo'));
    await tester.pumpAndSettle();
    expect(await meta.read(AppMetaKeys.appLanguage), 'pseudo');
    expect(_navLabel('[Šéţţîñĝš ~~~~]'), findsOneWidget);
    expect(Intl.defaultLocale, 'en_US');

    await _openLanguage(tester, '[Ļåñĝûåĝé ~~~~]');
    await tester.tap(find.text('[Šýšţéɱ ~~~]'));
    await tester.pumpAndSettle();
    expect(await meta.read(AppMetaKeys.appLanguage), 'system');
    expect(_navLabel('Ajustes'), findsOneWidget);
    expect(Intl.defaultLocale, 'es_ES');

    await _openLanguage(tester, 'Idioma');
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(_navLabel('Settings'), findsOneWidget);
    expect(await meta.read(AppMetaKeys.appLanguage), 'english');
  });

  testWidgets('the list beside its detail lays out right to left', (
    tester,
  ) async {
    tester.view.physicalSize = expandedSize * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          ...testOverrides(initialLocation: '/accounts/$checkingId'),
          storeOverride(seededStore()),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(goRouterProvider),
            theme: AppTheme.light(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final Rect list = tester.getRect(
      find.byWidgetPredicate((w) => w is PaneScope && w.role == PaneRole.start),
    );
    final Rect detail = tester.getRect(
      find.byWidgetPredicate((w) => w is PaneScope && w.role == PaneRole.end),
    );
    final Rect rail = tester.getRect(find.byType(NavigationRail));
    expect(rail.right, expandedSize.width, reason: 'the rail at the start');
    expect(list.left, greaterThan(detail.right - 1));
    expect(detail.left, 0);
  });
}
