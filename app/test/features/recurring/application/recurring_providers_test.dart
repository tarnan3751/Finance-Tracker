// The recurring providers over the in-memory repository: the streams with their
// overrides, the subscriptions (active, unmuted, counted as one by the user or the
// app) with each annual cost, and the actions writing one field each.
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/recurring/application/recurring_providers.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/domain/stream_override.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:finance_tracker/features/recurring/domain/subscriptions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../contract/recurring_stream_repository_contract.dart';

void main() {
  late ProviderContainer container;
  late RecurringStreamRepository streams;

  setUp(() {
    container = ProviderContainer();
    streams = container.read(recurringStreamRepositoryProvider);
  });
  tearDown(() => container.dispose());

  // The provider's value once it has settled, kept listened to for the test.
  Future<List<StreamView>> allStreams() async {
    final sub = container.listen(recurringStreamsProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    return container.read(recurringStreamsProvider.future);
  }

  Future<List<Subscription>> allSubscriptions() async {
    final sub = container.listen(subscriptionsProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    return container.read(subscriptionsProvider.future);
  }

  test('the streams, with their overrides, in the repository order', () async {
    await streams.applyPlaid([
      testStream('s2', merchant: 'spotify'),
      testStream('s1', merchant: 'Netflix'),
    ]);
    await container.read(streamActionsProvider).mute('s2', muted: true);
    final List<StreamView> all = await allStreams();
    expect(
      [for (final StreamView v in all) (v.stream.id, v.muted)],
      [('s1', false), ('s2', true)],
    );
  });

  test('subscriptions: active and unmuted ones, the user\'s answer first, with '
      'a positive annual cost by cadence', () async {
    await streams.applyPlaid([
      testStream(
        'weekly',
        cadence: RecurringCadence.weekly,
        isSubscription: true,
        amount: -500,
      ),
      testStream(
        'biweekly',
        cadence: RecurringCadence.biweekly,
        isSubscription: true,
        amount: -500,
      ),
      testStream(
        'semi',
        cadence: RecurringCadence.semiMonthly,
        isSubscription: true,
        amount: -500,
      ),
      testStream('monthly', isSubscription: true, amount: -1549),
      testStream(
        'quarterly',
        cadence: RecurringCadence.quarterly,
        isSubscription: true,
        amount: -3000,
      ),
      testStream(
        'annual',
        cadence: RecurringCadence.annually,
        isSubscription: true,
        amount: -9900,
      ),
      testStream(
        'unknown',
        cadence: RecurringCadence.unknown,
        isSubscription: true,
      ),
      testStream(
        'ended',
        isSubscription: true,
      ).copyWith(status: RecurringStatus.ended),
      testStream('muted', isSubscription: true),
      testStream('rent', amount: -185000),
      testStream('gym', amount: -4000),
    ]);
    final StreamActions actions = container.read(streamActionsProvider);
    await actions.mute('muted', muted: true);
    await actions.setSubscription('gym', true);
    await actions.setSubscription('annual', null);
    final List<Subscription> subs = await allSubscriptions();
    expect(
      {for (final Subscription s in subs) s.view.stream.id: s.annualCost},
      {
        'annual': Money(9900, 'USD'),
        'biweekly': Money(13000, 'USD'),
        'gym': Money(48000, 'USD'),
        'monthly': Money(18588, 'USD'),
        'quarterly': Money(12000, 'USD'),
        'semi': Money(12000, 'USD'),
        'unknown': null,
        'weekly': Money(26000, 'USD'),
      },
    );
  });

  test('rename trims, and a blank name restores the merchant\'s; reset clears '
      'every choice', () async {
    await streams.applyPlaid([testStream('s1')]);
    final StreamActions actions = container.read(streamActionsProvider);
    await actions.rename('s1', '  Movies  ');
    expect((await streams.watchById('s1').first)!.displayName, 'Movies');
    await actions.setSubscription('s1', true);
    await actions.rename('s1', '   ');
    expect(
      (await streams.watchById('s1').first)!.userOverride,
      const StreamOverride(isSubscription: true),
    );
    await actions.reset('s1');
    expect((await streams.watchById('s1').first)!.userOverride, isNull);
  });
}
