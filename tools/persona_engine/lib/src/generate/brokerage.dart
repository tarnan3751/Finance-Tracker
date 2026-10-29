/// A retirement account, replayed from the day it opened: a deterministic daily price walk
/// per security, the rollover, and payroll contributions split across the securities by
/// weight. Before the window the replay only moves the position, which is the account's
/// opening; inside the window it records investment transactions. The position on any
/// date is the same whatever the window.
library;

import 'package:persona_engine/src/model/investments.dart';
import 'package:persona_engine/src/model/persona.dart';
import 'package:persona_engine/src/random/pcg32.dart';
import 'package:shared_models/shared_models.dart'
    hide Holding, InvestmentTransaction, Security;

/// The account's state through its life.
final class BrokerageBook {
  /// A book for a household as of [asOf] whose window starts on [first], replayed to the
  /// window's eve. Throws an [ArgumentError] when the account opens inside the window.
  BrokerageBook(
    this.spec,
    this.accountId,
    this._rng,
    LocalDate asOf,
    this.first,
  ) : opened = asOf.addMonths(-spec.openedMonthsBefore),
      _prices = [for (final s in spec.securities) s.startPrice],
      _quantities = List.filled(spec.securities.length, 0),
      _costs = [
        for (final s in spec.securities) Money(0, s.startPrice.currencyCode),
      ],
      _cash = Money(0, spec.contribution.currencyCode) {
    if (!opened.isBefore(first)) {
      throw ArgumentError('the brokerage opens on $opened, inside the window');
    }
    final eve = first.addDays(-1);
    final due = spec.schedule.occurrences(opened.addDays(1), eve).toSet();
    _contribute(opened, spec.rollover, 'ROLLOVER CONTRIBUTION', emit: false);
    for (var d = opened.addDays(1); !d.isAfter(eve); d = d.addDays(1)) {
      _walk();
      if (due.contains(d)) {
        _contribute(d, spec.contribution, 'PAYROLL CONTRIBUTION', emit: false);
      }
    }
    openingHoldings = holdings(eve);
    openingCash = _cash;
    _dueInWindow = spec.schedule.occurrences(first, asOf).toSet();
  }

  /// The account.
  final BrokerageSpec spec;

  /// Its id.
  final String accountId;

  /// The window's first day.
  final LocalDate first;

  /// The day it opened.
  final LocalDate opened;

  final Pcg32 _rng;
  final List<Money> _prices;
  final List<int> _quantities;
  final List<Money> _costs;
  Money _cash;
  late final Set<LocalDate> _dueInWindow;

  /// The position on the window's eve.
  late final List<Holding> openingHoldings;

  /// The uninvested cash on the window's eve.
  late final Money openingCash;

  /// The contributions and purchases inside the window, in order; ids are assigned by the
  /// generator.
  final List<InvestmentTransaction Function(String id)> pending = [];

  /// The uninvested cash.
  Money get cash => _cash;

  /// Moves every price one day; called at the start of each day in the window.
  void walk() => _walk();

  /// Contributes on [date] when it is a contribution date.
  void contributeIfDue(LocalDate date) {
    if (_dueInWindow.contains(date)) {
      _contribute(date, spec.contribution, 'PAYROLL CONTRIBUTION', emit: true);
    }
  }

  void _walk() {
    for (var i = 0; i < _prices.length; i++) {
      final s = spec.securities[i];
      final move =
          s.driftBasisPoints +
          _rng.nextIntInRange(-s.stepBasisPoints, s.stepBasisPoints);
      _prices[i] = _prices[i].multipliedBy(10000 + move, 10000);
    }
  }

  /// Adds [amount] as cash and buys each security's weighted share of the cash in
  /// thousandths of a share; what does not divide stays as cash.
  void _contribute(
    LocalDate date,
    Money amount,
    String name, {
    required bool emit,
  }) {
    _cash += amount;
    if (emit) {
      pending.add(
        (id) => InvestmentTransaction(
          id: id,
          accountId: accountId,
          date: date,
          name: name,
          type: InvestmentTransactionType.cash,
          amount: amount,
          source: DataSource.demo,
        ),
      );
    }
    final parts = _cash.allocate([for (final s in spec.securities) s.weight]);
    for (var i = 0; i < parts.length; i++) {
      final price = _prices[i];
      final quantity = parts[i].minorUnits * 1000 ~/ price.minorUnits;
      if (quantity == 0) continue;
      final cost = price.multipliedBy(quantity, 1000);
      _cash -= cost;
      _quantities[i] += quantity;
      _costs[i] += cost;
      if (!emit) continue;
      final s = spec.securities[i];
      pending.add(
        (id) => InvestmentTransaction(
          id: id,
          accountId: accountId,
          date: date,
          name: 'BUY ${s.ticker}',
          type: InvestmentTransactionType.buy,
          amount: cost,
          security: Security(s.ticker, s.name, price.currencyCode),
          quantityMilli: quantity,
          price: price,
          source: DataSource.demo,
        ),
      );
    }
  }

  /// The positions on [date] at the current prices.
  List<Holding> holdings(LocalDate date) => [
    for (var i = 0; i < _prices.length; i++)
      if (_quantities[i] > 0)
        Holding(
          accountId: accountId,
          security: Security(
            spec.securities[i].ticker,
            spec.securities[i].name,
            _prices[i].currencyCode,
          ),
          quantityMilli: _quantities[i],
          costBasis: _costs[i],
          price: _prices[i],
          priceAsOf: date,
        ),
  ];
}
