// Linked accounts on the account screens: the institution's reported balance labelled
// "reported" on the list and "reported by <institution>" with the as-of time in the
// device's zone on the detail, with the available balance; a linked account never synced
// keeps its derived balance "from transactions"; manual accounts unchanged; totals add
// reported and derived balances; the institution's avatar, name, official name and mask;
// the linked banks from the detail's menu.
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/widgets/merchant_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Finder _card(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(Card));

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('the list', () {
    testWidgets('a linked account shows its reported balance and institution', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await pumpApp(
          tester,
          overrides: [storeOverride(linkedStore(manual: true))],
        );

        final Finder checking = _card('Platypus Checking');
        expect(
          find.descendant(of: checking, matching: find.text(r'$1,100.00')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: checking, matching: find.text('reported')),
          findsOneWidget,
        );
        final MerchantAvatar avatar = tester.widget(
          find.descendant(of: checking, matching: find.byType(MerchantAvatar)),
        );
        expect(avatar.name, 'First Platypus Bank');
        expect(avatar.semanticsLabel, 'First Platypus Bank');
        expect(
          find.bySemanticsLabel(
            RegExp('^First Platypus Bank\nPlatypus Checking'),
          ),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('a linked account never synced shows its derived balance', (
      tester,
    ) async {
      await pumpApp(tester, overrides: [storeOverride(linkedStore())]);

      final Finder card = _card('Tartan Card');
      expect(
        find.descendant(of: card, matching: find.text(r'$0.00')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('from transactions')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.byType(MerchantAvatar)),
        findsOneWidget,
      );
    });

    testWidgets('a manual account keeps its icon and derived balance', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [storeOverride(linkedStore(manual: true))],
      );

      final Finder card = _card('Everyday Checking');
      expect(
        find.descendant(of: card, matching: find.text(r'$4,925.91')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('from transactions')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.byType(MerchantAvatar)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.byIcon(Icons.account_balance_outlined),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the totals add reported and derived balances', (tester) async {
      final InMemoryStore store = linkedStore(manual: true)
        ..upsertAccount(
          const Account(
            id: 'euro',
            type: AccountType.depository,
            name: 'Euro Account',
            currencyCode: 'EUR',
            isHidden: false,
            displayOrder: 9,
          ),
        );
      await pumpApp(tester, overrides: [storeOverride(store)]);

      // Manual 4,925.91 - 5.75, reported 1,100.00 (not the checking's derived
      // 2,437.45), and the card never synced 0.
      expect(find.text(r'$6,020.16'), findsOneWidget);
      expect(find.text('reported and from transactions'), findsOneWidget);
    });
  });

  group('the detail', () {
    testWidgets('a linked account shows its institution and reported balance', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialLocation: '/accounts/$linkedCheckingId',
        overrides: [storeOverride(linkedStore())],
      );

      expect(find.text('First Platypus Bank'), findsOneWidget);
      expect(
        find.text('Plaid Gold Standard 0% Interest Checking · •••• 0000'),
        findsOneWidget,
      );
      expect(find.text(r'$1,100.00'), findsOneWidget);
      expect(find.text('reported by First Platypus Bank'), findsOneWidget);
      // A no-break space before the period (formatDateTime).
      expect(
        find.textContaining(RegExp('^as of Oct 24, 2026 2:00\u00a0PM\$')),
        findsOneWidget,
      );
      expect(find.text(r'Available $1,000.00'), findsOneWidget);
      expect(find.text('from transactions'), findsNothing);
    });

    testWidgets('running balances work back from the reported balance', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialLocation: '/accounts/$linkedCheckingId',
        overrides: [storeOverride(linkedStore())],
      );

      // The newest row ends at the reported 1,100.00.
      expect(
        find.text(r'Running balance $1,100.00, from the reported balance'),
        findsOneWidget,
      );
      expect(
        find.textContaining(RegExp(r'^Running balance \$[0-9,.]+$')),
        findsNothing,
      );
    });

    testWidgets('a manual account sums its running balances', (tester) async {
      await pumpApp(
        tester,
        initialLocation: '/accounts/$checkingId',
        overrides: [storeOverride(linkedStore(manual: true))],
      );

      expect(find.text(r'Running balance $4,925.91'), findsOneWidget);
      expect(find.textContaining('from the reported balance'), findsNothing);
    });

    testWidgets('the as-of time is in the device zone', (tester) async {
      final Clock newYork = FixedClock(
        DateTime.utc(2026, 10, 24, 15),
        tz.getLocation('America/New_York'),
      );
      await pumpApp(
        tester,
        initialLocation: '/accounts/$linkedCheckingId',
        clock: newYork,
        overrides: [storeOverride(linkedStore())],
      );

      expect(
        find.textContaining(RegExp('^as of Oct 24, 2026 10:00\u00a0AM\$')),
        findsOneWidget,
      );
    });

    testWidgets('the mask is read as the digits it ends in', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await pumpApp(
          tester,
          initialLocation: '/accounts/$linkedCheckingId',
          overrides: [storeOverride(linkedStore())],
        );
        final String label = tester
            .getSemantics(find.textContaining('Plaid Gold'))
            .label;
        expect(
          label,
          contains('Plaid Gold Standard 0% Interest Checking · ending in 0000'),
        );
        expect(label, isNot(contains('•')));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('a linked account never synced shows its derived balance', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialLocation: '/accounts/$linkedCardId',
        overrides: [storeOverride(linkedStore())],
      );

      expect(find.text('Tartan Bank'), findsOneWidget);
      expect(find.text('•••• 3333'), findsOneWidget);
      expect(find.text('from transactions'), findsOneWidget);
      expect(find.textContaining('reported'), findsNothing);
      expect(find.textContaining('as of'), findsNothing);
    });

    testWidgets(
      'a manual account shows no institution and its derived balance',
      (tester) async {
        await pumpApp(
          tester,
          initialLocation: '/accounts/$checkingId',
          overrides: [storeOverride(linkedStore(manual: true))],
        );

        expect(find.text('First Platypus Bank'), findsNothing);
        expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
        expect(find.text('from transactions'), findsOneWidget);
        await tester.tap(find.byTooltip('Show menu'));
        await tester.pumpAndSettle();
        expect(find.text('Linked banks'), findsNothing);
        expect(find.text('Delete'), findsOneWidget);
      },
    );

    testWidgets("the menu opens the linked banks, to sync the account's bank", (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialLocation: '/accounts/$linkedCheckingId',
        overrides: [storeOverride(linkedStore())],
      );

      await tester.tap(find.byTooltip('Show menu'));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsNothing);
      await tester.tap(find.text('Linked banks'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Linked banks'), findsOneWidget);
      expect(find.text('Sync now'), findsWidgets);
    });
  });
}
