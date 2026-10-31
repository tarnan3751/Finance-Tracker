/// The notification seams' providers (`docs/reference/background.md`,
/// **Notifications**): the channels and the system settings (fakes by default, the
/// demo flavor's and the tests'; the platform's in dev and prod through `overridesFor`),
/// the channels' names in the device's locale, what each kind says in the tray and
/// where its tap goes, and the one-time permission request.
library;

import 'dart:ui' show PlatformDispatcher;

import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/fake_notification_channels.dart';
import 'package:finance_tracker/core/platform/notification_channels.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/platform/system_notifier.dart';
import 'package:finance_tracker/core/platform/system_settings.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/time/date_time_format.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart' show basicLocaleListResolution;
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

part 'notification_providers.g.dart';

/// The channels.
@Riverpod(keepAlive: true)
NotificationChannels notificationChannels(Ref ref) =>
    FakeNotificationChannels();

/// The system's settings screens and the background restriction.
@Riverpod(keepAlive: true)
SystemSettings systemSettings(Ref ref) => FakeSystemSettings();

/// The strings of the device's locale, for what is shown outside the app's widgets.
AppLocalizations deviceLocalizations() => lookupAppLocalizations(
  basicLocaleListResolution(
    PlatformDispatcher.instance.locales,
    AppLocalizations.supportedLocales,
  ),
);

/// The channels' names and descriptions in the device's locale, read at each start.
@Riverpod(keepAlive: true)
Map<AppChannel, ChannelText> channelTexts(Ref ref) {
  final AppLocalizations l10n = deviceLocalizations();
  return {
    AppChannel.budgetAlerts: (
      name: l10n.budgetAlertsChannelName,
      description: l10n.budgetAlertsChannelDescription,
    ),
    AppChannel.billReminders: (
      name: l10n.billRemindersChannelName,
      description: l10n.billRemindersChannelDescription,
    ),
    AppChannel.weeklySummary: (
      name: l10n.weeklySummaryChannelName,
      description: l10n.weeklySummaryChannelDescription,
    ),
    AppChannel.syncProblems: (
      name: l10n.syncProblemsChannelName,
      description: l10n.syncProblemsChannelDescription,
    ),
  };
}

/// What each kind says in the tray, in the device's locale, and the route its tap opens;
/// a bill due has no tray notice of its own (its reminder is one).
@Riverpod(keepAlive: true)
NoticeText systemNoticeText(Ref ref) => (notification) async {
  final AppLocalizations l10n = deviceLocalizations();
  final tz.Location zone = ref.read(clockProvider).location;
  return switch (notification) {
    final BudgetThresholdNotification alert => (
      channel: AppChannel.budgetAlerts,
      title: l10n.notificationBudgetTitle,
      body: l10n.alertBudgetThreshold(
        (await ref
                    .read(categoryRepositoryProvider)
                    .watchById(alert.categoryId)
                    .first)
                ?.name ??
            l10n.budgetDeletedCategory,
        alert.thresholdBp ~/ 100,
        alert.available.format(),
        DateFormat.MMMd().format(tz.TZDateTime.from(alert.raisedAt, zone)),
      ),
      route: BudgetTransactionsRoute(alert.budgetId).location,
    ),
    WeeklySummaryNotification() => (
      channel: AppChannel.weeklySummary,
      title: l10n.alertWeeklySummary,
      body: l10n.notificationWeeklySummaryText,
      route: const WeeklySummaryRoute().location,
    ),
    final SyncProblemNotification problem => (
      channel: AppChannel.syncProblems,
      title: l10n.notificationSyncTitle,
      body: syncProblemText(problem, l10n, zone),
      route: problem.problem == SyncProblem.bankNeedsAttention
          ? const ItemsRoute().location
          : const SettingsRoute().location,
    ),
    BillDueNotification() => null,
  };
};

/// What [problem] says, in [l10n], its times in [zone].
String syncProblemText(
  SyncProblemNotification problem,
  AppLocalizations l10n,
  tz.Location zone,
) => switch (problem.problem) {
  SyncProblem.failing => l10n.alertSyncFailing(
    problem.since == null ? '' : formatDateTime(problem.since!, zone),
  ),
  SyncProblem.signedOut => l10n.alertSyncSignedOut,
  SyncProblem.bankNeedsAttention => l10n.alertBankNeedsAttention,
};

/// Asks for the permission to notify once, ever, on this device
/// (`notification_permission_asked` in `app_meta`): the first time a notifying feature
/// is turned on (a bill reminder, a new budget's alerts) or from Settings →
/// Notifications, never at launch. Once refused, it is not asked again; the screen says
/// notifications are off and opens the system's settings instead.
final class NotificationPermission {
  /// The permission through [_scheduler]'s platform call, remembered in [_meta].
  const NotificationPermission(this._scheduler, this._meta, this._now);

  final ReminderScheduler _scheduler;
  final AppMetaStore _meta;
  final DateTime Function() _now;

  /// Whether the app may notify, asking the user first if it never has.
  Future<bool> ask() async {
    if (await _scheduler.ensurePermission(request: false)) return true;
    if (await asked()) return false;
    await _meta.write(
      AppMetaKeys.notificationPermissionAsked,
      const UtcInstantConverter().toJson(_now()),
    );
    return _scheduler.ensurePermission(request: true);
  }

  /// Whether the user has been asked on this device.
  Future<bool> asked() async =>
      await _meta.read(AppMetaKeys.notificationPermissionAsked) != null;
}

/// The permission.
@Riverpod(keepAlive: true)
NotificationPermission notificationPermission(Ref ref) =>
    NotificationPermission(
      ref.watch(reminderSchedulerProvider),
      ref.watch(appMetaStoreProvider),
      ref.watch(clockProvider).nowUtc,
    );
