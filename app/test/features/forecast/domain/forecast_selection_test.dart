// The forecast's account selection (forecast_selection.dart): the default, toggles kept
// as changes from it, an account linked later joining by default, the JSON round trip,
// and the currency rule.
import 'package:finance_tracker/features/forecast/domain/forecast_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

Account account(
  String id, {
  AccountType type = AccountType.depository,
  String currency = 'USD',
  bool hidden = false,
}) => Account(
  id: id,
  type: type,
  name: id,
  currencyCode: currency,
  isHidden: hidden,
  displayOrder: 0,
);

void main() {
  final Account checking = account('checking');
  final Account savings = account('savings');
  final Account stash = account('stash', hidden: true);
  final Account card = account('card', type: AccountType.credit);
  final Account euro = account('euro', currency: 'EUR');

  test('the default covers the depository accounts that are not hidden', () {
    const ForecastSelection s = ForecastSelection();
    expect(s.coveredAmong([checking, savings, stash, card, euro]), [
      checking,
      savings,
      euro,
    ]);
  });

  test('a toggle is kept only as a change from the default', () {
    final ForecastSelection off = const ForecastSelection().toggled(savings);
    expect(off.exclude, {'savings'});
    expect(off.covers(savings), isFalse);
    expect(off.toggled(savings), const ForecastSelection());

    final ForecastSelection on = const ForecastSelection().toggled(stash);
    expect(on.include, {'stash'});
    expect(on.covers(stash), isTrue);
    expect(on.toggled(stash), const ForecastSelection());
  });

  test('only a depository account can be covered', () {
    expect(const ForecastSelection(include: {'card'}).covers(card), isFalse);
  });

  test('an account linked later joins by default', () {
    final ForecastSelection s = const ForecastSelection().toggled(savings);
    final Account linked = account('linked');
    expect(s.coveredAmong([checking, savings, linked]), [checking, linked]);
  });

  test('the JSON form round-trips, and anything else reads as the default', () {
    final ForecastSelection s = const ForecastSelection()
        .toggled(savings)
        .toggled(stash)
        .showing('EUR');
    expect(s.toJson(), {
      'include': ['stash'],
      'exclude': ['savings'],
      'currency': 'EUR',
    });
    expect(ForecastSelection.fromJson(s.toJson()), s);
    expect(ForecastSelection.fromJson(null), const ForecastSelection());
    expect(ForecastSelection.fromJson('x'), const ForecastSelection());
    expect(
      ForecastSelection.fromJson({
        'include': [1, 'a'],
        'currency': 'euro',
      }),
      const ForecastSelection(include: {'a'}),
    );
    expect(const ForecastSelection().toJson(), {
      'include': <String>[],
      'exclude': <String>[],
    });
  });

  group('the currency shown', () {
    final List<Account> accounts = [euro, checking];

    test('is the one picked when a covered account holds it', () {
      expect(
        const ForecastSelection(currency: 'EUR').currencyFor(accounts, 'USD'),
        'EUR',
      );
      expect(
        const ForecastSelection(currency: 'JPY').currencyFor(accounts, 'USD'),
        'USD',
      );
    });

    test('else the default currency when a covered account holds it', () {
      expect(const ForecastSelection().currencyFor(accounts, 'USD'), 'USD');
    });

    test('else the first covered account\'s', () {
      expect(const ForecastSelection().currencyFor(accounts, 'GBP'), 'EUR');
      expect(
        const ForecastSelection(exclude: {'euro'}).currencyFor(accounts, 'GBP'),
        'USD',
      );
    });

    test('is null when nothing is covered', () {
      expect(
        const ForecastSelection().currencyFor([card, stash], 'USD'),
        isNull,
      );
    });
  });
}
