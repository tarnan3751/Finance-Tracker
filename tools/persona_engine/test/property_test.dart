// Every invariant over many seeds, as-of dates and window lengths. Deterministic by
// default: seeds start at 1000; set PERSONA_ENGINE_SEED to start elsewhere
// (`PERSONA_ENGINE_SEED=5000 dart test test/property_test.dart`). A failure names the
// persona, the seed, the as-of date and the window, so it reproduces exactly.
import 'dart:io';

import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import 'support/invariants.dart';

const int defaultSeed = 1000;
const int seedsPerPersona = 100;
const int seedsPerSweepPoint = 2;

final int base =
    int.tryParse(Platform.environment['PERSONA_ENGINE_SEED'] ?? '') ??
    defaultSeed;

/// As-of dates across several years: month ends, leap days, the days either side of a
/// semester's disbursement, a year end and a year start.
final List<LocalDate> asOfDates = [
  LocalDate(2024, 2, 29),
  LocalDate(2024, 3, 1),
  LocalDate(2024, 12, 31),
  LocalDate(2025, 1, 31),
  LocalDate(2025, 6, 30),
  LocalDate(2025, 8, 21),
  LocalDate(2026, 2, 28),
  LocalDate(2026, 8, 23),
  LocalDate(2026, 10, 24),
  LocalDate(2027, 4, 30),
  LocalDate(2027, 12, 31),
  LocalDate(2028, 2, 29),
  LocalDate(2028, 8, 22),
  LocalDate(2029, 11, 30),
  LocalDate(2030, 1, 1),
];

const List<int> windows = [1, 2, 7, 31, 120, 365, 730];

void main() {
  final asOf = LocalDate(2026, 10, 24);

  for (final id in PersonaId.values) {
    final persona = personaFor(id);

    test('${id.slug} holds every invariant for seeds $base to '
        '${base + seedsPerPersona - 1}', () {
      for (var seed = base; seed < base + seedsPerPersona; seed++) {
        final h = generateHousehold(persona, seed: seed, asOf: asOf);
        expect(allViolations(h), isEmpty, reason: '${id.slug} seed $seed');
      }
    }, timeout: const Timeout(Duration(minutes: 5)));

    test(
      '${id.slug} holds every invariant on every as-of date and window, and its '
      'state on the as-of date does not depend on the window',
      () {
        for (final date in asOfDates) {
          for (var seed = base; seed < base + seedsPerSweepPoint; seed++) {
            GeneratedHousehold? longest;
            for (final days in windows.reversed) {
              final where = '${id.slug} seed $seed as of $date, $days days';
              final h = generateHousehold(
                persona,
                seed: seed,
                asOf: date,
                days: days,
              );
              expect(allViolations(h), isEmpty, reason: where);
              final full = longest ??= h;
              expect(_state(h), _state(full), reason: where);
            }
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}

/// What a household owes and holds on its as-of date apart from its cash flows: loan
/// principals, interest paid this year, and positions.
List<Object> _state(GeneratedHousehold h) => [
  for (final l in h.liabilities.whereType<LoanLiability>())
    '${l.accountId} ${l.principalBalance} ${l.ytdInterestPaid} ${l.monthlyPayment}',
  for (final x in h.holdings)
    '${x.security.ticker} ${x.quantityMilli} ${x.costBasis} ${x.price}',
];
