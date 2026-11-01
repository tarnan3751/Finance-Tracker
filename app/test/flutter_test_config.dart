// Runs before every test file in test/: wraps each test in the alchemist golden
// configuration.
//
// CI goldens (text drawn as blocks, no shadows) are always on; they are written to
// goldens/ci/ next to the test, committed, and compared by the gate and by CI, with a
// tolerance for the anti-aliasing noise between the macOS that generates them and the
// Linux that checks them in CI (helpers/golden_comparator.dart). Platform goldens (real
// fonts, for a human to look at) are a local aid: they are written to goldens/<os>/
// (gitignored) by `flutter test --update-goldens --tags golden` when the CI environment
// variable is not set, and never compared, because a fresh clone has none to compare
// against.
import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/golden_comparator.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) {
  final bool onCi = Platform.environment.containsKey('CI');
  // Flutter sets a LocalFileComparator for the test file before this runs.
  final GoldenFileComparator comparator = goldenFileComparator;
  if (comparator is LocalFileComparator) {
    goldenFileComparator = TolerantGoldenComparator.from(comparator);
  }
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
