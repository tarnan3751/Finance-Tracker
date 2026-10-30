// Devices and account deletion on a device, in the demo build on the dev flavor's
// wiring started as bootstrap starts it (startApp: the encrypted database under the
// application support directory, the receipts folder beside it, the real client over
// the in-app fake server, the platform's notifications). Run on the harness's emulator
// with `tools/emulator_tests.sh integration`.
//
// A signed-in install with a receipt photo and a second device: Settings → Devices lists
// both with this one marked, and removes the other. Settings → Delete account, the email
// typed: the server deletes the user, the app stops, the database files, the receipts,
// the key, the session and the install's user go, the confirmation shows, and Done
// starts the app again at sign-in on a fresh database under a new key, where a new
// account may register.
import 'dart:io';

import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:finance_tracker/features/auth/application/device_name.dart';
import 'package:finance_tracker/features/auth/presentation/sign_in_screen.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_models/shared_models.dart';

const String _email = 'ada@example.com';
const String _password = 'correct horse';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

/// Pumps until [finder] shows (or, when [gone], no longer does), or fails after [timeout] saying what the screen shows.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 120),
  bool gone = false,
}) async {
  final DateTime end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty != gone) return;
  }
  final List<String> shown = [
    for (final Element e in find.byType(Text).evaluate())
      if ((e.widget as Text).data case final String text) text,
  ];
  fail('$finder did not ${gone ? 'go' : 'appear'}; the screen shows $shown');
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;

  File databaseFile() => File(p.join(support.path, databaseFileName));
  Directory receiptsFolder() => Directory(p.join(support.path, receiptFolder));

  void removeInstall() {
    for (final String suffix in const ['', '-wal', '-shm', '-journal']) {
      final File f = File('${databaseFile().path}$suffix');
      if (f.existsSync()) f.deleteSync();
    }
    if (receiptsFolder().existsSync()) {
      receiptsFolder().deleteSync(recursive: true);
    }
  }

  setUp(() async {
    support = await getApplicationSupportDirectory();
    removeInstall();
  });
  tearDown(() async {
    await stopApp();
    removeInstall();
  });

  testWidgets('devices, then account deletion to a fresh install', (
    tester,
  ) async {
    await setUpTimeZones();
    final FakeServer server = FakeServer(
      dataset: FakeDataset.sample(LocalDate.fromDateTime(DateTime.now())),
    )..seedUser(email: _email, password: _password, displayName: 'Ada');
    server.seedLinkedItems(_email);
    final Session session = server.seedSession(
      email: _email,
      password: _password,
      deviceName: 'Test phone',
    );
    server.seedSession(
      email: _email,
      password: _password,
      deviceName: 'Tablet',
    );
    final InMemoryDatabaseKeyStore keys = InMemoryDatabaseKeyStore();
    final InMemoryTokenStore tokens = InMemoryTokenStore(
      session: session,
      installUserId: session.userId,
    );
    final File receipt = File(p.join(receiptsFolder().path, 'lunch.jpg'))
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);

    await startApp(
      AppConfig.dev(),
      overrides: [
        ...localDataOverridesFor(AppConfig.dev()),
        databaseKeyStoreProvider.overrideWithValue(keys),
        fakeServerProvider.overrideWithValue(server),
        tokenStoreProvider.overrideWithValue(tokens),
        fakeFinanceApiOverride,
        deviceNameProvider.overrideWith((ref) async => 'Test phone'),
        appVersionProvider.overrideWith((ref) async => '1.0.0+1'),
      ],
    );
    final String? firstKey = keys.key;
    expect(firstKey, isNotNull);
    expect(databaseFile().existsSync(), isTrue);

    // A signed-in install with an empty database is offered a restore first.
    await pumpUntil(tester, find.text(l10n.restoreOfferStartFresh));
    await tapAndSettle(tester, find.text(l10n.restoreOfferStartFresh));
    await pumpUntil(tester, find.text('Settings'));
    await tapAndSettle(tester, find.text('Settings'));

    // Devices: this one marked, the tablet removed.
    await tapAndSettle(tester, find.text(l10n.settingsDevices));
    await pumpUntil(tester, find.text('Tablet'));
    expect(find.textContaining(l10n.devicesThisDevice), findsOneWidget);
    await tapAndSettle(tester, find.byTooltip(l10n.devicesActions('Tablet')));
    await tapAndSettle(tester, find.text(l10n.devicesRemove));
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.devicesRemove),
      ),
    );
    await pumpUntil(tester, find.text('Tablet'), gone: true);
    expect(find.text(l10n.devicesSignOutOthers), findsNothing);
    await tapAndSettle(tester, find.byType(BackButton));

    // Delete account.
    await tapAndSettle(tester, find.text(l10n.settingsDeleteAccount));
    await tester.enterText(find.byType(TextField), _email);
    await tester.pump();
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, l10n.deleteAccountSubmit),
    );
    await pumpUntil(tester, find.text(l10n.erasedAccountTitle));
    expect(server.hasUser(_email), isFalse);
    expect(databaseFile().existsSync(), isFalse);
    expect(receipt.existsSync(), isFalse);
    expect(keys.key, isNull);
    expect(tokens.session, isNull);
    expect(tokens.installUserId, isNull);

    // Done: the fresh install at sign-in, a new key, an empty database.
    await tester.tap(find.text(l10n.erasedDone));
    await pumpUntil(tester, find.byType(SignInScreen));
    expect(find.text(l10n.signInRemoteNotice), findsNothing);
    expect(keys.key, isNotNull);
    expect(keys.key, isNot(firstKey));
    expect(databaseFile().existsSync(), isTrue);
    final ProviderContainer fresh = ProviderScope.containerOf(
      tester.element(find.byType(SignInScreen)),
    );
    expect(
      await fresh.read(accountRepositoryProvider).watchAll().first,
      isEmpty,
    );

    // The install's user is gone with the data: a new account may register.
    await tapAndSettle(tester, find.text(l10n.signInCreateAccount));
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.authEmailLabel),
      'bea@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.authPasswordLabel),
      _password,
    );
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, l10n.registerSubmit),
    );
    await pumpUntil(tester, find.text(l10n.restoreOfferStartFresh));
  });
}
