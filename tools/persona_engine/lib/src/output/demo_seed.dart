/// The demo seed: what the demo flavor loads (`PLAN.md` §7). The demo plays the
/// institution: accounts belong to demo Items at Plaid's test institutions and report the
/// balance derived from their history, and every transaction is `source: demo`.
library;

import 'package:persona_engine/src/generate/generator.dart';
import 'package:persona_engine/src/model/household.dart';
import 'package:persona_engine/src/model/persona.dart';
import 'package:persona_engine/src/personas/personas.dart';
import 'package:shared_models/shared_models.dart';

/// The version of the output formats; bumped when a format changes shape.
const int formatVersion = 1;

/// The demo flavor's data for one household.
final class DemoSeed {
  /// The seed for [household].
  const DemoSeed(this.household);

  /// The household.
  final GeneratedHousehold household;

  /// The JSON form: the household's entities through `shared_models`' JSON (amounts as
  /// `{minor_units, currency}`), and the package's own records alongside.
  Map<String, Object?> toJson() {
    final h = household;
    return {
      'generator': 'persona_engine',
      'format_version': formatVersion,
      'persona': h.persona.id.slug,
      'seed': h.seed,
      'as_of': h.asOf.toIso(),
      'window_start': h.window.start.toIso(),
      'days': h.window.length,
      'institutions': [for (final i in h.institutions) i.toJson()],
      'items': [for (final i in h.items) i.toJson()],
      'accounts': [for (final a in h.accounts) a.toJson()],
      'opening_balances': [for (final o in h.openingBalances) o.toJson()],
      'transactions': [for (final t in h.transactions) t.toJson()],
      'transfers': [for (final t in h.transfers) t.toJson()],
      'recurring': [for (final r in h.recurring) r.toJson()],
      'holdings': [for (final x in h.holdings) x.toJson()],
      'opening_holdings': [for (final x in h.openingHoldings) x.toJson()],
      'investment_transactions': [
        for (final t in h.investmentTransactions) t.toJson(),
      ],
      'liabilities': [for (final l in h.liabilities) l.toJson()],
      'anomalies': [for (final a in h.anomalies) a.toJson()],
    };
  }
}

/// The demo seed for [persona] with [seed], over the [days] ending on [asOf]. The app's
/// demo flavor calls this directly; the same arguments always give the same seed.
DemoSeed generateDemoSeed(
  PersonaId persona,
  int seed,
  LocalDate asOf, {
  int days = maxWindowDays,
}) => DemoSeed(
  generateHousehold(personaFor(persona), seed: seed, asOf: asOf, days: days),
);
