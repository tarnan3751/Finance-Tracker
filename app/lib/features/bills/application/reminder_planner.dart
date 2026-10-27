/// Plans the bill reminders and keeps the platform's set current
/// (`docs/reference/bills.md`, **Reminders**; `PLAN.md` §12 "Reminders").
///
/// [ReminderPlanner.plan] computes every reminder of the active bills for the next 60
/// days in the device's zone (`reminder_times.dart`), leaving out the occurrences already
/// paid, keeps the [reminderLimit] soonest (Android refuses more than 500 alarms per app),
/// gives each its stable id (`reminderId`, the next free one on a collision, in instant
/// order), hands the set to the [ReminderScheduler], and records the zone and the time in
/// `app_meta`. It also raises a [BillDueNotification] in the in-app list for each unpaid
/// occurrence due today or tomorrow of a bill with reminders, once per occurrence
/// (`bill_alerts`), so the list shows it even when the system notification is late.
///
/// [ReminderWatcher] runs it, [reminderDebounce] after the last trigger: at start (when
/// `bootstrap` starts listening, after the first frame), when the bills, the transactions
/// near their due dates or today change, after a sync or a Plaid pull, and on resume when
/// the device's zone is not the one the reminders were last planned in. The platform keeps
/// the instants it was given and does not follow a zone change itself; planning again is
/// the correction. The rest of the app keeps the zone it started with.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/domain/bill_alert_store.dart';
import 'package:finance_tracker/features/bills/domain/bill_schedule.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/bills/domain/reminder_times.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

part 'reminder_planner.g.dart';

final Logger _log = Logger('bills');

/// How many reminders are kept pending at most: the soonest.
const int reminderLimit = 64;

/// The localized title and text of bill [bill]'s reminder [offset] days before its
/// occurrence due [due]; [name] is the bill's name, or its stream's for a bill recorded
/// before bills had names (null when neither is known).
typedef ReminderText = ({String title, String body}) Function(
  BillReminder bill,
  String? name,
  LocalDate due,
  int offset,
);

/// What a plan is computed from: the live bills, which transaction paid which of their
/// occurrences (`assignPayments`, shared with the bill statuses), the followed
/// liabilities' next due dates, by bill id, and the streams' names, by stream id.
final class ReminderInputs {
  const ReminderInputs({
    required this.bills,
    this.payments = const {},
    this.liabilityDue = const {},
    this.streamNames = const {},
  });

  final List<BillReminder> bills;
  final BillPayments payments;
  final Map<String, LocalDate> liabilityDue;
  final Map<String, String> streamNames;

  /// [bill]'s name, or its stream's when it has none.
  String? nameOf(BillReminder bill) => bill.name ?? streamNames[bill.streamId];
}

/// Computes the reminders and hands them to the scheduler.
final class ReminderPlanner {
  /// A planner scheduling through [_scheduler], recording in [_meta] and [_alerts],
  /// telling [_notifier], with the texts of [_text].
  ReminderPlanner(
    this._scheduler,
    this._meta,
    this._alerts,
    this._notifier,
    this._text,
  );

  final ReminderScheduler _scheduler;
  final AppMetaStore _meta;
  final BillAlertStore _alerts;
  final Notifier _notifier;
  final ReminderText _text;
  Future<void> _last = Future<void>.value();

  /// Plans [inputs] at [now] in [location]. Plans run one at a time, in call order.
  /// Never throws: a failure is logged by type, and the next trigger plans again.
  Future<void> plan(
    ReminderInputs inputs,
    DateTime now,
    tz.Location location,
  ) => _last = _last.then((_) => _plan(inputs, now, location));

  Future<void> _plan(
    ReminderInputs inputs,
    DateTime now,
    tz.Location location,
  ) async {
    try {
      final tz.TZDateTime local = tz.TZDateTime.from(now, location);
      final LocalDate today = LocalDate(local.year, local.month, local.day);
      final List<(BillReminder, ReminderTime)> times = [];
      final List<(BillReminder, LocalDate)> dueSoon = [];
      for (final BillReminder bill in inputs.bills) {
        if (!bill.active || bill.reminderOffsetDays.isEmpty) continue;
        final BillSchedule schedule = BillSchedule.of(
          bill,
          liabilityDue: inputs.liabilityDue[bill.id],
        );
        final Map<LocalDate, String> paid =
            inputs.payments[bill.id] ?? const {};
        bool isPaid(LocalDate due) =>
            paid.containsKey(due) || bill.paidOccurrences.contains(due);
        for (final ReminderTime t in reminderTimes(
          bill,
          schedule,
          now,
          location,
          skip: isPaid,
        )) {
          times.add((bill, t));
        }
        for (final LocalDate due in schedule.between(today, today.addDays(2))) {
          if (!isPaid(due)) dueSoon.add((bill, due));
        }
      }
      times.sort((a, b) {
        final int byAt = a.$2.at.compareTo(b.$2.at);
        if (byAt != 0) return byAt;
        final int byBill = a.$1.id.compareTo(b.$1.id);
        if (byBill != 0) return byBill;
        final int byDue = a.$2.due.compareTo(b.$2.due);
        return byDue != 0 ? byDue : a.$2.offset.compareTo(b.$2.offset);
      });
      final Set<int> used = {};
      final List<ScheduledReminder> reminders = [
        for (final (BillReminder bill, ReminderTime t) in times.take(
          reminderLimit,
        ))
          _reminder(bill, inputs.nameOf(bill), t, used),
      ];
      await _scheduler.replaceAll(reminders);
      await _meta.write(AppMetaKeys.remindersZone, location.name);
      await _meta.write(
        AppMetaKeys.remindersScheduledAt,
        const UtcInstantConverter().toJson(now),
      );
      for (final (BillReminder bill, LocalDate due) in dueSoon) {
        if (!await _alerts.markRaised(bill.id, due, now)) continue;
        await _notifier.notify(
          BillDueNotification(
            billId: bill.id,
            name: inputs.nameOf(bill),
            dueDate: due,
            amount: bill.amount,
            raisedAt: now,
          ),
        );
      }
    } on Object catch (e) {
      _log.warning('reminders not planned: ${e.runtimeType}');
    }
  }

  ScheduledReminder _reminder(
    BillReminder bill,
    String? name,
    ReminderTime t,
    Set<int> used,
  ) {
    int id = reminderId(bill.id, t.due, t.offset);
    while (!used.add(id)) {
      id = (id + 1) & 0x7fffffff;
    }
    final ({String title, String body}) text = _text(
      bill,
      name,
      t.due,
      t.offset,
    );
    return ScheduledReminder(
      id: id,
      billId: bill.id,
      dueDate: t.due,
      at: t.at,
      title: text.title,
      body: text.body,
    );
  }
}

/// The IANA name of the device's zone, read from the platform each time
/// (`core/time/time_zone_setup.dart`); tests override it.
@Riverpod(keepAlive: true)
Future<String> Function() deviceZone(Ref ref) => deviceZoneName;

/// How long after the last trigger the reminders are planned.
@Riverpod(keepAlive: true)
Duration reminderDebounce(Ref ref) => const Duration(seconds: 1);

/// Plans the reminders, through [reminderScheduler] and [appNotifier].
@Riverpod(keepAlive: true)
ReminderPlanner reminderPlanner(Ref ref) => ReminderPlanner(
  ref.watch(reminderSchedulerProvider),
  ref.watch(appMetaStoreProvider),
  ref.watch(billAlertStoreProvider),
  ref.watch(appNotifierProvider),
  ref.watch(reminderTextProvider),
);

/// Plans the reminders [reminderDebounce] after the last trigger, outside any build,
/// while something listens: `bootstrap` does, from the first frame, for the life of the
/// app.
@riverpod
class ReminderWatcher extends _$ReminderWatcher {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  @override
  void build() {
    final Duration debounce = ref.watch(reminderDebounceProvider);
    ref.onDispose(() {
      _timer?.cancel();
      _lifecycle?.dispose();
    });
    void trigger() {
      _timer?.cancel();
      _timer = Timer(debounce, () => unawaited(_run()));
    }

    ref
      ..listen(reminderInputsProvider, (_, next) {
        if (next.hasValue) trigger();
      }, fireImmediately: true)
      ..listen(
        syncControllerProvider.select(
          (SyncStatus s) => (s.lastSyncAt, s.plaidPulledAt),
        ),
        (_, _) => trigger(),
      );
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_checkZone(trigger)),
    );
  }

  // Plans again when the device's zone is not the one last planned in.
  Future<void> _checkZone(void Function() trigger) async {
    try {
      final String zone = await ref.read(deviceZoneProvider)();
      final String? planned = await ref
          .read(appMetaStoreProvider)
          .read(AppMetaKeys.remindersZone);
      if (zone != planned) trigger();
    } on Object catch (e) {
      _log.warning('the device zone was not read: ${e.runtimeType}');
    }
  }

  Future<void> _run() async {
    if (!ref.mounted) return;
    final ReminderInputs? inputs = ref.read(reminderInputsProvider).value;
    if (inputs == null) return;
    final Clock clock = ref.read(clockProvider);
    tz.Location location = clock.location;
    try {
      location = tz.getLocation(await ref.read(deviceZoneProvider)());
    } on Object catch (e) {
      // The platform call failed, or names a zone the database lacks: the app's zone.
      _log.warning('planning in ${location.name}: ${e.runtimeType}');
    }
    if (!ref.mounted) return;
    await ref
        .read(reminderPlannerProvider)
        .plan(inputs, clock.nowUtc(), location);
  }
}
