/// The [LiabilityRepository] of the dev and prod flavors, over the `liabilities` table
/// (`docs/reference/data.md`).
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/liabilities/data/in_memory_liability_repository.dart'
    show checkLiabilityBatch, liabilityCurrency;
import 'package:finance_tracker/features/liabilities/domain/liability_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Liabilities in [AppDatabase], stamped `pulled_at` from the clock; nothing recorded.
final class DriftLiabilityRepository implements LiabilityRepository {
  /// The repository over [_database], stamping writes from [_clock].
  DriftLiabilityRepository(this._database, this._clock);

  final AppDatabase _database;
  final Clock _clock;

  $LiabilitiesTable get _liabilities => _database.liabilities;

  Stream<List<Liability>> _watch(
    Expression<bool> Function($LiabilitiesTable) w,
  ) =>
      (_database.select(_liabilities)
            ..where(w)
            ..orderBy([
              (l) => OrderingTerm.asc(l.accountId),
              (l) => OrderingTerm.asc(l.kind),
            ]))
          .watch()
          .map((rows) => rows.map(liabilityFromRow).toList())
          .distinct(sameList);

  @override
  Stream<List<Liability>> watchAll() => _watch((_) => const Constant(true));

  @override
  Stream<List<Liability>> watchByAccount(String accountId) =>
      _watch((l) => l.accountId.equals(accountId));

  @override
  Future<void> applyPlaid(List<Liability> liabilities) async {
    checkLiabilityBatch(liabilities);
    final DateTime now = _clock.nowUtc();
    await _database.transaction(() async {
      await _database.delete(_liabilities).go();
      await _database.batch(
        (batch) => batch.insertAll(_liabilities, [
          for (final Liability l in liabilities)
            liabilityCompanion(l, pulledAt: now),
        ]),
      );
    });
  }
}

/// The row of [liability], written at [pulledAt]: every amount a `*_minor` in the row's
/// `currency`, the APRs and the payload JSON.
LiabilitiesCompanion liabilityCompanion(
  Liability liability, {
  required DateTime pulledAt,
}) {
  final String? currency = liabilityCurrency(liability);
  int? minor(Money? m) => m?.minorUnits;
  return LiabilitiesCompanion(
    accountId: Value(liability.accountId),
    kind: Value(liability.kind),
    currency: Value(currency),
    nextPaymentDueDate: Value(liability.nextPaymentDueDate),
    minimumPaymentMinor: Value(minor(liability.minimumPaymentAmount)),
    lastStatementBalanceMinor: Value(minor(liability.lastStatementBalance)),
    lastStatementIssueDate: Value(liability.lastStatementIssueDate),
    lastPaymentMinor: Value(minor(liability.lastPaymentAmount)),
    lastPaymentDate: Value(liability.lastPaymentDate),
    isOverdue: Value(liability.isOverdue),
    aprs: Value(
      jsonEncode([
        for (final LiabilityApr a in liability.aprs)
          {
            'apr_type': a.type,
            'percentage_basis_points': a.percentageBasisPoints,
            'balance_subject_to_apr': a.balanceSubjectToApr?.toJson(),
          },
      ]),
    ),
    interestRateBp: Value(liability.interestRateBasisPoints),
    originationDate: Value(liability.originationDate),
    originationPrincipalMinor: Value(minor(liability.originationPrincipal)),
    loanTerm: Value(liability.loanTerm),
    nextMonthlyPaymentMinor: Value(minor(liability.nextMonthlyPayment)),
    ytdInterestPaidMinor: Value(minor(liability.ytdInterestPaid)),
    ytdPrincipalPaidMinor: Value(minor(liability.ytdPrincipalPaid)),
    payload: Value(jsonEncode(liability.payload)),
    source: Value(liability.source),
    pulledAt: Value(pulledAt),
  );
}

/// The [Liability] a row holds.
Liability liabilityFromRow(LiabilityRow row) {
  Money? money(int? minor) =>
      minor == null ? null : moneyOrNull(minor, row.currency!);
  return Liability(
    accountId: row.accountId,
    kind: row.kind,
    source: row.source,
    nextPaymentDueDate: row.nextPaymentDueDate,
    minimumPaymentAmount: money(row.minimumPaymentMinor),
    lastStatementBalance: money(row.lastStatementBalanceMinor),
    lastStatementIssueDate: row.lastStatementIssueDate,
    lastPaymentAmount: money(row.lastPaymentMinor),
    lastPaymentDate: row.lastPaymentDate,
    isOverdue: row.isOverdue,
    aprs: [
      for (final Object? a in jsonDecode(row.aprs) as List<Object?>)
        if (a case final Map<String, Object?> apr)
          LiabilityApr(
            type: apr['apr_type']! as String,
            percentageBasisPoints: apr['percentage_basis_points']! as int,
            balanceSubjectToApr: switch (apr['balance_subject_to_apr']) {
              null => null,
              final Object json => Money.fromJson(json as Map<String, dynamic>),
            },
          ),
    ],
    interestRateBasisPoints: row.interestRateBp,
    originationDate: row.originationDate,
    originationPrincipal: money(row.originationPrincipalMinor),
    loanTerm: row.loanTerm,
    nextMonthlyPayment: money(row.nextMonthlyPaymentMinor),
    ytdInterestPaid: money(row.ytdInterestPaidMinor),
    ytdPrincipalPaid: money(row.ytdPrincipalPaidMinor),
    payload: jsonDecode(row.payload) as Map<String, Object?>,
  );
}
