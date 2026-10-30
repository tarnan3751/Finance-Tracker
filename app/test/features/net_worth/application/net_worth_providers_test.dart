// The net worth providers over the in-memory repositories, on the net worth household
// (net_worth_seed.dart), as of 24 October 2026: the series the screen reads reproduced
// exactly from the stored rows by an independent fold (the Phase 6 acceptance
// criterion), the derived prefix before the first row, the series following a new
// snapshot, the liabilities' payoffs from the reported terms and the entries, and the
// entries kept in app_meta across a restart, validated, with a failed write undone.
import 'dart:convert';

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/net_worth/application/net_worth_providers.dart';
import 'package:finance_tracker/features/net_worth/domain/net_worth_series.dart';
import 'package:finance_tracker/features/net_worth/domain/payoff.dart';
import 'package:finance_tracker/features/net_worth/domain/payoff_entries.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/net_worth_seed.dart';
import '../../../helpers/pump_app.dart';

Money usd(int cents) => Money(cents, 'USD');

ProviderContainer container({AppMetaStore? meta}) {
  final ProviderContainer c = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.demo()),
      clockProvider.overrideWithValue(testClock),
      ...netWorthOverrides(),
      if (meta != null) appMetaStoreProvider.overrideWithValue(meta),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<Map<String, List<NetWorthPoint>>> series(ProviderContainer c) {
  addTearDown(c.listen(netWorthSeriesProvider, (_, _) {}).close);
  return c.read(netWorthSeriesProvider.future);
}

Future<List<LiabilityPayoff>> payoffsOf(ProviderContainer c) {
  addTearDown(c.listen(liabilityPayoffsProvider, (_, _) {}).close);
  return c.read(liabilityPayoffsProvider.future);
}

Future<Map<String, LiabilityPayoff>> payoffsById(ProviderContainer c) async => {
  for (final LiabilityPayoff p in await payoffsOf(c)) p.account.id: p,
};

Future<Map<String, PayoffEntry>> entriesOf(ProviderContainer c) =>
    c.read(payoffEntriesControllerProvider.future);

final class FailingMetaStore implements AppMetaStore {
  final InMemoryAppMetaStore _values = InMemoryAppMetaStore();
  bool fail = false;

  @override
  Future<String?> read(String key) => _values.read(key);

  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('disk full');
    await _values.write(key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the series shown reproduces exactly from the stored rows', () async {
    final ProviderContainer c = container();
    final List<NetWorthPoint> shown = (await series(c))['USD']!;
    final List<BalanceSnapshot> rows = await c
        .read(balanceSnapshotRepositoryProvider)
        .watchAll()
        .first;

    // The fold, independent of the code under test: per stored date, the asset
    // accounts' balances and the credit and loan accounts' balances negated.
    const Set<String> owing = {nwCardId, nwMortgageId, nwCarId};
    final Map<LocalDate, (int, int)> fold = {};
    for (final BalanceSnapshot r in rows) {
      final (int a, int l) = fold[r.date] ?? (0, 0);
      fold[r.date] = owing.contains(r.accountId)
          ? (a, l - r.current.minorUnits)
          : (a + r.current.minorUnits, l);
    }
    final List<NetWorthPoint> observed = [
      for (final NetWorthPoint p in shown)
        if (!p.derived) p,
    ];
    expect(observed.first.date, nwFirstSnapshot);
    expect(observed.last.date, testClock.today());
    expect(observed, hasLength(11));
    for (final NetWorthPoint p in observed) {
      final (int a, int l) = fold[p.date] ?? fold[p.date.addDays(-1)]!;
      expect(p.assets, usd(a), reason: '${p.date}');
      expect(p.liabilities, usd(l), reason: '${p.date}');
      expect(p.netWorth, usd(a - l), reason: '${p.date}');
      expect(p.carried, p.date == nwGap, reason: '${p.date}');
    }
    // Today by hand: the three loans' amounts owed; the 401(k) at its reported total
    // and checking at the balance its transactions give.
    final NetWorthPoint today = observed.last;
    expect(today.liabilities, usd(125000 + 28500000 + 1840000));
    expect(
      today.assets,
      usd(4200000) +
          Money.sum([
            for (final Transaction t in netWorthTransactions())
              if (t.accountId == nwCheckingId) t.amount,
          ]),
    );
    expect(
      observed[5],
      NetWorthPoint(
        date: nwGap,
        assets: observed[4].assets,
        liabilities: observed[4].liabilities,
        carried: true,
      ),
    );
  });

  test(
    'before the first row the history is derived from the transactions',
    () async {
      final ProviderContainer c = container();
      final List<NetWorthPoint> shown = (await series(c))['USD']!;
      final List<NetWorthPoint> prefix = [
        for (final NetWorthPoint p in shown)
          if (p.derived) p,
      ];
      expect(prefix.first.date, LocalDate(2026, 8, 1));
      expect(prefix.last.date, nwFirstSnapshot.addDays(-1));
      expect(prefix.every((p) => !p.carried), isTrue);
      // On 1 August checking holds its opening, the pay and less the rent; the card's
      // first purchase is on 3 August, so it holds what it owed before its purchases
      // up to 14 October; the mortgage, the car loan and the 401(k) are flat at their
      // 14 October rows.
      expect(
        prefix.first.assets,
        usd(420000 + 260000 - 215000 + 4200000 - 12000 * 10),
      );
      final Money cardPurchases = Money.sum([
        for (final Transaction t in netWorthTransactions())
          if (t.accountId == nwCardId && !t.date.isAfter(nwFirstSnapshot))
            t.amount,
      ]);
      expect(
        prefix.first.liabilities,
        usd(125000 + 28500000 + 1840000) + cardPurchases,
      );
      expect(prefix[1].liabilities, prefix.first.liabilities);
    },
  );

  test('a new snapshot moves the series', () async {
    final ProviderContainer c = container();
    await series(c);
    final LocalDate today = testClock.today();
    final List<BalanceSnapshot> todays = [
      for (final BalanceSnapshot r in netWorthSnapshots())
        if (r.date == today)
          r.accountId == nw401kId ? r.copyWith(current: usd(5000000)) : r,
    ];
    await c.read(balanceSnapshotRepositoryProvider).writeDay(today, todays);
    final NetWorthPoint last = (await series(c))['USD']!.last;
    expect(last.assets.minorUnits, greaterThan(5000000));
  });

  group('payoffs', () {
    test(
      'every credit and loan account that owes, from the reported terms',
      () async {
        final ProviderContainer c = container();
        final List<LiabilityPayoff> payoffs = await payoffsOf(c);
        // In the accounts' order: the manual car loan, then the linked ones.
        expect(payoffs.map((p) => p.account.id), [
          nwCarId,
          nwCardId,
          nwMortgageId,
        ]);
        final LiabilityPayoff card = payoffs[1];
        expect(card.terms.owed, usd(125000));
        expect(card.terms.rateBasisPoints, 2199);
        expect(card.terms.paymentKind, PayoffPaymentKind.minimum);
        expect(card.projection, isA<PaidOff>());
        final LiabilityPayoff mortgage = payoffs[2];
        expect(mortgage.terms.paymentKind, PayoffPaymentKind.monthly);
        expect(
          mortgage.projection,
          projectPayoff(
            owed: usd(28500000),
            rateBasisPoints: 625,
            payment: usd(215000),
            today: testClock.today(),
          ),
        );
        final LiabilityPayoff car = payoffs[0];
        expect(car.terms.owed, usd(1840000));
        expect(car.terms.rateBasisPoints, isNull);
        expect(car.projection, isNull);
      },
    );

    test(
      'entries fill what the bank does not report and survive a restart',
      () async {
        final InMemoryAppMetaStore meta = InMemoryAppMetaStore();
        final ProviderContainer c = container(meta: meta);
        await entriesOf(c);
        final PayoffEntriesController entries = c.read(
          payoffEntriesControllerProvider.notifier,
        );
        await entries.setRate(nwCarId, 489);
        await entries.setPayment(nwCarId, usd(42000));
        await entries.setExtra(nwCarId, usd(5000));
        // The mortgage reports its rate: an entered one is kept but not used.
        await entries.setRate(nwMortgageId, 100);

        final LiabilityPayoff car = (await payoffsById(c))[nwCarId]!;
        expect(car.terms.rateSource, PayoffInputSource.entered);
        expect(car.terms.paymentKind, PayoffPaymentKind.entered);
        final PaidOff base = car.projection! as PaidOff;
        final PaidOff more = car.withExtra! as PaidOff;
        expect(more.months, lessThan(base.months));
        expect(
          (await payoffsById(c))[nwMortgageId]!.terms.rateBasisPoints,
          625,
        );

        expect(jsonDecode((await meta.read(AppMetaKeys.payoffEntries))!), {
          nwCarId: {
            'payment': {'minor_units': 42000, 'currency': 'USD'},
            'rate_bp': 489,
            'extra': {'minor_units': 5000, 'currency': 'USD'},
          },
          nwMortgageId: {'rate_bp': 100},
        });

        final ProviderContainer restarted = container(meta: meta);
        final LiabilityPayoff again = (await payoffsById(restarted))[nwCarId]!;
        expect(again.projection, car.projection);
        expect(again.withExtra, car.withExtra);
      },
    );

    test('entries are validated, and a failed write is undone', () async {
      final FailingMetaStore meta = FailingMetaStore();
      final ProviderContainer c = container(meta: meta);
      await entriesOf(c);
      final PayoffEntriesController entries = c.read(
        payoffEntriesControllerProvider.notifier,
      );
      await expectLater(entries.setRate(nwCarId, 10001), throwsArgumentError);
      await expectLater(entries.setRate(nwCarId, -1), throwsArgumentError);
      await expectLater(
        entries.setPayment(nwCarId, usd(0)),
        throwsArgumentError,
      );
      await expectLater(
        entries.setExtra(nwCarId, usd(-1)),
        throwsArgumentError,
      );
      await entries.setRate(nwCarId, 10000);
      meta.fail = true;
      await expectLater(entries.setRate(nwCarId, 500), throwsStateError);
      expect(
        (await c.read(
          payoffEntriesControllerProvider.future,
        ))[nwCarId]!.rateBasisPoints,
        10000,
      );
      // An invalid stored entry is dropped, the others kept.
      final InMemoryAppMetaStore stored = InMemoryAppMetaStore();
      await stored.write(
        AppMetaKeys.payoffEntries,
        jsonEncode({
          'a': {'rate_bp': 20000},
          'b': {
            'payment': {'minor_units': 100, 'currency': 'USD'},
          },
          'c': 'nonsense',
        }),
      );
      final ProviderContainer other = container(meta: stored);
      expect((await entriesOf(other)).keys, ['b']);
    });
  });
}
