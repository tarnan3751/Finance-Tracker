/// The Settings tab: Account (`features/auth/presentation/account_section.dart`), Sync
/// (when this build's data syncs: dev and prod, `sync_section.dart`), Appearance (theme
/// mode, dynamic color, and in dev and demo the language: System, English or Pseudo),
/// Security (the app lock and screenshot blocking,
/// `features/lock/presentation/security_section.dart`), Notifications (the row that opens
/// `notifications_screen.dart`), Data (category management, rules,
/// export, backup; in the demo flavor the Backup entry says the demo's data is not backed
/// up) and About (app name, version and build, flavor, the time zone dates are computed
/// in), then Demo data (demo only, `demo_data_section.dart`) and Developer (dev only,
/// `features/developer/presentation/developer_section.dart`).
library;

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/layout/two_pane.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/features/auth/presentation/account_section.dart';
import 'package:finance_tracker/features/developer/presentation/developer_section.dart';
import 'package:finance_tracker/features/lock/presentation/security_section.dart';
import 'package:finance_tracker/features/settings/application/app_language_controller.dart';
import 'package:finance_tracker/features/settings/application/package_info.dart';
import 'package:finance_tracker/features/settings/application/settings_controller.dart';
import 'package:finance_tracker/features/settings/domain/app_language.dart';
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
          if (ref.watch(syncControllerProvider).phase != SyncPhase.unavailable)
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
          if (ref.watch(appConfigProvider).flavor != Flavor.prod)
            const _LanguageTile(),
          const SecuritySection(),
          SettingsSectionHeader(l10n.settingsNotifications),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l10n.settingsNotificationsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                openDetail(context, const NotificationsRoute().location),
          ),
          SettingsSectionHeader(l10n.settingsData),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(l10n.categoriesTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openDetail(context, const CategoriesRoute().location),
          ),
          ListTile(
            leading: const Icon(Icons.rule),
            title: Text(l10n.rulesTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openDetail(context, const RulesRoute().location),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: Text(l10n.exportTitle),
            subtitle: Text(l10n.exportSettingsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openDetail(context, const ExportRoute().location),
          ),
          if (ref.watch(appConfigProvider).flavor == Flavor.demo)
            ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: Text(l10n.backupTitle),
              subtitle: Text(l10n.backupDemoNote),
            )
          else
            ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: Text(l10n.backupTitle),
              subtitle: Text(l10n.backupSettingsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openDetail(context, const BackupRoute().location),
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
          if (ref.watch(appConfigProvider).flavor == Flavor.dev)
            const DeveloperSection(),
        ],
      ),
    );
  }
}

/// The language the app is shown in on this device (dev and demo only).
class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppLanguage? language = ref
        .watch(appLanguageControllerProvider)
        .value;
    if (language == null) return const SizedBox.shrink();
    return ListTile(
      title: Text(l10n.settingsLanguage),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.settingsLanguageSubtitle),
          const SizedBox(height: 8),
          SegmentedButton<AppLanguage>(
            segments: [
              ButtonSegment(
                value: AppLanguage.system,
                label: Text(l10n.languageSystem),
              ),
              ButtonSegment(
                value: AppLanguage.english,
                label: Text(l10n.languageEnglish),
              ),
              ButtonSegment(
                value: AppLanguage.pseudo,
                label: Text(l10n.languagePseudo),
              ),
            ],
            selected: {language},
            onSelectionChanged: (selection) => ref
                .read(appLanguageControllerProvider.notifier)
                .set(selection.single),
          ),
        ],
      ),
    );
  }
}
