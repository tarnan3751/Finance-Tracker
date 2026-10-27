// The contract every RecurringStreamRepository implementation passes: the in-memory,
// demo and Drift ones, each from its own test file under test/features/recurring/data/.
import 'package:finance_tracker/features/recurring/domain/recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/domain/stream_override.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'repository_fixture.dart';

/// A stream [id] from [source] at [merchant].
RecurringStream testStream(
  String id, {
  String merchant = 'Netflix',
  RecurringSource source = RecurringSource.plaid,
  int amount = -1549,
  String currency = 'USD',
  RecurringCadence cadence = RecurringCadence.monthly,
  bool isSubscription = false,
  List<String> transactionIds = const ['t1', 't2'],
}) => RecurringStream(
  id: id,
  accountId: 'acc-1',
  merchantName: merchant,
  cadence: cadence,
  averageAmount: Money(amount, currency),
  lastExpected: LocalDate(2026, 10, 1),
  nextExpected: LocalDate(2026, 11, 1),
  status: RecurringStatus.active,
  isSubscription: isSubscription,
  source: source,
  transactionIds: transactionIds,
);

/// Registers the contract tests for the fixtures [create] builds.
void runRecurringStreamRepositoryContract(
  Future<RepositoryFixture> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('RecurringStreamRepository contract', () {
    late RecurringStreamRepository streams;

    setUp(() async => streams = (await create()).streams);
    if (dispose != null) tearDown(dispose);

    Future<List<String>> ids() async => [
      for (final StreamView v in await streams.watchAll().first) v.stream.id,
    ];

    test('a fresh repository has no streams', () async {
      expect(await streams.watchAll().first, isEmpty);
      expect(await streams.watchById('s1').first, isNull);
    });

    test(
      'every field round-trips, each cadence and an unknown date included',
      () async {
        final List<RecurringStream> all = [
          for (final RecurringCadence c in RecurringCadence.values)
            testStream('s-${c.name}', cadence: c, isSubscription: true),
          testStream(
            's-bare',
            currency: 'EUR',
            transactionIds: const [],
          ).copyWith(lastExpected: null, nextExpected: null),
          testStream(
            's-ended',
            source: RecurringSource.demo,
          ).copyWith(status: RecurringStatus.ended),
        ];
        await streams.applyPlaid(all);
        for (final RecurringStream s in all) {
          expect(await streams.watchById(s.id).first, StreamView(s));
        }
      },
    );

    test(
      'streams are ordered by merchant ignoring ASCII case, then by id',
      () async {
        await streams.applyPlaid([
          testStream('s3', merchant: 'netflix'),
          testStream('s2', merchant: 'Netflix'),
          testStream('s1', merchant: 'Spotify'),
          testStream('s0', merchant: 'Acme Payroll', amount: 250000),
        ]);
        expect(await ids(), ['s0', 's2', 's3', 's1']);
      },
    );

    test('applyPlaid replaces the server\'s streams and leaves the detected '
        'ones', () async {
      await streams.replaceDetected([
        testStream('d1', merchant: 'Gym', source: RecurringSource.detected),
      ]);
      await streams.applyPlaid([
        testStream('p1'),
        testStream('p2', merchant: 'Spotify', source: RecurringSource.demo),
      ]);
      expect(await ids(), ['d1', 'p1', 'p2']);
      final RecurringStream changed = testStream('p1', amount: -1699);
      await streams.applyPlaid([changed]);
      expect(await ids(), ['d1', 'p1']);
      expect((await streams.watchById('p1').first)!.stream, changed);
      await streams.applyPlaid(const []);
      expect(await ids(), ['d1']);
    });

    test('replaceDetected replaces the detected streams and leaves the '
        'server\'s', () async {
      await streams.applyPlaid([testStream('p1')]);
      await streams.replaceDetected([
        testStream('d1', merchant: 'Gym', source: RecurringSource.detected),
        testStream('d2', merchant: 'Rent', source: RecurringSource.detected),
      ]);
      await streams.replaceDetected([
        testStream('d2', merchant: 'Rent', source: RecurringSource.detected),
      ]);
      expect(await ids(), ['p1', 'd2']);
    });

    test('a stream of the wrong source, or a repeated id, is refused and '
        'nothing is written', () async {
      await streams.applyPlaid([testStream('p1')]);
      for (final RecurringSource wrong in [
        RecurringSource.detected,
        RecurringSource.user,
      ]) {
        await expectLater(
          streams.applyPlaid([
            testStream('p2'),
            testStream('x', source: wrong),
          ]),
          throwsArgumentError,
        );
      }
      await expectLater(
        streams.applyPlaid([testStream('p2'), testStream('p2')]),
        throwsArgumentError,
      );
      for (final RecurringSource wrong in [
        RecurringSource.plaid,
        RecurringSource.demo,
        RecurringSource.user,
      ]) {
        await expectLater(
          streams.replaceDetected([testStream('x', source: wrong)]),
          throwsArgumentError,
        );
      }
      expect(await ids(), ['p1']);
    });

    test('an override resolves the view, and survives the server\'s '
        'replacement', () async {
      await streams.applyPlaid([testStream('p1', isSubscription: false)]);
      StreamView view = (await streams.watchById('p1').first)!;
      expect(
        (view.muted, view.isSubscription, view.displayName),
        (false, false, 'Netflix'),
      );
      await streams.setOverride('p1', (o) => o.withMuted(true));
      await streams.setOverride('p1', (o) => o.withSubscription(true));
      await streams.setOverride('p1', (o) => o.withDisplayName('TV'));
      await streams.applyPlaid([testStream('p1', amount: -1699)]);
      view = (await streams.watchById('p1').first)!;
      expect(
        view.userOverride,
        const StreamOverride(
          muted: true,
          isSubscription: true,
          displayName: 'TV',
        ),
      );
      expect(
        (view.muted, view.isSubscription, view.displayName),
        (true, true, 'TV'),
      );
      expect(view.stream.averageAmount, Money(-1699, 'USD'));

      await streams.setOverride('p1', (o) => o.withSubscription(null));
      view = (await streams.watchById('p1').first)!;
      expect(view.isSubscription, isFalse, reason: 'the stream\'s own again');
      expect((await streams.watchAll().first).single, view);
    });

    test('the change sees the current override', () async {
      await streams.applyPlaid([testStream('p1')]);
      final List<StreamOverride> seen = [];
      StreamOverride Function(StreamOverride) keep(
        StreamOverride Function(StreamOverride) change,
      ) => (o) {
        seen.add(o);
        return change(o);
      };
      await streams.setOverride('p1', keep((o) => o.withMuted(true)));
      await streams.setOverride('p1', keep((o) => o.withDisplayName('TV')));
      expect(seen, [const StreamOverride(), const StreamOverride(muted: true)]);
    });

    test('clearOverride removes the choices; a later set starts from the '
        'default', () async {
      await streams.applyPlaid([testStream('p1')]);
      await streams.clearOverride('p1');
      await streams.setOverride('p1', (o) => o.withMuted(true));
      await streams.setOverride('p1', (o) => o.withDisplayName('TV'));
      await streams.clearOverride('p1');
      await streams.clearOverride('p1');
      expect((await streams.watchById('p1').first)!.userOverride, isNull);
      await streams.setOverride('p1', (o) => o.withSubscription(true));
      expect(
        (await streams.watchById('p1').first)!.userOverride,
        const StreamOverride(isSubscription: true),
      );
    });

    test('an override may name a stream that is not stored', () async {
      await streams.setOverride('later', (o) => o.withMuted(true));
      expect(await streams.watchById('later').first, isNull);
      await streams.applyPlaid([testStream('later')]);
      expect((await streams.watchById('later').first)!.muted, isTrue);
    });

    test('watchers see each change once', () async {
      final List<List<String>> seen = [];
      final sub = streams.watchAll().listen(
        (all) => seen.add([
          for (final StreamView v in all) '${v.stream.id}:${v.muted}',
        ]),
      );
      addTearDown(sub.cancel);
      await pumpEventQueue();
      await streams.applyPlaid([testStream('p1')]);
      await pumpEventQueue();
      await streams.setOverride('p1', (o) => o.withMuted(true));
      await pumpEventQueue();
      await streams.setOverride('p1', (o) => o.withMuted(true));
      await pumpEventQueue();
      expect(seen, [
        <String>[],
        ['p1:false'],
        ['p1:true'],
      ]);
    });
  });
}
