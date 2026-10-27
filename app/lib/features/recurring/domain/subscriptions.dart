/// The subscriptions: the active, unmuted streams the user or the app counts as one,
/// with what each costs a year (`docs/reference/recurring.md`). Pure Dart, no Flutter
/// import.
library;

import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:shared_models/shared_models.dart';

/// A subscription and its [annualCost]: the stream's average magnitude times its
/// occurrences a year, positive, or null when its cadence is unknown.
typedef Subscription = ({StreamView view, Money? annualCost});

/// How many times a year [cadence] recurs, or null for [RecurringCadence.unknown].
int? occurrencesPerYear(RecurringCadence cadence) => switch (cadence) {
  RecurringCadence.weekly => 52,
  RecurringCadence.biweekly => 26,
  RecurringCadence.semiMonthly => 24,
  RecurringCadence.monthly => 12,
  RecurringCadence.quarterly => 4,
  RecurringCadence.annually => 1,
  RecurringCadence.unknown => null,
};

/// The subscriptions among [streams], in their order: those whose resolved
/// `isSubscription` is true, not muted, and still active.
List<Subscription> subscriptionsOf(List<StreamView> streams) => [
  for (final StreamView view in streams)
    if (view.isSubscription &&
        !view.muted &&
        view.stream.status == RecurringStatus.active)
      (
        view: view,
        annualCost: switch (occurrencesPerYear(view.stream.cadence)) {
          null => null,
          final int times => view.stream.averageAmount.abs() * times,
        },
      ),
];
