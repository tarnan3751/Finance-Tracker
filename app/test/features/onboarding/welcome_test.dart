// The Welcome screen of a fresh dev or prod install: every location held there, the demo
// step listing the four households with their lines, a household chosen storing it and
// the demo mode and restarting once (a second tap ignored, the cards read as disabled
// meanwhile), "Use my own server" storing
// the live mode and restarting, a store that refuses leaving both screens usable and
// saying so, and both screens at twice the text size.
import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/config/app_mode_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/widgets/brand_mark.dart';
import 'package:finance_tracker/features/onboarding/presentation/demo_persona_screen.dart';
import 'package:finance_tracker/features/onboarding/presentation/welcome_screen.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsAction, SemanticsData;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;

import '../../helpers/pump_app.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

/// A fresh prod install: no mode chosen.
final AppConfig fresh = AppConfig.prod().withChoices(mode: null);

/// The store [modes], and a restart counted in [restarts].
List<Override> _overrides(InMemoryAppModeStore modes, List<int> restarts) => [
  appModeStoreProvider.overrideWithValue(modes),
  appModeRestartProvider.overrideWithValue(() async => restarts.add(1)),
];

/// A store that refuses every write.
final class _RefusingStore extends Fake implements AppModeStore {
  int tries = 0;

  @override
  Future<void> writeMode(AppMode mode) async {
    tries++;
    throw StateError('storage refused');
  }

  @override
  Future<void> writeDemoPersona(PersonaId persona) async {
    tries++;
    throw StateError('storage refused');
  }
}

/// A store whose writes wait for [done].
final class _SlowStore extends Fake implements AppModeStore {
  final Completer<void> done = Completer<void>();

  @override
  Future<void> writeMode(AppMode mode) => done.future;

  @override
  Future<void> writeDemoPersona(PersonaId persona) => done.future;
}

void main() {
  testWidgets('while a household is being stored, the cards read as disabled', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final _SlowStore modes = _SlowStore();
    await pumpApp(
      tester,
      config: fresh,
      signedIn: false,
      overrides: [
        appModeStoreProvider.overrideWithValue(modes),
        appModeRestartProvider.overrideWithValue(() async {}),
      ],
    );
    await tester.tap(find.text(l10n.welcomeTryDemo));
    await tester.pumpAndSettle();
    final SemanticsData before = tester
        .getSemantics(find.text(l10n.demoPersonaStudent))
        .getSemanticsData();
    expect(before.flagsCollection.isEnabled, Tristate.isTrue);
    await tester.tap(find.text(l10n.demoPersonaFamily));
    await tester.pump();
    final SemanticsData busy = tester
        .getSemantics(find.text(l10n.demoPersonaStudent))
        .getSemanticsData();
    expect(busy.flagsCollection.isEnabled, Tristate.isFalse);
    expect(busy.hasAction(SemanticsAction.tap), isFalse);
    modes.done.complete();
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('a fresh install opens on Welcome, wherever it starts', (
    tester,
  ) async {
    await pumpApp(
      tester,
      config: fresh,
      signedIn: false,
      initialLocation: '/transactions',
      overrides: _overrides(InMemoryAppModeStore(), []),
    );
    expect(find.byType(WelcomeScreen), findsOneWidget);
    // The wordmark: the name in the blue over its pink copy, read once.
    expect(
      find.descendant(
        of: find.byType(Wordmark),
        matching: find.text(AppConfig.prod().appName),
      ),
      findsNWidgets(2),
    );
    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.text(l10n.welcomeBody), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('the demo stores the household and the mode, then restarts', (
    tester,
  ) async {
    final InMemoryAppModeStore modes = InMemoryAppModeStore();
    final List<int> restarts = [];
    await pumpApp(
      tester,
      config: fresh,
      signedIn: false,
      overrides: _overrides(modes, restarts),
    );
    await tester.tap(find.text(l10n.welcomeTryDemo));
    await tester.pumpAndSettle();
    expect(find.byType(DemoPersonaScreen), findsOneWidget);
    for (final String text in [
      l10n.demoPersonaRenter,
      l10n.demoPersonaRenterDetail,
      l10n.demoPersonaFamily,
      l10n.demoPersonaStudent,
      l10n.demoPersonaSmallBusiness,
      l10n.demoPersonaSmallBusinessDetail,
    ]) {
      expect(find.text(text), findsOneWidget);
    }

    await tester.tap(find.text(l10n.demoPersonaFamily));
    await tester.tap(find.text(l10n.demoPersonaStudent));
    await tester.pumpAndSettle();
    expect(modes.mode, AppMode.demo);
    expect(modes.demoPersona, PersonaId.family);
    expect(restarts, hasLength(1));
  });

  testWidgets('back from the households returns to Welcome', (tester) async {
    await pumpApp(
      tester,
      config: fresh,
      signedIn: false,
      overrides: _overrides(InMemoryAppModeStore(), []),
    );
    await tester.tap(find.text(l10n.welcomeTryDemo));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('my own server stores the live mode, then restarts', (
    tester,
  ) async {
    final InMemoryAppModeStore modes = InMemoryAppModeStore();
    final List<int> restarts = [];
    await pumpApp(
      tester,
      config: fresh,
      signedIn: false,
      overrides: _overrides(modes, restarts),
    );
    await tester.tap(find.text(l10n.welcomeUseServer));
    await tester.tap(find.text(l10n.welcomeUseServer));
    await tester.pumpAndSettle();
    expect(modes.mode, AppMode.live);
    expect(modes.demoPersona, isNull);
    expect(restarts, hasLength(1));
  });

  testWidgets('both lay out at twice the text size', (tester) async {
    await pumpApp(
      tester,
      config: fresh,
      signedIn: false,
      textScale: 2,
      overrides: _overrides(InMemoryAppModeStore(), []),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(l10n.welcomeTryDemo));
    await tester.pumpAndSettle();
    expect(find.byType(DemoPersonaScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a store that refuses says so and leaves the choices usable', (
    tester,
  ) async {
    final _RefusingStore modes = _RefusingStore();
    final List<int> restarts = [];
    await pumpApp(
      tester,
      config: fresh,
      signedIn: false,
      overrides: [
        appModeStoreProvider.overrideWithValue(modes),
        appModeRestartProvider.overrideWithValue(() async => restarts.add(1)),
      ],
    );
    await tester.tap(find.text(l10n.welcomeUseServer));
    await tester.pumpAndSettle();
    expect(find.text(l10n.modeChoiceFailed), findsOneWidget);
    expect(restarts, isEmpty);
    // Usable again.
    await tester.tap(find.text(l10n.welcomeUseServer));
    await tester.pumpAndSettle();
    expect(modes.tries, 2);

    await tester.tap(find.text(l10n.welcomeTryDemo));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.demoPersonaFamily));
    await tester.pumpAndSettle();
    expect(modes.tries, 3);
    await tester.tap(find.text(l10n.demoPersonaStudent));
    await tester.pumpAndSettle();
    expect(modes.tries, 4);
    expect(restarts, isEmpty);
    expect(find.text(l10n.modeChoiceFailed), findsWidgets);
  });
}
