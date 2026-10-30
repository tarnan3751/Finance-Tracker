// Goldens of the shell: each tab, and each segment of the Plan and Insights tabs, in light and dark at
// phone size, the demo shell with its flavor strip below a status bar, the settings
// screen at tablet size (1024 × 768, expanded), and the Accounts tab in each window size
// class: compact at phone size (412 × 915, a Pixel 6), medium at 701 × 841 (a Pixel
// Fold's inner display upright) and expanded at 1280 × 800 (a Pixel Tablet on its
// side), on the seed, and a transaction beside the transactions on an expanded
// window. Tagged
// `golden`; see test/flutter_test_config.dart for where the files go and how to update
// them.
import 'package:alchemist/alchemist.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

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
  'plan': '/plan',
  'plan_bills': '/bills',
  'plan_forecast': '/forecast',
  'insights': '/insights',
  'insights_net_worth': '/net-worth',
  'insights_investments': '/investments',
  'insights_goals': '/goals',
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

  for (final (String sizeClass, Size size) in [
    ('compact', phoneSize),
    ('medium', mediumSize),
    ('expanded', expandedSize),
  ]) {
    goldenTest(
      'the accounts tab, light, $sizeClass',
      fileName: 'shell_accounts_${sizeClass}_light',
      constraints: BoxConstraints.tight(size),
      builder: () => _device(
        size,
        buildTestApp(overrides: [storeOverride(seededStore())]),
      ),
    );
  }

  goldenTest(
    'a transaction beside the transactions, light, expanded',
    fileName: 'shell_transactions_two_pane_expanded_light',
    constraints: BoxConstraints.tight(expandedSize),
    builder: () => _device(
      expandedSize,
      buildTestApp(
        initialLocation: '/transactions/demo-txn-04',
        overrides: [storeOverride(seededStore())],
      ),
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
