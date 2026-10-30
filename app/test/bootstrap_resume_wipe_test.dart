// bootstrap finishing a wipe cut short (the process killed part way) before it opens
// anything local: the erasing screen first, Try again after a failure, the confirmation
// for the recorded reason, then the normal start, signed out on the fresh install; a
// failure of a resumed wipe already points at Android's storage settings
// (`bootstrap_resume_wipe_dev_test.dart` covers the dev flavor's start). Its
// own file: the test binding's frames do not carry over from the running-app tests.
import 'dart:async';

import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/features/auth/presentation/sign_in_screen.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'core/api/support/fake_api.dart';
import 'helpers/wipe_support.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  testWidgets('a start finishes a wipe cut short before anything opens', (
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
    // Killed part way: still pending, the session and the marker still there.
    final TestWipe wipe = TestWipe(
      tokens,
      failures: 1,
      pendingReason: WipeReason.deviceErased,
    );
    // startApp returns only once the wipe it finishes first has been confirmed.
    await tester.runAsync(() async {
      unawaited(
        startApp(
          AppConfig.demo(),
          overrides: wipeTestOverrides(server, tokens, wipe),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await settleWipe(tester);
    expect(find.byType(FinanceTrackerApp), findsNothing);
    expect(find.text(l10n.eraseFailedTitle), findsOneWidget);
    // Resumed at startup, a failure is already a repeated one.
    expect(find.text(l10n.eraseFailedBody('true')), findsOneWidget);

    await tester.tap(find.text(l10n.eraseTryAgain));
    await settleWipe(tester);
    expect(find.text(l10n.erasedDeviceTitle), findsOneWidget);
    expect(await wipe.pending(), isNull);

    await tester.runAsync(() async {
      await tester.tap(find.text(l10n.erasedDone));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await settleWipe(tester);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(tokens.session, isNull);
    expect(tokens.installUserId, isNull);
    expect(wipe.runs, 2);

    await tester.runAsync(stopApp);
    await tester.pumpWidget(const SizedBox());
  });
}
