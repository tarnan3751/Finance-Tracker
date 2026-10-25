/// The committed goldens, as a function: for each persona at seed 1 and as of 2026-10-24,
/// - `days120/`: every output over 120 days, byte for byte (small enough to diff);
/// - `days730/`: the custom users and their manifest over the full window, byte for byte
///   (the Sandbox fixtures Phase 3 provisions);
/// - `digests.json`: the FNV-1a 64 of every output over the full window.
/// `tool/update_goldens.dart` writes these files; `test/determinism_test.dart` compares.
library;

import 'dart:collection';

import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';

/// The goldens' seed.
const int goldenSeed = 1;

/// The goldens' as-of date.
final LocalDate goldenAsOf = LocalDate(2026, 10, 24);

/// The short window.
const int goldenShortDays = 120;

/// The golden files for [persona], by path under `test/goldens/<slug>/`.
SplayTreeMap<String, String> goldenSet(PersonaId persona) {
  final files = SplayTreeMap<String, String>();
  final short = renderOutputs(
    persona,
    seed: goldenSeed,
    asOf: goldenAsOf,
    days: goldenShortDays,
  );
  for (final e in short.entries) {
    files['days$goldenShortDays/${e.key}'] = e.value;
  }
  final full = renderOutputs(persona, seed: goldenSeed, asOf: goldenAsOf);
  for (final e in full.entries) {
    if (e.key.startsWith('sandbox_user_') || e.key == sandboxManifestFileName) {
      files['days$maxWindowDays/${e.key}'] = e.value;
    }
  }
  files['digests.json'] = writeJson({
    'generator': 'persona_engine',
    'format_version': formatVersion,
    'persona': persona.slug,
    'seed': goldenSeed,
    'as_of': goldenAsOf.toIso(),
    'days': maxWindowDays,
    'fnv1a64': {
      for (final e in full.entries) e.key: fnv1a64Hex(fnv1a64String(e.value)),
    },
  });
  return files;
}
