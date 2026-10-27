// The detector runner and the merged list over the in-memory repositories: the detected
// streams follow the transactions, are classified, give way to the server's streams
// that cover them, run the same on a background isolate, and settle on the latest
// input when changes arrive during a run; the merged list classifies the server's
// streams and lets the user's override win.
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/recurring/application/detector_runner.dart';
import 'package:finance_tracker/features/recurring/application/merged_streams.dart';
import 'package:finance_tracker/features/recurring/application/recurring_providers.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:finance_tracker/features/recurring/domain/subscriptions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../contract/recurring_stream_repository_contract.dart';
import '../../../contract/repository_fixture.dart';

const Category tv = Category(
  id: 'tv',
  name: 'TV',
  isSystem: false,
  icon: 'i',
  color: 0,
);

final LocalDate today = LocalDate(2026, 6, 10);

/// [count] monthly Netflix charges on the 7th from January 2026, ids `n0`, `n1`, ...
List<Transaction> netflix(int count, {int minor = -1549}) => [
  for (int i = 0; i < count; i++)
    testTransaction(
      'n$i',
      'a1',
      minor,
      date: LocalDate(2026, 1 + i, 7),
      name: 'NETFLIX.COM',
      merchantName: 'Netflix',
      userCategoryId: 'tv',
    ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late RecurringStreamRepository streams;

  ProviderContainer create({int threshold = 2000}) {
    final ProviderContainer c = ProviderContainer.test(
      overrides: [
        clockProvider.overrideWithValue(
          FixedClock(DateTime.utc(2026, 6, 10, 12), tz.UTC),
        ),
        detectorDebounceProvider.overrideWithValue(
          const Duration(milliseconds: 20),
        ),
        detectorIsolateThresholdProvider.overrideWithValue(threshold),
      ],
    );
    streams = c.read(recurringStreamRepositoryProvider);
    return c;
  }

  Future<void> seed(ProviderContainer c, List<Transaction> rows) async {
    await c.read(accountRepositoryProvider).upsert(testAccount('a1'));
    await c.read(categoryRepositoryProvider).upsert(tv);
    await c.read(transactionRepositoryProvider).upsertAll(rows);
  }

  // The stored streams once the runner has settled.
  Future<List<StreamView>> settled() async {
    for (int i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    return streams.watchAll().first;
  }

  Future<List<StreamView>> merged() async {
    final sub = container.listen(mergedStreamsProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    return container.read(mergedStreamsProvider.future);
  }

  tearDown(() => container.dispose());

  test('nothing runs unless something listens', () async {
    container = create();
    await seed(container, netflix(4));
    expect(await settled(), isEmpty);
  });

  test('the detected streams follow the transactions, classified', () async {
    container = create();
    await seed(container, netflix(4));
    container.listen(detectorRunnerProvider, (_, _) {});
    final StreamView view = (await settled()).single;
    expect(view.stream.source, RecurringSource.detected);
    expect(view.stream.cadence, RecurringCadence.monthly);
    expect(view.stream.transactionIds, ['n0', 'n1', 'n2', 'n3']);
    expect(view.stream.isSubscription, isTrue);

    await container.read(transactionRepositoryProvider).deleteAll(['n2', 'n3']);
    expect(await settled(), isEmpty);
  });

  test('the same result on a background isolate', () async {
    container = create(threshold: 0);
    await seed(container, netflix(4));
    container.listen(detectorRunnerProvider, (_, _) {});
    final StreamView view = (await settled()).single;
    expect(view.stream.transactionIds, ['n0', 'n1', 'n2', 'n3']);
    expect(view.stream.isSubscription, isTrue);
  });

  test(
    'a server stream covering the transactions replaces the detected one',
    () async {
      container = create();
      await seed(container, netflix(4));
      container.listen(detectorRunnerProvider, (_, _) {});
      expect(await settled(), hasLength(1));
      await streams.applyPlaid([
        testStream('plaid-1', transactionIds: const ['n3']),
      ]);
      expect(
        [for (final StreamView v in await settled()) v.stream.id],
        ['plaid-1'],
      );
    },
  );

  test('changes during a run settle on the latest input', () async {
    container = create();
    await seed(container, netflix(3));
    container.listen(detectorRunnerProvider, (_, _) {});
    for (int i = 3; i < 6; i++) {
      await container.read(transactionRepositoryProvider).upsert(netflix(6)[i]);
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    expect((await settled()).single.stream.transactionIds, [
      'n0',
      'n1',
      'n2',
      'n3',
      'n4',
      'n5',
    ]);
  });

  group('the merged list', () {
    test(
      'classifies a server stream over its members; the override wins',
      () async {
        container = create();
        await seed(container, netflix(4));
        await streams.applyPlaid([
          testStream('plaid-1', transactionIds: const ['n0', 'n1', 'n2', 'n3']),
        ]);
        expect((await merged()).single.isSubscription, isTrue);
        final sub = container.listen(subscriptionsProvider, (_, _) {});
        addTearDown(sub.close);
        await pumpEventQueue();
        final List<Subscription> subscriptions = await container.read(
          subscriptionsProvider.future,
        );
        expect(subscriptions.single.view.stream.id, 'plaid-1');

        await container
            .read(streamActionsProvider)
            .setSubscription('plaid-1', false);
        expect((await merged()).single.isSubscription, isFalse);
      },
    );

    test(
      'a server stream is classified on its newest price step and its cadence',
      () async {
        container = create();
        await seed(container, [
          ...netflix(2),
          ...netflix(4, minor: -1999).skip(2),
        ]);
        await streams.applyPlaid([
          testStream('plaid-1', transactionIds: const ['n0', 'n1', 'n2', 'n3']),
        ]);
        // The newest price step is stable: still a subscription.
        expect((await merged()).single.isSubscription, isTrue);
        await streams.applyPlaid([
          testStream(
            'plaid-1',
            cadence: RecurringCadence.biweekly,
            transactionIds: const ['n0', 'n1', 'n2', 'n3'],
          ),
        ]);
        expect((await merged()).single.isSubscription, isFalse);
      },
    );

    test('drops a stored detected stream a server stream now covers', () async {
      container = create();
      await seed(container, netflix(4));
      await streams.replaceDetected([
        testStream(
          'detected-1',
          source: RecurringSource.detected,
          transactionIds: const ['n0', 'n1'],
        ),
      ]);
      await streams.applyPlaid([
        testStream('plaid-1', transactionIds: const ['n1']),
      ]);
      expect(
        [for (final StreamView v in await merged()) v.stream.id],
        ['plaid-1'],
      );
    });
  });
}
