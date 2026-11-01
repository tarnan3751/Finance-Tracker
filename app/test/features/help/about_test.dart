// Settings → About's new rows: Privacy opening the privacy page, and Open-source
// licences opening Flutter's licence page under the app's name and version, with the
// bundled Roboto fonts' licence among the packages'. And what the privacy page says of
// the demo holds: no record of any household carries an address off the device.
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/features/help/application/licenses.dart';
import 'package:finance_tracker/features/help/presentation/privacy_screen.dart';
import 'package:finance_tracker/features/settings/presentation/settings_screen.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart';

import '../../helpers/pump_app.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

Finder get _settings => find
    .descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _open(WidgetTester tester, String row) async {
  await tester.scrollUntilVisible(find.text(row), 200, scrollable: _settings);
  await tester.pumpAndSettle();
  await tester.tap(find.text(row));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('About opens the privacy page', (tester) async {
    await pumpApp(tester, initialLocation: '/settings');
    await _open(tester, l10n.privacyTitle);
    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(find.text(l10n.privacy1), findsOneWidget);
  });

  testWidgets("About opens the licences under the app's name and version", (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/settings');
    await _open(tester, l10n.aboutLicenses);
    expect(find.byType(LicensePage), findsOneWidget);
    final LicensePage page = tester.widget(find.byType(LicensePage));
    expect(page.applicationName, 'Finance Tracker');
    expect(page.applicationVersion, testPackageInfo.version);
  });

  testWidgets("the Roboto fonts' licence is registered once", (tester) async {
    registerBundledLicenses();
    registerBundledLicenses();
    final List<LicenseEntry> roboto =
        await tester.runAsync(
          () => LicenseRegistry.licenses
              .where((l) => l.packages.contains('Roboto'))
              .toList(),
        ) ??
        [];
    expect(roboto, hasLength(1));
    expect(
      roboto.single.paragraphs.map((p) => p.text).join(' '),
      contains('Apache License'),
    );
  });

  test('no demo household carries an address off the device', () {
    for (final PersonaId persona in PersonaId.values) {
      final DemoSeed seed = demoSeedFor(persona, testClock.today());
      expect(
        seed.household.transactions.where((t) => t.merchantLogoUrl != null),
        isEmpty,
        reason: persona.slug,
      );
      expect(
        seed.household.institutions.where((i) => i.logoUrl != null),
        isEmpty,
        reason: persona.slug,
      );
    }
  });
}
