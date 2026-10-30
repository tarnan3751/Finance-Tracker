// bootstrap's local wipe on the running app: the erasing screen, the app stopped, a
// failed wipe shown with Try again and run again (the second failure in a row pointing at
// Android's storage settings), the confirmation for the reason, and
// on Done the app started again on a new container, signed out on the fresh install.
import 'dart:async';

import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/features/auth/presentation/sign_in_screen.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'core/api/support/fake_api.dart';
import 'helpers/wipe_support.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  testWidgets('the wipe stops the app, retries, confirms and starts it again', (
    tester,
  ) async {
    final FakeServer server = newFakeServer()
      ..seedUser(email: 'ada@example.com', password: 'correct horse');
    final Session session = server.seedSession(
      email: 'ada@example.com',
      password: 'correct horse',
      deviceName: 'Pixel 6',
    );
    final InMemoryTokenStore tokens = InMemoryTokenStore(
      session: session,
      installUserId: session.userId,
    );
    final TestWipe wipe = TestWipe(tokens, failures: 2);
    final List<Override> overrides = wipeTestOverrides(server, tokens, wipe);
    await tester.runAsync(
      () => startApp(AppConfig.demo(), overrides: overrides),
    );
    await settleWipe(tester);
    ProviderContainer running() => ProviderScope.containerOf(
      tester.element(find.byType(FinanceTrackerApp)),
    );
    final ProviderContainer first = running();
    expect(first.read(sessionControllerProvider), isA<SignedIn>());

    unawaited(first.read(wipeLocalDataProvider)(WipeReason.accountDeleted));
    await settleWipe(tester);
    expect(find.text(l10n.eraseFailedTitle), findsOneWidget);
    expect(find.byType(FinanceTrackerApp), findsNothing);
    expect(find.text(l10n.eraseFailedBody('false')), findsOneWidget);

    // A double tap counts once.
    await tester.tap(find.text(l10n.eraseTryAgain));
    await tester.tap(find.text(l10n.eraseTryAgain));
    await settleWipe(tester);
    expect(tester.takeException(), isNull);
    expect(wipe.runs, 2);
    // The second failure in a row points at Android's storage settings.
    expect(find.text(l10n.eraseFailedBody('true')), findsOneWidget);

    await tester.tap(find.text(l10n.eraseTryAgain));
    await settleWipe(tester);
    expect(wipe.runs, 3);
    expect(find.text(l10n.erasedAccountTitle), findsOneWidget);
    expect(find.text(l10n.erasedAccountBody), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text(l10n.erasedDone));
      await tester.tap(find.text(l10n.erasedDone));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await settleWipe(tester);
    expect(find.byType(SignInScreen), findsOneWidget);
    final ProviderContainer second = running();
    expect(second, isNot(same(first)));
    expect(second.read(sessionControllerProvider), isA<SignedOut>());
    expect(tokens.installUserId, isNull);
    expect(tester.takeException(), isNull);

    await tester.runAsync(stopApp);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('erasing the device says the account stays', (tester) async {
    final InMemoryTokenStore tokens = InMemoryTokenStore();
    await tester.runAsync(
      () => startApp(
        AppConfig.demo(),
        overrides: wipeTestOverrides(newFakeServer(), tokens, TestWipe(tokens)),
      ),
    );
    await settleWipe(tester);
    unawaited(
      ProviderScope.containerOf(tester.element(find.byType(FinanceTrackerApp)))
          .read(wipeLocalDataProvider)(WipeReason.deviceErased),
    );
    await settleWipe(tester);
    expect(find.text(l10n.erasedDeviceTitle), findsOneWidget);
    expect(find.text(l10n.erasedDeviceBody), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text(l10n.erasedDone));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await settleWipe(tester);
    await tester.runAsync(stopApp);
    await tester.pumpWidget(const SizedBox());
  });
}
