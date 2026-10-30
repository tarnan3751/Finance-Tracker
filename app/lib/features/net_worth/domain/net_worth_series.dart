/// The observed net worth series (`docs/reference/net-worth.md`, **The series**;
/// `PLAN.md` §12 "Balance snapshots and net worth", "6b plan rulings"), computed from the
/// stored balance snapshots alone. Pure Dart, integer `Money` only.
///
/// For each currency, one point per day from the first date any snapshot in it is stored
/// for to the last:
///
/// - on a day with snapshots, assets are the sum of the day's balances of asset accounts
///   (depository, investment, other) and liabilities the sum of the day's balances of
///   credit and loan accounts negated, both signed, so an overdraft lowers the assets, a
///   card in credit lowers the liabilities, and net worth (assets − liabilities) is the
///   sum of the day's balances exactly. A snapshot of an account that is no longer live
///   (its type unknown) is an asset when its balance is not negative, else a liability;
/// - a day without snapshots (the app did not run) carries the previous point's values,
///   marked `carried`.
library;

import 'package:shared_models/shared_models.dart';

/// Net worth on one day: what [assets] and [liabilities] (owed, positive when owed) were,
/// whether the point was reconstructed from transactions ([derived], `source: derived`
/// in `PLAN.md` §7.1's terms, labelled in the UI) and whether it carries an earlier day's
/// values because no snapshot was stored for its own ([carried]).
final class NetWorthPoint {
  /// A point.
  const NetWorthPoint({
    required this.date,
    required this.assets,
    required this.liabilities,
    this.derived = false,
    this.carried = false,
  });

  final LocalDate date;
  final Money assets;
  final Money liabilities;
  final bool derived;
  final bool carried;

  /// Assets less liabilities.
  Money get netWorth => assets - liabilities;

  @override
  bool operator ==(Object other) =>
      other is NetWorthPoint &&
      other.date == date &&
      other.assets == assets &&
      other.liabilities == liabilities &&
      other.derived == derived &&
      other.carried == carried;

  @override
  int get hashCode => Object.hash(date, assets, liabilities, derived, carried);

  @override
  String toString() =>
      'NetWorthPoint($date, assets: $assets, liabilities: $liabilities'
      '${derived ? ', derived' : ''}${carried ? ', carried' : ''})';
}

/// Whether an account of [type] counts among the liabilities: credit and loan accounts
/// do; with no [type] (an account no longer live), a negative [balance] does.
bool isLiability(AccountType? type, Money balance) => switch (type) {
  AccountType.credit || AccountType.loan => true,
  AccountType.depository ||
  AccountType.investment ||
  AccountType.other => false,
  null => balance.isNegative,
};

/// The point on [date] of [balances] (each an account's balance with its account's type,
/// null when unknown), all in [currencyCode].
NetWorthPoint pointOf(
  LocalDate date,
  Iterable<(AccountType?, Money)> balances,
  String currencyCode, {
  bool derived = false,
}) {
  Money assets = Money.zero(currencyCode);
  Money liabilities = Money.zero(currencyCode);
  for (final (AccountType? type, Money balance) in balances) {
    if (isLiability(type, balance)) {
      liabilities -= balance;
    } else {
      assets += balance;
    }
  }
  return NetWorthPoint(
    date: date,
    assets: assets,
    liabilities: liabilities,
    derived: derived,
  );
}

/// The observed series per currency code (see the library comment) from [snapshots] and
/// the live accounts' types [typeOf] (account id to type). Each list is by date, one
/// point per day, none `derived`.
Map<String, List<NetWorthPoint>> observedNetWorth(
  Iterable<BalanceSnapshot> snapshots,
  Map<String, AccountType> typeOf,
) {
  final Map<String, Map<LocalDate, List<BalanceSnapshot>>> byCurrency = {};
  for (final BalanceSnapshot s in snapshots) {
    (byCurrency[s.current.currencyCode] ??= {})
        .putIfAbsent(s.date, () => [])
        .add(s);
  }
  return {
    for (final String currency in byCurrency.keys.toList()..sort())
      currency: _daily(byCurrency[currency]!, typeOf, currency),
  };
}

List<NetWorthPoint> _daily(
  Map<LocalDate, List<BalanceSnapshot>> byDate,
  Map<String, AccountType> typeOf,
  String currency,
) {
  final List<LocalDate> dates = byDate.keys.toList()..sort();
  final List<NetWorthPoint> points = [];
  for (LocalDate d = dates.first; !d.isAfter(dates.last); d = d.addDays(1)) {
    final List<BalanceSnapshot>? rows = byDate[d];
    if (rows == null) {
      final NetWorthPoint previous = points.last;
      points.add(
        NetWorthPoint(
          date: d,
          assets: previous.assets,
          liabilities: previous.liabilities,
          carried: true,
        ),
      );
    } else {
      points.add(
        pointOf(d, [
          for (final BalanceSnapshot s in rows)
            (typeOf[s.accountId], s.current),
        ], currency),
      );
    }
  }
  return points;
}
