/// Renders a household's outputs as files: the CLI, the golden updater and the tests all
/// go through here, so they write the same bytes.
library;

import 'dart:collection';

import 'package:persona_engine/src/generate/generator.dart';
import 'package:persona_engine/src/model/persona.dart';
import 'package:persona_engine/src/output/demo_seed.dart';
import 'package:persona_engine/src/output/json_writer.dart';
import 'package:persona_engine/src/output/sandbox_manifest.dart';
import 'package:persona_engine/src/output/sandbox_user.dart';
import 'package:persona_engine/src/personas/personas.dart';
import 'package:shared_models/shared_models.dart';

/// Which outputs to render.
enum OutputFormat {
  /// `demo_seed.json`.
  demo('demo'),

  /// `sandbox_user_<institution>.json`, one per institution, and
  /// `sandbox_manifest.json`.
  sandboxUser('sandbox-user');

  const OutputFormat(this.flag);

  /// The CLI name.
  final String flag;
}

/// The files for [persona] at [seed] over the [days] ending on [asOf], by file name in
/// sorted order. With [includeInterestLegs] false the Sandbox outputs leave out card and
/// loan interest charges; the demo seed always has them.
SplayTreeMap<String, String> renderOutputs(
  PersonaId persona, {
  required int seed,
  required LocalDate asOf,
  int days = maxWindowDays,
  Set<OutputFormat> formats = const {...OutputFormat.values},
  bool includeInterestLegs = true,
}) {
  final household = generateHousehold(
    personaFor(persona),
    seed: seed,
    asOf: asOf,
    days: days,
  );
  final files = SplayTreeMap<String, String>();
  if (formats.contains(OutputFormat.demo)) {
    files['demo_seed.json'] = writeJson(DemoSeed(household).toJson());
  }
  if (formats.contains(OutputFormat.sandboxUser)) {
    final users = sandboxUsers(
      household,
      includeInterestLegs: includeInterestLegs,
    );
    for (final u in users) {
      files[sandboxUserFileName(u)] = writeJson(u.config);
    }
    files[sandboxManifestFileName] = writeJson(
      sandboxManifest(
        household,
        users,
        includeInterestLegs: includeInterestLegs,
      ),
    );
  }
  return files;
}
