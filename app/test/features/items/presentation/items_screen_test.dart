// The linked banks screen: each bank's status chip and last sync in the device's zone,
// Fix connection only for a bank whose login must be repaired, a bank unlinked with its
// history shown only while its accounts are, with Delete history as its one action, each
// button's label naming its bank, the empty state linking
// the fake server's bank through the fake launcher, a failure shown on its card, the
// unlink dialog's two choices, and the entries from Accounts and Settings.
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/items/application/link_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

const String _location = '/accounts/linked-banks';

InMemoryStore _banked() =>
    seededStore()..applyPlaidItems(testBanks, testClock.nowUtc());

Finder _card(String institution) =>
    find.ancestor(of: find.text(institution), matching: find.byType(Card));

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('each bank shows its status and last sync in the device zone', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    // 15:00 UTC is 11:00 in New York, and the 14:00 UTC sync 10:00.
    final Clock newYork = FixedClock(
      DateTime.utc(2026, 10, 24, 15),
      tz.getLocation('America/New_York'),
    );
    await pumpApp(
      tester,
      initialLocation: _location,
      clock: newYork,
      size: const Size(412, 1200),
      overrides: [storeOverride(_banked())],
    );

    expect(find.widgetWithText(AppBar, 'Linked banks'), findsOneWidget);
    expect(
      find.descendant(
        of: _card('First Platypus Bank'),
        matching: find.text('Connected'),
      ),
      findsOneWidget,
    );
    expect(find.text('Last synced Oct 24, 2026 10:00 AM'), findsOneWidget);
    expect(
      find.descendant(
        of: _card('Tartan Bank'),
        matching: find.text('Needs attention'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _card('Houndstooth Bank'),
        matching: find.text('Not synced yet'),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Status: Error'), findsOneWidget);
    // Each button names the bank it acts on.
    expect(
      find.bySemanticsLabel('Sync now, First Platypus Bank'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Fix connection, Tartan Bank'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Unlink, Houndstooth Bank'), findsOneWidget);
    semantics.dispose();
    // Fix connection only where the login must be repaired.
    expect(find.text('Fix connection'), findsOneWidget);
    expect(
      find.descendant(
        of: _card('Tartan Bank'),
        matching: find.text('Fix connection'),
      ),
      findsOneWidget,
    );
    expect(find.text('Sync now'), findsNWidgets(3));
    expect(find.text('Link a bank'), findsOneWidget);
  });

  testWidgets('a bank unlinked with its history shows while its accounts do', (
    tester,
  ) async {
    final InMemoryStore store = seededStore()
      ..applyPlaidItems([
        (
          item: const Item(
            id: 'kept',
            institutionId: 'ins_kept',
            status: ItemStatus.removed,
          ),
          institution: const Institution(id: 'ins_kept', name: 'Kept Bank'),
        ),
        (
          item: const Item(
            id: 'gone',
            institutionId: 'ins_gone',
            status: ItemStatus.removed,
          ),
          institution: const Institution(id: 'ins_gone', name: 'Gone Bank'),
        ),
      ], testClock.nowUtc())
      ..upsertAccount(
        const Account(
          id: 'kept-checking',
          itemId: 'kept',
          type: AccountType.depository,
          name: 'Kept checking',
          currencyCode: 'USD',
          isHidden: false,
          displayOrder: 9,
        ),
      );
    await pumpApp(
      tester,
      initialLocation: _location,
      overrides: [storeOverride(store)],
    );
    expect(find.text('Kept Bank'), findsOneWidget);
    expect(find.text('Unlinked'), findsOneWidget);
    expect(find.text('Sync now'), findsNothing);
    expect(find.text('Unlink'), findsNothing);
    expect(find.text('Gone Bank'), findsNothing);

    // Its one action deletes the kept history, after saying what that does.
    await tester.tap(find.text('Delete history'));
    await tester.pumpAndSettle();
    expect(find.text('Delete the history of Kept Bank?'), findsOneWidget);
    expect(
      find.textContaining('every other device signed in to your account'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Kept Bank'), findsOneWidget);
    await tester.tap(find.text('Delete history'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Kept Bank'), findsNothing);
    expect(store.account('kept-checking'), isNull);
  });

  testWidgets('the empty state links the fake server\'s bank', (tester) async {
    final InMemoryStore store = seededStore();
    await pumpApp(
      tester,
      initialLocation: _location,
      overrides: [
        storeOverride(store),
        linkPollIntervalProvider.overrideWithValue(Duration.zero),
      ],
    );
    expect(find.text('No linked banks'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Link a bank'));
    await tester.pumpAndSettle();

    expect(find.text('First Platypus Bank'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(
      store.accounts().where((a) => a.itemId == 'sample-item-1'),
      hasLength(3),
    );
  });

  testWidgets('a failure shows on its card', (tester) async {
    await pumpApp(
      tester,
      initialLocation: _location,
      size: const Size(412, 1200),
      overrides: [storeOverride(_banked())],
    );
    final ProviderContainer c = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).last),
    );
    c.read(fakeServerProvider).failNextNetwork('syncItem');

    await tester.tap(
      find.descendant(
        of: _card('First Platypus Bank'),
        matching: find.text('Sync now'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: _card('First Platypus Bank'),
        matching: find.text(
          "Couldn't reach the server. Try again when you're online.",
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('unlink asks to keep or delete the history', (tester) async {
    final InMemoryStore store = seededStore();
    await pumpApp(
      tester,
      initialLocation: _location,
      overrides: [
        storeOverride(store),
        linkPollIntervalProvider.overrideWithValue(Duration.zero),
      ],
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Link a bank'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unlink'));
    await tester.pumpAndSettle();
    expect(find.text('Unlink First Platypus Bank?'), findsOneWidget);
    expect(find.text('Keep history on this device and others'), findsOneWidget);
    expect(
      find.text(
        'Its accounts and transactions stay on every device, no longer updated.',
      ),
      findsOneWidget,
    );
    expect(find.text('Delete its accounts and transactions'), findsOneWidget);

    // Cancel leaves the bank.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('First Platypus Bank'), findsOneWidget);

    await tester.tap(find.text('Unlink'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete its accounts and transactions'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Unlink').last);
    await tester.pumpAndSettle();

    expect(find.text('No linked banks'), findsOneWidget);
    expect(store.accounts().where((a) => a.itemId != null), isEmpty);
  });

  testWidgets('the Accounts app bar opens the linked banks', (tester) async {
    await pumpApp(tester, overrides: [storeOverride(_banked())]);
    await tester.tap(find.byTooltip('Linked banks'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Linked banks'), findsOneWidget);
  });

  testWidgets('Settings opens the linked banks', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/settings',
      overrides: [storeOverride(_banked())],
    );
    await tester.tap(find.text('Linked banks'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Linked banks'), findsOneWidget);
  });
}
