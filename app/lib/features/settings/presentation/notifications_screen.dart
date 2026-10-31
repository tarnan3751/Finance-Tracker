/// Settings → Notifications (`docs/reference/background.md`, **Settings**): one row per
/// notification channel with its state as Android reports it (on, off, or off with the
/// whole app), each opening that channel's settings in Android; "Turn on notifications"
/// while the app may not notify (asking once, then opening Android's settings); the
/// background sync's switch with where WorkManager has it and its last run (dev and
/// prod; the demo has no server); and, when Android restricts the app's background work,
/// a note with a button to the app's settings. Read again whenever the app resumes; a
/// state that cannot be read says so, with Try again.
library;

import 'dart:async';

import 'package:finance_tracker/core/background/background_cycle.dart';
import 'package:finance_tracker/core/background/background_sync_watcher.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/background_work.dart';
import 'package:finance_tracker/core/platform/notification_channels.dart';
import 'package:finance_tracker/core/platform/notification_providers.dart';
import 'package:finance_tracker/core/time/date_time_format.dart';
import 'package:finance_tracker/features/settings/application/notifications_overview.dart';
import 'package:finance_tracker/features/settings/presentation/settings_section_header.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The screen.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(notificationsOverviewProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _turnOn(bool asked) async {
    if (asked) {
      await ref.read(notificationChannelsProvider).openAppSettings();
    } else {
      await ref.read(notificationPermissionProvider).ask();
    }
    if (mounted) ref.invalidate(notificationsOverviewProvider);
  }

  Future<void> _setBackground(bool on) async {
    await ref.read(backgroundSyncWatcherProvider.notifier).setEnabled(on);
    if (mounted) ref.invalidate(notificationsOverviewProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<NotificationsOverview> overview = ref.watch(
      notificationsOverviewProvider,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNotifications)),
      body: switch (overview) {
        AsyncData(:final NotificationsOverview value) => _body(
          context,
          l10n,
          value,
        ),
        AsyncError() => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.notificationsLoadFailed),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(notificationsOverviewProvider),
                child: Text(l10n.notificationsTryAgain),
              ),
            ],
          ),
        ),
        _ => const LinearProgressIndicator(),
      },
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    NotificationsOverview value,
  ) {
    final NotificationsState state = value.notifications;
    final ThemeData theme = Theme.of(context);
    return ListView(
      children: [
        if (!state.appEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.notificationsAppOff,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => unawaited(_turnOn(value.asked)),
                  child: Text(l10n.notificationsTurnOn),
                ),
              ],
            ),
          ),
        for (final AppChannel channel in AppChannel.values)
          _ChannelTile(channel: channel, state: state),
        SettingsSectionHeader(l10n.backgroundSyncTitle),
        if (!value.backgroundAvailable)
          ListTile(
            leading: const Icon(Icons.sync_disabled),
            title: Text(l10n.backgroundSyncTitle),
            subtitle: Text(l10n.backgroundSyncUnavailable),
          )
        else
          SwitchListTile(
            secondary: const Icon(Icons.sync),
            title: Text(l10n.backgroundSyncTitle),
            subtitle: Text(
              '${_schedule(l10n, value)}\n'
              '${_lastRun(l10n, value.lastRun)}',
            ),
            isThreeLine: true,
            value: value.backgroundEnabled,
            onChanged: (on) => unawaited(_setBackground(on)),
          ),
        if (value.restricted)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.backgroundRestricted),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => unawaited(
                    ref.read(systemSettingsProvider).openAppDetails(),
                  ),
                  child: Text(l10n.backgroundOpenAppSettings),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Where WorkManager has the periodic sync: its cadence while scheduled.
  String _schedule(AppLocalizations l10n, NotificationsOverview value) =>
      switch (value.schedule) {
        BackgroundWorkState.scheduled => l10n.backgroundSyncSchedule,
        BackgroundWorkState.running => l10n.backgroundSyncRunningNow,
        BackgroundWorkState.none when value.backgroundEnabled =>
          l10n.backgroundSyncNotScheduled,
        BackgroundWorkState.none => l10n.backgroundSyncSchedule,
      };

  String _lastRun(AppLocalizations l10n, BackgroundRun? run) {
    if (run == null) return l10n.backgroundSyncNever;
    return l10n.backgroundSyncLastRun(
      formatDateTime(run.at, ref.read(clockProvider).location),
      switch (run.result) {
        BackgroundResult.synced => l10n.backgroundResultSynced,
        BackgroundResult.offline => l10n.backgroundResultOffline,
        BackgroundResult.failed => l10n.backgroundResultFailed,
        BackgroundResult.sessionEnded => l10n.backgroundResultSessionEnded,
        BackgroundResult.skipped => l10n.backgroundResultSkipped,
        BackgroundResult.timedOut => l10n.backgroundResultTimedOut,
        BackgroundResult.held => l10n.backgroundResultHeld,
      },
    );
  }
}

/// One channel: its name, what it is for, its state; a tap opens its settings.
class _ChannelTile extends ConsumerWidget {
  const _ChannelTile({required this.channel, required this.state});

  final AppChannel channel;
  final NotificationsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final (String name, String description, IconData icon) = switch (channel) {
      AppChannel.budgetAlerts => (
        l10n.budgetAlertsChannelName,
        l10n.budgetAlertsChannelDescription,
        Icons.savings_outlined,
      ),
      AppChannel.billReminders => (
        l10n.billRemindersChannelName,
        l10n.billRemindersChannelDescription,
        Icons.receipt_long_outlined,
      ),
      AppChannel.weeklySummary => (
        l10n.weeklySummaryChannelName,
        l10n.weeklySummaryChannelDescription,
        Icons.insights_outlined,
      ),
      AppChannel.syncProblems => (
        l10n.syncProblemsChannelName,
        l10n.syncProblemsChannelDescription,
        Icons.sync_problem_outlined,
      ),
    };
    final String status = !state.appEnabled
        ? l10n.notificationsChannelAppOff
        : state.shows(channel)
        ? l10n.notificationsChannelOn
        : l10n.notificationsChannelOff;
    return Semantics(
      onTapHint: l10n.notificationsChannelHint,
      child: ListTile(
        leading: Icon(icon),
        title: Text(name),
        subtitle: Text('$description\n$status'),
        isThreeLine: true,
        trailing: const Icon(Icons.open_in_new),
        onTap: () => unawaited(
          ref.read(notificationChannelsProvider).openChannelSettings(channel),
        ),
      ),
    );
  }
}
