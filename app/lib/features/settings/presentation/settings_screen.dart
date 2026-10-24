/// The Settings tab: Account (`features/auth/presentation/account_section.dart`), Sync
/// (dev and prod, `sync_section.dart`), Appearance (theme mode, dynamic color), Data
/// (category management) and About (app name, version and build, flavor, the time zone
/// dates are computed in), then Demo data (demo only, `demo_data_section.dart`).
library;

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/auth/presentation/account_section.dart';
import 'package:finance_tracker/features/settings/application/package_info.dart';
import 'package:finance_tracker/features/settings/application/settings_controller.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:finance_tracker/features/settings/presentation/demo_data_section.dart';
import 'package:finance_tracker/features/settings/presentation/settings_section_header.dart';
import 'package:finance_tracker/features/settings/presentation/sync_section.dart';
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
          const AccountSection(),
          if (ref.watch(appConfigProvider).flavor != Flavor.demo)
            const SyncSection(),
          SettingsSectionHeader(l10n.settingsAppearance),
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
          SettingsSectionHeader(l10n.settingsData),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(l10n.categoriesTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const CategoriesRoute().push<void>(context),
          ),
          SettingsSectionHeader(l10n.settingsAbout),
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
          if (ref.watch(appConfigProvider).flavor == Flavor.demo)
            const DemoDataSection(),
        ],
      ),
    );
  }
}
