/// Planted anomalies: two or three a year, half of them a usual merchant at several times
/// its usual amount and half a merchant the household has never used. A new merchant is
/// drawn without replacement from a pool that shares no name or description with the
/// household's regular merchants and payees, so it appears exactly once.
library;

import 'package:persona_engine/src/model/anomaly.dart';
import 'package:persona_engine/src/model/persona.dart';
import 'package:persona_engine/src/random/pcg32.dart';
import 'package:shared_models/shared_models.dart';

/// One planned anomaly.
final class PlannedAnomaly {
  /// A plan.
  const PlannedAnomaly({
    required this.kind,
    required this.account,
    required this.merchant,
    required this.raw,
    required this.amountMinor,
  });

  /// The kind.
  final AnomalyKind kind;

  /// The account charged.
  final String account;

  /// The merchant.
  final Merchant merchant;

  /// The description.
  final String raw;

  /// The amount, positive, in minor units.
  final int amountMinor;
}

/// Throws an [ArgumentError] when [persona]'s anomaly pool repeats a merchant or shares a
/// merchant name or raw description with a regular pool, payee or subscription.
void checkAnomalyPool(Persona persona) {
  final regular = <String>{};
  void add(String? merchant, Iterable<String> raw) {
    if (merchant != null) regular.add(merchant);
    regular.addAll(raw);
  }

  for (final p in [
    for (final s in persona.incomes) s.payer,
    for (final s in persona.bills) s.payee,
    for (final s in persona.subscriptions) s.payee,
    for (final s in persona.loans) ?s.paymentPayee,
    for (final s in persona.disbursements) ...[s.payee, ?s.paysOut],
    for (final s in persona.cards) s.paymentPayee,
    for (final s in persona.transfers) ...[s.outPayee, s.inPayee],
  ]) {
    add(p.merchant, [p.raw]);
  }
  for (final s in persona.spending) {
    for (final m in s.merchants) {
      add(m.name, m.raw);
    }
  }
  final seen = <String>{};
  for (final m in persona.anomalyMerchants) {
    final name = m.name;
    if (name == null || !seen.add(name)) {
      throw ArgumentError('anomaly merchant $name is unnamed or repeated');
    }
    if (regular.contains(name) || m.raw.any(regular.contains)) {
      throw ArgumentError('anomaly merchant $name is one the household uses');
    }
  }
}

/// The anomalies for the window `[first, last]`, by day. Each 365-day block from [first]
/// gets two or three; a shorter final block gets its share, rounded down. New merchants
/// are drawn without replacement; once the pool is used up, the rest are unusual amounts.
Map<LocalDate, List<PlannedAnomaly>> planAnomalies(
  Persona persona,
  Pcg32 rng,
  LocalDate first,
  LocalDate last,
) {
  final plan = <LocalDate, List<PlannedAnomaly>>{};
  final unused = [...persona.anomalyMerchants];
  final days = first.daysUntil(last) + 1;
  for (var start = 0; start < days; start += 365) {
    final length = days - start < 365 ? days - start : 365;
    var count = 2 + rng.nextInt(2);
    if (length < 365) count = count * length ~/ 365;
    for (var i = 0; i < count; i++) {
      final day = first.addDays(start + rng.nextInt(length));
      final PlannedAnomaly anomaly;
      if (rng.chance(500) || unused.isEmpty) {
        final spec = rng.pick(persona.spending);
        final m =
            spec.merchants[rng.pickWeighted([
              for (final m in spec.merchants) m.weight,
            ])];
        anomaly = PlannedAnomaly(
          kind: AnomalyKind.unusualAmount,
          account: spec.account,
          merchant: m,
          raw: rng.pick(m.raw),
          amountMinor: m.maxMinor * rng.nextIntInRange(4, 8) + rng.nextInt(100),
        );
      } else {
        final m = unused.removeAt(rng.nextInt(unused.length));
        anomaly = PlannedAnomaly(
          kind: AnomalyKind.newMerchant,
          account: persona.anomalyAccount,
          merchant: m,
          raw: rng.pick(m.raw),
          amountMinor: rng.nextIntInRange(m.minMinor, m.maxMinor),
        );
      }
      (plan[day] ??= []).add(anomaly);
    }
  }
  return plan;
}
