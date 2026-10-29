// The subscriptions screen on the stream seed (stream_seed.dart): the yearly total of
// the known costs, the order by yearly cost with the irregular one last, the detected
// caption, the folded Muted and Other recurring sections, Mute, Not a subscription, Mark
// as subscription and Rename each with an Undo that restores the earlier choice, Create a
// bill opening the editor prefilled (saved only by Save), the empty state, and opening
// from the Bills segment.
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/bills/data/in_memory_bill_repository.dart';
import 'package:finance_tracker/features/recurring/data/in_memory_recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';
import '../../../helpers/stream_seed.dart';

void main() {
  late InMemoryRecurringStreamRepository streams;
  late InMemoryBillRepository bills;

  Future<void> open(
    WidgetTester tester, {
    List<RecurringStream>? initial,
    String location = '/bills/subscriptions',
  }) async {
    streams = seededStreams(initial);
    addTearDown(streams.close);
    bills = InMemoryBillRepository(
      testClock,
      recorder: const NoChangeRecorder(),
    );
    addTearDown(bills.close);
    await pumpApp(
      tester,
      initialLocation: location,
      overrides: [
        storeOverride(seededStore()),
        streamsOverride(streams),
        billRepositoryProvider.overrideWithValue(bills),
      ],
    );
  }

  Future<StreamView?> view(WidgetTester tester, String id) =>
      tester.runAsync<StreamView?>(() => streams.watchById(id).first);

  Future<void> choose(WidgetTester tester, String name, String item) async {
    await tester.tap(find.byTooltip('Actions for $name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  Future<void> undo(WidgetTester tester) async {
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
  }

  testWidgets('totals the known yearly costs and orders by them', (
    tester,
  ) async {
    await open(tester);

    expect(find.text(r'$620.76 a year across 4 subscriptions'), findsOneWidget);
    final List<double> tops = [
      for (final String name in [
        'Gym',
        'Netflix',
        'Newspaper',
        'iCloud',
        'Patreon',
      ])
        tester.getTopLeft(find.text(name)).dy,
    ];
    expect(tops, [...tops]..sort());
    expect(find.text(r'Monthly, $15.49 each'), findsOneWidget);
    expect(find.text(r'$185.88 a year'), findsOneWidget);
    expect(find.text(r'Irregular, $5.00 each'), findsOneWidget);
    // Only iCloud was detected from the transactions.
    expect(find.text('Detected from your transactions'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Detected from your transactions')).dy,
      greaterThan(tester.getTopLeft(find.text('iCloud')).dy),
    );
    // The ended stream is nowhere; the muted and other ones are folded.
    expect(find.text('Magazine'), findsNothing);
    expect(find.text('Hulu'), findsNothing);
    expect(find.text('Electric'), findsNothing);
    expect(find.text('Muted (1)'), findsOneWidget);
    expect(find.text('Other recurring (1)'), findsOneWidget);
  });

  testWidgets('mutes a subscription, and Undo unmutes it', (tester) async {
    await open(tester);

    await choose(tester, 'Netflix', 'Mute');
    expect(find.text('Netflix muted'), findsOneWidget);
    expect((await view(tester, 'stream-netflix'))!.muted, isTrue);
    expect(find.text('Muted (2)'), findsOneWidget);
    expect(find.text(r'$434.88 a year across 3 subscriptions'), findsOneWidget);

    await undo(tester);
    expect((await view(tester, 'stream-netflix'))!.muted, isFalse);
    expect(find.text('Muted (1)'), findsOneWidget);
  });

  testWidgets('unmutes from the folded Muted section', (tester) async {
    await open(tester);

    await tester.tap(find.text('Muted (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Hulu'), findsOneWidget);
    await choose(tester, 'Hulu', 'Unmute');
    expect(find.text('Hulu unmuted'), findsOneWidget);
    expect((await view(tester, 'stream-hulu'))!.muted, isFalse);
    expect(find.text('Muted (1)'), findsNothing);
  });

  testWidgets(
    'Not a subscription moves it to Other recurring; Undo restores the '
    'app\'s classification',
    (tester) async {
      await open(tester);

      await choose(tester, 'Gym', 'Not a subscription');
      expect(
        find.text('Gym is no longer counted as a subscription'),
        findsOneWidget,
      );
      expect(
        (await view(tester, 'stream-gym'))!.userOverride!.isSubscription,
        isFalse,
      );
      expect(find.text('Other recurring (2)'), findsOneWidget);

      await undo(tester);
      // The earlier choice was none, so the classification is the app's again.
      expect(
        (await view(tester, 'stream-gym'))!.userOverride!.isSubscription,
        isNull,
      );
      expect(find.text('Gym'), findsOneWidget);
    },
  );

  testWidgets('Mark as subscription from Other recurring, with Undo', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.text('Other recurring (1)'));
    await tester.pumpAndSettle();
    // The payroll is an inflow, never offered as a subscription.
    expect(find.text('Payroll'), findsNothing);
    await choose(tester, 'Electric', 'Mark as subscription');
    expect(find.text('Electric is counted as a subscription'), findsOneWidget);
    expect(
      (await view(tester, 'stream-electric'))!.userOverride!.isSubscription,
      isTrue,
    );
    expect(
      find.text(r'$1,631.16 a year across 5 subscriptions'),
      findsOneWidget,
    );
    expect(find.text('Other recurring (1)'), findsNothing);

    await undo(tester);
    expect(
      (await view(tester, 'stream-electric'))!.userOverride!.isSubscription,
      isNull,
    );
    expect(find.text('Other recurring (1)'), findsOneWidget);
  });

  testWidgets('renames a stream, blank restores the merchant, Undo the earlier '
      'name', (tester) async {
    await open(tester);

    await choose(tester, 'Netflix', 'Rename');
    await tester.enterText(find.byType(TextField), 'Films');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Renamed to Films'), findsOneWidget);
    expect((await view(tester, 'stream-netflix'))!.displayName, 'Films');

    await choose(tester, 'Films', 'Rename');
    expect(find.text('Leave empty to use Netflix'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Renamed to Netflix'), findsOneWidget);
    expect(
      (await view(tester, 'stream-netflix'))!.userOverride!.displayName,
      isNull,
    );

    await undo(tester);
    expect((await view(tester, 'stream-netflix'))!.displayName, 'Films');

    await choose(tester, 'Films', 'Rename');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect((await view(tester, 'stream-netflix'))!.displayName, 'Films');
  });

  testWidgets('saving the merchant\'s own name stores no override', (
    tester,
  ) async {
    await open(tester);

    // Prefilled with "Netflix", saved unchanged.
    await choose(tester, 'Netflix', 'Rename');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await view(tester, 'stream-netflix'))!.userOverride, isNull);
    expect(find.text('Undo'), findsNothing);

    // A name typed equal to the merchant's clears an earlier one.
    await choose(tester, 'Netflix', 'Rename');
    await tester.enterText(find.byType(TextField), 'Films');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await choose(tester, 'Films', 'Rename');
    await tester.enterText(find.byType(TextField), ' Netflix ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      (await view(tester, 'stream-netflix'))!.userOverride!.displayName,
      isNull,
    );
    expect(find.text('Renamed to Netflix'), findsOneWidget);
  });

  testWidgets(
    'Create a bill opens the editor prefilled and saves only on Save',
    (tester) async {
      await open(tester);

      // Only a stream with a suggestion offers it.
      await tester.tap(find.byTooltip('Actions for Gym'));
      await tester.pumpAndSettle();
      expect(find.text('Create a bill'), findsNothing);
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      await choose(tester, 'Netflix', 'Create a bill');
      expect(find.widgetWithText(AppBar, 'New bill'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Netflix'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '15.49'), findsOneWidget);
      expect(find.text('Nov 3, 2026'), findsOneWidget);
      expect((await tester.runAsync(() => bills.watchAll().first))!, isEmpty);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final BillReminder bill = (await tester.runAsync(
        () => bills.watchAll().first,
      ))!.single;
      expect(bill.name, 'Netflix');
      expect(bill.amount, Money(-1549, 'USD'));
      expect(bill.dueDate, LocalDate(2026, 11, 3));
      expect(bill.cadence, RecurringCadence.monthly);
      expect(bill.accountId, checkingId);
      expect(bill.streamId, 'stream-netflix');
      expect(find.widgetWithText(AppBar, 'Subscriptions'), findsOneWidget);
    },
  );

  testWidgets('says when there is nothing recurring', (tester) async {
    await open(tester, initial: const []);

    expect(find.text('No subscriptions yet'), findsOneWidget);
  });

  testWidgets('opens from the Bills segment', (tester) async {
    await open(tester, location: '/bills');

    await tester.tap(find.byTooltip('Subscriptions'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Subscriptions'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
  });
}
