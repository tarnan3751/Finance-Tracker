/// Whether this build carries the developer tools: the Developer section of Settings and
/// the Sandbox controls (`docs/reference/developer.md`, `docs/reference/build.md`).
///
/// A compile-time constant, so that `if (kDevTools && …)` lets the AOT compiler drop the
/// tools from a build where it is false: a demo or prod APK (`--flavor demo`, `--flavor
/// prod`). It is true in a dev build; in a build with no flavor, which only the host
/// tests are (`flutter test`); and under `FT_FAKE_SERVER`, the test-only define with
/// which the emulator harness runs the dev configuration inside its demo-flavor test app
/// (`tools/emulator_tests.sh`). No release build passes that define. Where it is true,
/// `AppConfig.flavor` still decides at run time: the tools show in the dev flavor only.
library;

import 'package:flutter/services.dart' show appFlavor;

/// The `FT_FAKE_SERVER` define, read as `fakeServerInDev` reads it
/// (`core/api/api_providers.dart`).
const bool _fakeServer = bool.fromEnvironment('FT_FAKE_SERVER');

/// Whether the developer tools are compiled in.
const bool kDevTools = appFlavor == 'dev' || appFlavor == null || _fakeServer;
