/// Rewrites `test/goldens/` from the current engine. Run it from the package directory
/// (`dart run tool/update_goldens.dart`) after a deliberate change to a persona, the
/// generator or an output, and commit the result with that change: golden expectations
/// change only under a tier A brief (`CLAUDE.md`).
library;

import 'dart:io';

import 'package:persona_engine/persona_engine.dart';

import 'golden_set.dart';

Future<void> main() async {
  final root = Directory('test/goldens');
  if (root.existsSync()) await root.delete(recursive: true);
  for (final persona in PersonaId.values) {
    for (final e in goldenSet(persona).entries) {
      final file = File('${root.path}/${persona.slug}/${e.key}');
      await file.parent.create(recursive: true);
      await file.writeAsString(e.value);
      stdout.writeln('${file.path} (${e.value.length} bytes)');
    }
  }
}
