/// The Settings tab: Appearance (theme mode, dynamic color) and About (app name, version
/// and build, flavor, the time zone dates are computed in).
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/settings/application/package_info.dart';
import 'package:finance_tracker/features/settings/application/settings_controller.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The settings screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Settings? settings = ref.watch(settingsControllerProvider).value;
    final PackageInfo? packageInfo = ref.watch(packageInfoProvider).value;
    final String appName = ref.watch(appConfigProvider).appName;
    // The flavor's identifier (dev, demo, prod), not prose, so it is not localized.
    final String flavor = ref.watch(appConfigProvider).flavor.name;
    final String timeZone = ref.watch(clockProvider).location.name;
    final SettingsController controller = ref.read(
      settingsControllerProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          _SectionHeader(l10n.settingsAppearance),
          if (settings == null)
            const LinearProgressIndicator()
          else ...[
            ListTile(
              title: Text(l10n.settingsThemeMode),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SegmentedButton<AppThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: AppThemeMode.system,
                      label: Text(l10n.themeModeSystem),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.light,
                      label: Text(l10n.themeModeLight),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      label: Text(l10n.themeModeDark),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) =>
                      controller.setThemeMode(selection.single),
                ),
              ),
            ),
            SwitchListTile(
              title: Text(l10n.settingsDynamicColor),
              subtitle: Text(l10n.settingsDynamicColorSubtitle),
              value: settings.useDynamicColor,
              onChanged: controller.setUseDynamicColor,
            ),
          ],
          _SectionHeader(l10n.settingsAbout),
          ListTile(title: Text(l10n.aboutAppName), subtitle: Text(appName)),
          ListTile(
            title: Text(l10n.aboutVersion),
            subtitle: packageInfo == null
                ? null
                : Text(
                    l10n.aboutVersionValue(
                      packageInfo.version,
                      packageInfo.buildNumber,
                    ),
                  ),
          ),
          ListTile(title: Text(l10n.aboutFlavor), subtitle: Text(flavor)),
          ListTile(title: Text(l10n.aboutTimeZone), subtitle: Text(timeZone)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
