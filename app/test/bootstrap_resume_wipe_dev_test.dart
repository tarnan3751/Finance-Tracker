// bootstrap finishing a wipe cut short on the dev flavor's start, which opens the local
// data: the wipe runs to its confirmation before the database is ever built. Its own
// file, as the demo case's: the test binding's frames do not carry over between tests
// that start the app.
import 'dart:async';

import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'core/api/support/fake_api.dart';
import 'helpers/wipe_support.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  testWidgets('in dev, the database is not opened before the wipe finishes', (
    tester,
  ) async {
    final InMemoryTokenStore tokens = InMemoryTokenStore(installUserId: 'u');
    final TestWipe wipe = TestWipe(
      tokens,
      pendingReason: WipeReason.accountDeleted,
    );
    bool opened = false;
    unawaited(
      startApp(
        AppConfig.dev(),
        overrides: wipeTestOverrides(
          newFakeServer(),
          tokens,
          wipe,
          onDatabase: () => opened = true,
        ),
      ),
    );
    await settleWipe(tester);
    expect(find.text(l10n.erasedAccountTitle), findsOneWidget);
    expect(opened, isFalse);
    expect(wipe.runs, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
