// The demo's strip and the ways out of the demo in dev and prod: the strip above every
// tab, read by screen readers, on one line at every size class, at twice the text size
// and in the pseudo-locale; Leave asking first and then running the wipe for leaving the
// demo; Settings → Demo data's "Leave the demo" doing the same and keeping a chosen
// household; and neither in the demo flavor (marked by its banner) nor in the live mode.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/config/app_mode_store.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/onboarding/presentation/demo_strip.dart';
import 'package:finance_tracker/features/settings/domain/app_language.dart';
import 'package:finance_tracker/features/settings/presentation/settings_screen.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;

import '../../helpers/pump_app.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

final AppConfig _demoMode = AppConfig.prod().withChoices(mode: AppMode.demo);

List<Override> _overrides(List<WipeReason> wipes, [AppModeStore? modes]) => [
  wipeLocalDataProvider.overrideWithValue((reason) async => wipes.add(reason)),
  if (modes != null) appModeStoreProvider.overrideWithValue(modes),
];

Finder get _confirm => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.text(l10n.leaveDemoConfirm),
);

Finder get _settings => find
    .descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(Scrollable),
    )
    .first;

Finder get _strip => find.descendant(
  of: find.byType(DemoStrip),
  matching: find.text(l10n.demoStripLabel),
);

void main() {
  testWidgets('the strip is above every tab and read before the screen', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpApp(tester, config: _demoMode, overrides: _overrides([]));
    expect(find.bySemanticsLabel(l10n.demoStripLabel), findsOneWidget);
    expect(find.bySemanticsLabel(l10n.demoStripLeave), findsOneWidget);
    for (final String tab in ['Transactions', 'Plan', 'Insights', 'Settings']) {
      expect(_strip, findsOneWidget);
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
    }
    expect(_strip, findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Leave asks first, then leaves the demo', (tester) async {
    final List<WipeReason> wipes = [];
    await pumpApp(tester, config: _demoMode, overrides: _overrides(wipes));
    await tester.tap(find.text(l10n.demoStripLeave));
    await tester.pumpAndSettle();
    expect(find.text(l10n.leaveDemoTitle), findsOneWidget);
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(wipes, isEmpty);

    await tester.tap(find.text(l10n.demoStripLeave));
    await tester.pumpAndSettle();
    await tester.tap(_confirm);
    await tester.pumpAndSettle();
    expect(wipes, [WipeReason.demoLeft]);
  });

  testWidgets('Settings leaves the demo and keeps a chosen household', (
    tester,
  ) async {
    final List<WipeReason> wipes = [];
    final InMemoryAppModeStore modes = InMemoryAppModeStore(mode: AppMode.demo);
    await pumpApp(
      tester,
      config: _demoMode,
      initialLocation: '/settings',
      overrides: _overrides(wipes, modes),
    );
    await tester.scrollUntilVisible(
      find.text(l10n.demoPersonaStudent),
      200,
      scrollable: _settings,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.demoPersonaStudent));
    await tester.pumpAndSettle();
    expect(modes.demoPersona, PersonaId.student);

    await tester.scrollUntilVisible(
      find.text(l10n.leaveDemo),
      200,
      scrollable: _settings,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.leaveDemo));
    await tester.pumpAndSettle();
    await tester.tap(_confirm);
    await tester.pumpAndSettle();
    expect(wipes, [WipeReason.demoLeft]);
  });

  testWidgets('the demo flavor has no strip and no way out; live, no strip', (
    tester,
  ) async {
    await pumpApp(
      tester,
      config: AppConfig.demo(),
      initialLocation: '/settings',
      overrides: _overrides([]),
    );
    expect(_strip, findsNothing);
    await tester.scrollUntilVisible(
      find.text(l10n.demoPersonaSmallBusiness),
      200,
      scrollable: _settings,
    );
    expect(find.text(l10n.leaveDemo), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, overrides: _overrides([]));
    expect(_strip, findsNothing);
  });

  for (final (String name, Size size) in [
    ('compact', phoneSize),
    ('medium', mediumSize),
    ('expanded', expandedSize),
  ]) {
    testWidgets('one line on a $name window at twice the text size', (
      tester,
    ) async {
      await pumpApp(
        tester,
        config: _demoMode,
        size: size,
        textScale: 2,
        overrides: _overrides([]),
      );
      expect(tester.takeException(), isNull);
      _expectOneLine(tester);
    });
  }

  testWidgets('one line in the pseudo-locale', (tester) async {
    final InMemoryAppMetaStore meta = InMemoryAppMetaStore();
    await meta.write(AppMetaKeys.appLanguage, AppLanguage.pseudo.name);
    await pumpApp(
      tester,
      config: AppConfig.dev().withChoices(mode: AppMode.demo),
      overrides: [
        ..._overrides([]),
        appMetaStoreProvider.overrideWithValue(meta),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(DemoStrip), findsOneWidget);
    final Finder label = find.descendant(
      of: find.byType(DemoStrip),
      matching: find.byWidgetPredicate((w) => w is Text && w.maxLines == 1),
    );
    expect(label, findsNWidgets(2));
  });

  for (final Brightness brightness in Brightness.values) {
    testWidgets('the strip sets dark status bar icons on its pink in the '
        '${brightness.name} theme', (tester) async {
      await pumpApp(
        tester,
        config: _demoMode,
        brightness: brightness,
        overrides: _overrides([]),
      );
      final AnnotatedRegion<SystemUiOverlayStyle> region = tester.widget(
        find
            .descendant(
              of: find.byType(DemoStrip),
              matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            )
            .first,
      );
      expect(region.value.statusBarIconBrightness, Brightness.dark);
      expect(region.value.systemNavigationBarColor, isNull);
    });
  }
}

// The strip's label and button each take one line of their text.
void _expectOneLine(WidgetTester tester) {
  for (final String text in [l10n.demoStripLabel, l10n.demoStripLeave]) {
    final Finder found = find.text(text);
    final RenderParagraph paragraph = tester.renderObject(found);
    final double line = paragraph.getFullHeightForCaret(
      const TextPosition(offset: 0),
    );
    expect(tester.getSize(found).height, lessThanOrEqualTo(line + 0.5));
  }
}
