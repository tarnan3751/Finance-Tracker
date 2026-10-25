// The duplicate review: the pairs as cards with both transactions; "Hide this one" hides
// that transaction, which ends the pair, with an undo that shows it again; "Not
// duplicates" removes a pair with an undo that brings it back; the empty state; the way in from the
// transaction list's menu, whose badge counts the pairs; and the pairs against the
// accessibility guidelines, in light and dark and at twice the text size
// (test/accessibility_test.dart checks the screen on the shared seed).
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/duplicates/data/in_memory_dismissed_pair_store.dart';
import 'package:finance_tracker/features/duplicates/domain/duplicate_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/duplicate_seed.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

void main() {
  testWidgets('each pair shows both transactions; not duplicates has an undo', (
    tester,
  ) async {
    final InMemoryDismissedPairStore dismissed = InMemoryDismissedPairStore();
    addTearDown(dismissed.close);
    await pumpApp(
      tester,
      initialLocation: '/transactions/duplicates',
      overrides: [
        storeOverride(duplicateStore()),
        dismissedPairStoreProvider.overrideWithValue(dismissed),
      ],
      size: const Size(412, 1600),
    );
    expect(find.text('Review duplicates'), findsOneWidget);
    expect(find.text('Same amount, same day'), findsNothing);
    expect(find.text('Same amount, 1 day apart'), findsNWidgets(2));
    expect(find.text('Blue Bottle'), findsOneWidget);
    expect(find.text('Blue Bottle Coffee'), findsOneWidget);
    expect(find.text('Hide this one'), findsNWidgets(4));
    await tester.tap(find.text('Not duplicates').first);
    await tester.pumpAndSettle();
    expect(find.text('Marked as not duplicates'), findsOneWidget);
    expect(find.text('Not duplicates'), findsOneWidget);
    expect(await tester.runAsync(() => dismissed.watch().first), hasLength(1));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Not duplicates'), findsNWidgets(2));
    expect(await tester.runAsync(() => dismissed.watch().first), isEmpty);
  });

  testWidgets('hide this one hides that transaction, with an undo', (
    tester,
  ) async {
    final InMemoryStore store = duplicateStore();
    await pumpApp(
      tester,
      initialLocation: '/transactions/duplicates',
      overrides: [storeOverride(store)],
      size: const Size(412, 1600),
    );
    // The first card's second row is the manual entry, Blue Bottle.
    await tester.tap(find.text('Hide this one').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Transaction hidden'), findsOneWidget);
    expect(store.transaction('manual-coffee')!.hidden, isTrue);
    expect(find.text('Blue Bottle'), findsNothing);
    expect(find.text('Not duplicates'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(store.transaction('manual-coffee')!.hidden, isFalse);
    expect(find.text('Not duplicates'), findsNWidgets(2));
  });

  testWidgets('a dismissed pair stays out', (tester) async {
    final InMemoryDismissedPairStore dismissed = InMemoryDismissedPairStore();
    addTearDown(dismissed.close);
    await dismissed.dismiss(PairKey('manual-coffee', 'demo-txn-12'));
    await dismissed.dismiss(PairKey('manual-netflix', 'demo-txn-06'));
    await pumpApp(
      tester,
      initialLocation: '/transactions/duplicates',
      overrides: [
        storeOverride(duplicateStore()),
        dismissedPairStoreProvider.overrideWithValue(dismissed),
      ],
    );
    expect(find.text('No likely duplicates'), findsOneWidget);
  });

  testWidgets('the test seed alone has nothing to review', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/transactions/duplicates',
      overrides: [storeOverride(seededStore())],
    );
    expect(find.text('No likely duplicates'), findsOneWidget);
  });

  testWidgets('the transaction list\'s menu counts the pairs and opens the '
      'review', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/transactions',
      overrides: [storeOverride(duplicateStore())],
    );
    expect(find.byTooltip('More options, 2 likely duplicates'), findsOneWidget);
    await tester.tap(find.byTooltip('More options, 2 likely duplicates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review duplicates (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Same amount, 1 day apart'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('More options, 2 likely duplicates'), findsOneWidget);
  });

  testWidgets('with no pairs the menu has no badge', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/transactions',
      overrides: [storeOverride(seededStore())],
    );
    expect(find.byTooltip('More options'), findsOneWidget);
    final Badge badge = tester.widget(
      find.ancestor(
        of: find.byIcon(Icons.more_vert),
        matching: find.byType(Badge),
      ),
    );
    expect(badge.isLabelVisible, isFalse);
  });

  for (final Brightness brightness in Brightness.values) {
    testWidgets('the pairs (${brightness.name}) meet the Android and contrast '
        'guidelines', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await pumpApp(
          tester,
          initialLocation: '/transactions/duplicates',
          brightness: brightness,
          overrides: [storeOverride(duplicateStore())],
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('the pairs lay out at text scale 2.0 without overflow', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/transactions/duplicates',
      textScale: 2,
      overrides: [storeOverride(duplicateStore())],
    );
    expect(tester.takeException(), isNull);
  });
}
