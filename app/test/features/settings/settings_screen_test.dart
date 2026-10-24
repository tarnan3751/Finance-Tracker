// The settings screen: the theme mode control changes the app's theme, the dynamic color
// switch moves between the device's colors and the seed colors, and About shows the
// name, version, flavor and time zone.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

const MethodChannel _dynamicColorChannel = MethodChannel(
  'io.material.plugins/dynamic_color',
);

/// The device accent color the dynamic color tests report.
const Color _deviceAccent = Color(0xFF00897B);

ThemeData _currentTheme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).last));

void main() {
  testWidgets('the theme mode control switches the app to dark and back', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/settings');
    expect(_currentTheme(tester).brightness, Brightness.light);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(_currentTheme(tester).brightness, Brightness.dark);
    final SegmentedButton<AppThemeMode> control = tester.widget(
      find.byType(SegmentedButton<AppThemeMode>),
    );
    expect(control.selected, {AppThemeMode.dark});

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
    expect(_currentTheme(tester).brightness, Brightness.light);
  });

  testWidgets('dynamic color uses the device colors until switched off', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _dynamicColorChannel,
      (call) async => switch (call.method) {
        'getAccentColor' => _deviceAccent.toARGB32(),
        _ => null,
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _dynamicColorChannel,
        null,
      ),
    );
    final Color devicePrimary = ColorScheme.fromSeed(seedColor: _deviceAccent)
        .primary;
    final Color seedPrimary = AppTheme.light().colorScheme.primary;
    expect(devicePrimary, isNot(seedPrimary));

    await pumpApp(tester, initialLocation: '/settings');
    expect(_currentTheme(tester).colorScheme.primary, devicePrimary);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(_currentTheme(tester).colorScheme.primary, seedPrimary);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(_currentTheme(tester).colorScheme.primary, devicePrimary);
  });

  testWidgets('without device colors the seed colors are used', (tester) async {
    await pumpApp(tester, initialLocation: '/settings');

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    expect(
      _currentTheme(tester).colorScheme.primary,
      AppTheme.light().colorScheme.primary,
    );
  });

  testWidgets('About shows the app name, version, flavor and time zone', (
    tester,
  ) async {
    await pumpApp(
      tester,
      config: AppConfig.demo(),
      initialLocation: '/settings',
    );
    await tester.scrollUntilVisible(find.text('Time zone'), 100);

    expect(find.text('Finance Tracker Demo'), findsOneWidget);
    expect(find.text('1.0.0 (build 1)'), findsOneWidget);
    expect(find.text('demo'), findsOneWidget);
    expect(find.text('Etc/UTC'), findsOneWidget);
  });
}
