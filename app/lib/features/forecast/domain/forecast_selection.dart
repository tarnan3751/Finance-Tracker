/// Which accounts the forecast covers and in which currency (`docs/reference/forecast.md`,
/// **The selection**; `PLAN.md` §12 "5d plan rulings", D1 and D7). Pure Dart.
///
/// The default covers every depository account that is not hidden. The selection is kept
/// as the user's changes from that default (the accounts turned on and off, the currency
/// picked), so an account linked later joins by default. One series is shown per
/// currency: the one picked when a selected account holds it, else the device's default
/// currency when one does, else the first selected account's in display order.
library;

import 'package:shared_models/shared_models.dart';

/// The user's changes from the default selection.
final class ForecastSelection {
  /// The selection turning [include] on and [exclude] off, showing [currency].
  const ForecastSelection({
    this.include = const {},
    this.exclude = const {},
    this.currency,
  });

  /// Reads the form [toJson] writes; anything else is the default.
  factory ForecastSelection.fromJson(Object? json) {
    if (json is! Map<String, Object?>) return const ForecastSelection();
    Set<String> ids(Object? list) => {
      if (list is List<Object?>)
        for (final Object? id in list)
          if (id is String) id,
    };
    final Object? currency = json['currency'];
    return ForecastSelection(
      include: ids(json['include']),
      exclude: ids(json['exclude']),
      currency: currency is String && Money.isValidCurrencyCode(currency)
          ? currency
          : null,
    );
  }

  /// The accounts turned on that the default leaves off.
  final Set<String> include;

  /// The accounts turned off that the default covers.
  final Set<String> exclude;

  /// The currency picked, or null for the default rule.
  final String? currency;

  /// Whether [account] is covered by default: a depository account that is not hidden.
  static bool coversByDefault(Account account) =>
      account.type == AccountType.depository && !account.isHidden;

  /// Whether [account] is covered: only a depository account can be.
  bool covers(Account account) =>
      account.type == AccountType.depository &&
      (include.contains(account.id) ||
          (coversByDefault(account) && !exclude.contains(account.id)));

  /// This selection with [account] switched: on when it is off, off when it is on, kept
  /// as a change only where it differs from the default.
  ForecastSelection toggled(Account account) {
    final bool on = !covers(account);
    final bool byDefault = coversByDefault(account);
    return ForecastSelection(
      include: {...include}
        ..remove(account.id)
        ..addAll([if (on && !byDefault) account.id]),
      exclude: {...exclude}
        ..remove(account.id)
        ..addAll([if (!on && byDefault) account.id]),
      currency: currency,
    );
  }

  /// This selection showing [code].
  ForecastSelection showing(String code) =>
      ForecastSelection(include: include, exclude: exclude, currency: code);

  /// The covered accounts among [accounts], in their order.
  List<Account> coveredAmong(List<Account> accounts) => [
    for (final Account a in accounts)
      if (covers(a)) a,
  ];

  /// The currency shown for [accounts] (in display order) by the rule above, with
  /// [defaultCurrency] the device's; null when none is covered.
  String? currencyFor(List<Account> accounts, String defaultCurrency) {
    final List<Account> covered = coveredAmong(accounts);
    if (covered.isEmpty) return null;
    bool held(String? code) => covered.any((a) => a.currencyCode == code);
    if (held(currency)) return currency;
    if (held(defaultCurrency)) return defaultCurrency;
    return covered.first.currencyCode;
  }

  /// The JSON form, ids sorted, so equal selections write equal text.
  Map<String, Object?> toJson() => {
    'include': [...include]..sort(),
    'exclude': [...exclude]..sort(),
    if (currency != null) 'currency': currency,
  };

  @override
  bool operator ==(Object other) =>
      other is ForecastSelection &&
      other.currency == currency &&
      other.include.length == include.length &&
      other.include.containsAll(include) &&
      other.exclude.length == exclude.length &&
      other.exclude.containsAll(exclude);

  @override
  int get hashCode => Object.hash(
    currency,
    Object.hashAllUnordered(include),
    Object.hashAllUnordered(exclude),
  );
}
