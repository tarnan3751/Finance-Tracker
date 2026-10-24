// Goldens of the shell: each tab in light and dark at phone size, the demo shell with its
// flavor strip below a status bar, and the settings screen at tablet size. Tagged
// `golden`; see test/flutter_test_config.dart for where the files go and how to update
// them.
import 'package:alchemist/alchemist.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

/// [child] laid out at [size] with [padding] as the system insets (a status bar).
Widget _device(
  Size size,
  Widget child, {
  EdgeInsets padding = EdgeInsets.zero,
}) {
  return Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(size: size, padding: padding, viewPadding: padding),
      child: SizedBox.fromSize(size: size, child: child),
    ),
  );
}

const Map<String, String> _tabs = {
  'accounts': '/accounts',
  'transactions': '/transactions',
  'settings': '/settings',
};

void main() {
  // Flutter's own DEBUG banner is not part of the app; the flavor banner is.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final MapEntry(key: String tab, value: String location)
      in _tabs.entries) {
    for (final Brightness brightness in Brightness.values) {
      goldenTest(
        'the $tab tab, ${brightness.name}, phone',
        fileName: 'shell_${tab}_${brightness.name}_phone',
        constraints: BoxConstraints.tight(phoneSize),
        builder: () => _device(
          phoneSize,
          buildTestApp(initialLocation: location, brightness: brightness),
        ),
      );
    }
  }

  goldenTest(
    'the demo shell draws its strip below the status bar',
    fileName: 'shell_demo_banner_phone',
    constraints: BoxConstraints.tight(phoneSize),
    builder: () => _device(
      phoneSize,
      buildTestApp(config: AppConfig.demo()),
      padding: const EdgeInsets.only(top: 24),
    ),
  );

  goldenTest(
    'the settings screen, light, tablet',
    fileName: 'settings_light_tablet',
    constraints: BoxConstraints.tight(tabletSize),
    builder: () =>
        _device(tabletSize, buildTestApp(initialLocation: '/settings')),
  );
}
