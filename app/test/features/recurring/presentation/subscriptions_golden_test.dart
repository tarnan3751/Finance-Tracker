// Goldens of the subscriptions screen, light and dark at phone size, on the stream seed
// (stream_seed.dart): the yearly total, the subscriptions by yearly cost with the
// irregular one last and the detected caption, and the folded Muted and Other recurring
// sections. Tagged `golden`; see test/flutter_test_config.dart for where the files go
// and how to update them.
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';
import '../../../helpers/stream_seed.dart';

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final Brightness brightness in Brightness.values) {
    goldenTest(
      'the subscriptions screen, ${brightness.name}',
      fileName: 'subscriptions_${brightness.name}',
      constraints: BoxConstraints.tight(phoneSize),
      builder: () => SizedBox.fromSize(
        size: phoneSize,
        child: buildTestApp(
          initialLocation: '/bills/subscriptions',
          brightness: brightness,
          overrides: [
            storeOverride(seededStore()),
            streamsOverride(seededStreams()),
          ],
        ),
      ),
    );
  }
}
