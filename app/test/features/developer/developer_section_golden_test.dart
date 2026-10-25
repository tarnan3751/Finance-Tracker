// Goldens of the settings screen's Developer section in the dev flavor, light and dark:
// the diagnostics before the first sync and pull, Pull now, Copy diagnostics and the
// Sandbox controls entry. Tagged `golden`; see test/flutter_test_config.dart for where
// the files go and how to update them.
import 'package:alchemist/alchemist.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/features/developer/presentation/developer_section.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/pump_app.dart';

const Size _size = Size(412, 600);

Widget _section(Brightness brightness) => ProviderScope(
  retry: (_, _) => null,
  overrides: testOverrides(
    config: AppConfig.dev(),
    overrides: [
      // The fake server draws device ids at random.
      syncDeviceIdProvider.overrideWithValue('device-0001'),
    ],
  ),
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(
      body: SingleChildScrollView(child: DeveloperSection()),
    ),
  ),
);

void main() {
  for (final Brightness brightness in Brightness.values) {
    goldenTest(
      'the Developer section, ${brightness.name}',
      fileName: 'developer_section_${brightness.name}',
      constraints: BoxConstraints.tight(_size),
      builder: () =>
          SizedBox.fromSize(size: _size, child: _section(brightness)),
    );
  }
}
