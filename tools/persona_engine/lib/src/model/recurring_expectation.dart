/// What the generator promises recurs: the ground truth for the engine's recurrence tests
/// and, later, for the app's own recurring detector.
///
/// Deliberately not `shared_models`' `RecurringStream`: that entity's `source` is `plaid`,
/// `detected` or `user`, and none of those is true of a generated stream.
library;

import 'package:meta/meta.dart';
import 'package:persona_engine/src/model/schedule.dart';
import 'package:shared_models/shared_models.dart';

/// A stream the generator emits on a schedule: one transaction named [name] on
/// [accountId] per occurrence of [schedule], within [Schedule.toleranceDays] of the nominal
/// date, with a magnitude in `[minAmount, maxAmount]`.
@immutable
final class RecurringExpectation {
  /// An expectation.
  const RecurringExpectation({
    required this.key,
    required this.accountId,
    required this.name,
    required this.merchantName,
    required this.schedule,
    required this.minAmount,
    required this.maxAmount,
    required this.isSubscription,
    required this.isInflow,
  });

  /// The persona-local key of the spec it comes from.
  final String key;

  /// The account.
  final String accountId;

  /// The transactions' raw name.
  final String name;

  /// Their normalized merchant.
  final String? merchantName;

  /// When.
  final Schedule schedule;

  /// The smallest magnitude, positive.
  final Money minAmount;

  /// The largest magnitude, positive.
  final Money maxAmount;

  /// Whether it is a subscription.
  final bool isSubscription;

  /// Whether money comes in (income) rather than goes out.
  final bool isInflow;

  /// The domain's name for the cadence.
  RecurringCadence get cadence => schedule.cadence;

  /// The JSON form.
  Map<String, Object?> toJson() => {
    'key': key,
    'account_id': accountId,
    'name': name,
    'merchant_name': merchantName,
    'cadence': switch (cadence) {
      RecurringCadence.semiMonthly => 'semi_monthly',
      final c => c.name,
    },
    'schedule': schedule.toJson(),
    'tolerance_days': schedule.toleranceDays,
    'min_amount': minAmount.toJson(),
    'max_amount': maxAmount.toJson(),
    'is_subscription': isSubscription,
    'is_inflow': isInflow,
  };
}
