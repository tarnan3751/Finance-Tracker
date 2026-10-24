// Runs before every test file in test/: wraps each test in the alchemist golden
// configuration.
//
// CI goldens (Ahem font, text drawn as blocks, no shadows: identical on every OS) are
// always on; they are written to goldens/ci/ next to the test, committed, and compared by
// the gate and by CI. Platform goldens (real fonts, for a human to look at) are a local
// aid: they are written to goldens/<os>/ (gitignored) by
// `flutter test --update-goldens --tags golden` when the CI environment variable is not
// set, and never compared, because a fresh clone has none to compare against.
import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) {
  final bool onCi = Platform.environment.containsKey('CI');
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      ciGoldensConfig: const CiGoldensConfig(),
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: !onCi && autoUpdateGoldenFiles,
      ),
    ),
    run: () async => testMain(),
  );
}
