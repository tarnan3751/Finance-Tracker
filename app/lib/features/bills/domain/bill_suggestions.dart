/// Bills the user may want, from what the app already knows (`docs/reference/bills.md`,
/// **Suggestions**): the active expense streams and the liabilities with a payment due
/// that no bill links yet. Accepting one makes the bill with the link; the stream gives
/// the bill its values only then, after which the bill keeps its own schedule (`PLAN.md`
/// §12). Pure Dart, over [BillSourceData], which the application layer fills from the
/// recurring streams and the liabilities.
library;

import 'package:shared_models/shared_models.dart';

/// A recurring stream as suggestions read it.
final class SourceStream {
  /// The stream; [amount] is in the app's sign (an expense is negative); [minAmount] and
  /// [maxAmount] bound its payments' sizes, when known.
  const SourceStream({
    required this.id,
    required this.name,
    required this.accountId,
    required this.cadence,
    required this.amount,
    required this.nextExpected,
    required this.active,
    this.minAmount,
    this.maxAmount,
  });

  final String id;
  final String name;
  final String accountId;
  final RecurringCadence cadence;
  final Money amount;
  final LocalDate? nextExpected;
  final bool active;
  final Money? minAmount;
  final Money? maxAmount;
}

/// A liability as suggestions read it: the card or loan on account [accountId], named
/// [name], with its next payment due [nextPaymentDueDate] for at least [minimumPayment]
/// (a positive amount, as the institution reports it).
final class SourceLiability {
  const SourceLiability({
    required this.accountId,
    required this.name,
    required this.nextPaymentDueDate,
    this.minimumPayment,
  });

  final String accountId;
  final String name;
  final LocalDate? nextPaymentDueDate;
  final Money? minimumPayment;
}

/// What suggestions are made from.
final class BillSourceData {
  const BillSourceData({this.streams = const [], this.liabilities = const []});

  final List<SourceStream> streams;
  final List<SourceLiability> liabilities;
}

/// A bill the user may accept.
sealed class BillSuggestion {
  const BillSuggestion();

  /// The name the bill would take.
  String get name;

  /// The first due date the bill would take.
  LocalDate get dueDate;

  /// The bill, with id [id].
  BillReminder accept(String id);
}

/// A bill from a recurring expense stream.
final class StreamBillSuggestion extends BillSuggestion {
  const StreamBillSuggestion(this.stream);

  final SourceStream stream;

  @override
  String get name => stream.name;

  @override
  LocalDate get dueDate => stream.nextExpected!;

  @override
  BillReminder accept(String id) => BillReminder(
    id: id,
    name: stream.name,
    amount: stream.amount,
    dueDate: dueDate,
    cadence: stream.cadence,
    accountId: stream.accountId,
    streamId: stream.id,
  );
}

/// A bill from a liability's minimum payment, monthly, following its due date.
final class LiabilityBillSuggestion extends BillSuggestion {
  const LiabilityBillSuggestion(this.liability);

  final SourceLiability liability;

  @override
  String get name => liability.name;

  @override
  LocalDate get dueDate => liability.nextPaymentDueDate!;

  @override
  BillReminder accept(String id) => BillReminder(
    id: id,
    name: liability.name,
    amount: switch (liability.minimumPayment) {
      final Money minimum => Money(
        -minimum.minorUnits.abs(),
        minimum.currencyCode,
      ),
      null => null,
    },
    dueDate: dueDate,
    cadence: RecurringCadence.monthly,
    liabilityAccountId: liability.accountId,
  );
}

/// The suggestions from [data] that none of [bills] (the live ones) links: active
/// expense streams with a known cadence and next date, and liabilities with a next
/// payment due date. By due date, then name, then the stream id or account id.
List<BillSuggestion> billSuggestions(
  BillSourceData data,
  List<BillReminder> bills,
) {
  final Set<String> streams = {
    for (final BillReminder b in bills)
      if (b.streamId case final String id) id,
  };
  final Set<String> liabilities = {
    for (final BillReminder b in bills)
      if (b.liabilityAccountId case final String id) id,
  };
  final List<(BillSuggestion, String)> found = [
    for (final SourceStream s in data.streams)
      if (s.active &&
          s.amount.minorUnits < 0 &&
          s.nextExpected != null &&
          s.cadence != RecurringCadence.unknown &&
          !streams.contains(s.id))
        (StreamBillSuggestion(s), s.id),
    for (final SourceLiability l in data.liabilities)
      if (l.nextPaymentDueDate != null && !liabilities.contains(l.accountId))
        (LiabilityBillSuggestion(l), l.accountId),
  ];
  found.sort((a, b) {
    final int byDate = a.$1.dueDate.compareTo(b.$1.dueDate);
    if (byDate != 0) return byDate;
    final int byName = a.$1.name.compareTo(b.$1.name);
    return byName != 0 ? byName : a.$2.compareTo(b.$2);
  });
  return [for (final (BillSuggestion s, _) in found) s];
}
