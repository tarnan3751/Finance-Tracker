// The reminder planner: the set it hands the scheduler (the window, the cap, paid
// occurrences left out, the zone's wall clock across DST), a zone change between two
// runs, the in-app notification once per occurrence, and the watcher's triggers (start,
// a bill change, a sync, today, and a resume that finds the zone changed).
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/fake_reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/bills/application/reminder_planner.dart';
import 'package:finance_tracker/features/bills/data/in_memory_bill_alert_store.dart';
import 'package:finance_tracker/features/bills/domain/bill_schedule.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Notifier;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../contract/repository_fixture.dart' show testTransaction;

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

/// Rent on the 1st, reminders 2 days before at 09:00, from checking.
BillReminder rent({
  List<int> offsets = const [2],
  bool active = true,
  List<LocalDate> paid = const [],
  RecurringCadence cadence = RecurringCadence.monthly,
  String id = 'rent',
}) => BillReminder(
  id: id,
  name: 'Rent',
  amount: Money(-150000, 'USD'),
  dueDate: d(2027, 1, 1),
  cadence: cadence,
  accountId: 'checking',
  reminderOffsetDays: offsets,
  active: active,
  paidOccurrences: paid,
);

({String title, String body}) text(
  BillReminder bill,
  String? name,
  LocalDate due,
  int offset,
) => (title: '${name ?? 'Bill'} $due -$offset', body: '${bill.amount}');

final class _Sync extends SyncController {
  @override
  SyncStatus build() => const SyncStatus(phase: SyncPhase.idle);

  void synced(DateTime at) =>
      state = state.copyWith(lastSyncAt: at, failure: null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tzdata.initializeTimeZones);

  late FakeReminderScheduler scheduler;
  late InMemoryAppMetaStore meta;
  late InMemoryBillAlertStore alerts;
  late List<AppNotification> told;
  late ReminderPlanner planner;

  setUp(() {
    scheduler = FakeReminderScheduler();
    meta = InMemoryAppMetaStore();
    alerts = InMemoryBillAlertStore();
    told = [];
    planner = ReminderPlanner(
      scheduler,
      meta,
      alerts,
      _ListNotifier(told),
      text,
    );
  });

  group('the planner', () {
    final DateTime now = DateTime.utc(2027, 3, 10, 12); // 07:00 EST
    late final tz.Location newYork = tz.getLocation('America/New_York');
    late final tz.Location berlin = tz.getLocation('Europe/Berlin');

    test('plans the next 60 days at the wall-clock time across DST', () async {
      await planner.plan(ReminderInputs(bills: [rent()]), now, newYork);
      final List<ScheduledReminder> set = scheduler.replaced.single;
      expect([for (final r in set) r.dueDate], [d(2027, 4, 1), d(2027, 5, 1)]);
      // 2027-03-30 09:00 EDT (after the 03-14 change) and 2027-04-29 09:00 EDT.
      expect(set.first.at.toUtc(), DateTime.utc(2027, 3, 30, 13));
      expect(set.first.id, reminderId('rent', d(2027, 4, 1), 2));
      expect(set.first.title, 'Rent 2027-04-01 -2');
      expect(set.first.billId, 'rent');
      expect(await meta.read(AppMetaKeys.remindersZone), 'America/New_York');
      expect(
        await meta.read(AppMetaKeys.remindersScheduledAt),
        '2027-03-10T12:00:00.000Z',
      );
    });

    test(
      'leaves out inactive bills, bills with no reminders and paid occurrences',
      () async {
        await planner.plan(
          ReminderInputs(
            bills: [
              rent(paid: [d(2027, 4, 1)]),
              rent(id: 'off', active: false),
              rent(id: 'silent', offsets: const []),
            ],
            // A payment found for 05-01.
            payments: {
              'rent': {d(2027, 5, 1): 'pay'},
            },
          ),
          now,
          newYork,
        );
        expect(scheduler.replaced.single, isEmpty);
      },
    );

    test(
      'one payment drops one bill\'s reminder, not every bill it matches',
      () async {
        // Two any-account monthly bills of 50.00 due the 1st and the 2nd; one 50.00
        // payment on 03-29 pays the phone's 04-01 only.
        BillReminder fifty(String id, int day) => BillReminder(
          id: id,
          name: id,
          amount: Money(-5000, 'USD'),
          dueDate: d(2027, 1, day),
          cadence: RecurringCadence.monthly,
        );
        final List<BillReminder> bills = [
          fifty('phone', 1),
          fifty('internet', 2),
        ];
        final BillPayments payments = assignPayments(
          [
            for (final BillReminder b in bills)
              (bill: b, schedule: BillSchedule.of(b), band: null),
          ],
          [testTransaction('t', 'checking', -5000, date: d(2027, 3, 29))],
          d(2026, 1, 1),
          d(2028, 1, 1),
        );
        await planner.plan(
          ReminderInputs(bills: bills, payments: payments),
          now,
          newYork,
        );
        expect(
          [
            for (final r in scheduler.replaced.single)
              '${r.billId} ${r.dueDate}',
          ],
          ['internet 2027-04-02', 'phone 2027-05-01', 'internet 2027-05-02'],
        );
      },
    );

    test('keeps the 64 soonest', () async {
      final List<BillReminder> bills = [
        for (int i = 0; i < 10; i++)
          rent(
            id: 'gym$i',
            cadence: RecurringCadence.weekly,
            offsets: const [0, 1],
          ),
      ];
      await planner.plan(ReminderInputs(bills: bills), now, newYork);
      final List<ScheduledReminder> set = scheduler.replaced.single;
      expect(set, hasLength(reminderLimit));
      expect({for (final r in set) r.id}, hasLength(reminderLimit));
      for (int i = 1; i < set.length; i++) {
        expect(set[i].at.isBefore(set[i - 1].at), isFalse);
      }
      // 10 bills x 2 a week: the 64 soonest end in the fourth week.
      expect(set.last.at.isBefore(DateTime.utc(2027, 4, 7)), isTrue);
    });

    test(
      'a zone change replans every reminder at the new wall clock',
      () async {
        final ReminderInputs inputs = ReminderInputs(
          bills: [
            rent(offsets: const [0, 2]),
          ],
        );
        await planner.plan(inputs, now, newYork);
        final List<ScheduledReminder> before = await scheduler.pending();
        await planner.plan(inputs, now.add(const Duration(hours: 1)), berlin);
        final List<ScheduledReminder> after = await scheduler.pending();
        expect(after, hasLength(before.length));
        for (final ScheduledReminder r in after) {
          final tz.TZDateTime local = tz.TZDateTime.from(r.at, berlin);
          expect((local.hour, local.minute), (9, 0));
        }
        expect(
          after.any((r) => before.any((b) => b.at.isAtSameMomentAs(r.at))),
          isFalse,
        );
        expect(await meta.read(AppMetaKeys.remindersZone), 'Europe/Berlin');
      },
    );

    test('tells the in-app list once of an unpaid occurrence due today or tomorrow', () async {
      final DateTime eve = DateTime.utc(2027, 3, 31, 14); // 10:00 EDT, 03-31
      final ReminderInputs inputs = ReminderInputs(
        bills: [
          rent(),
          rent(id: 'paid', paid: [d(2027, 4, 1)]),
        ],
        streamNames: const {},
      );
      await planner.plan(inputs, eve, newYork);
      await planner.plan(inputs, eve.add(const Duration(hours: 2)), newYork);
      expect([for (final n in told) n.key], ['bill/rent/2027-04-01']);
      final BillDueNotification n = told.single as BillDueNotification;
      expect(n.name, 'Rent');
      expect(n.dueDate, d(2027, 4, 1));
      expect(n.amount, Money(-150000, 'USD'));
    });

    test('an unnamed bill takes its stream name', () async {
      await planner.plan(
        ReminderInputs(
          bills: [
            BillReminder(
              id: 'old',
              streamId: 's1',
              dueDate: d(2027, 4, 1),
              amount: Money(-1549, 'USD'),
            ),
          ],
          streamNames: const {'s1': 'Netflix'},
        ),
        now,
        newYork,
      );
      expect(scheduler.replaced.single.single.title, 'Netflix 2027-04-01 -2');
    });
  });

  group('the watcher', () {
    late String zone;
    late ProviderContainer container;
    late _Sync sync;

    setUp(() {
      zone = 'America/New_York';
      container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.demo()),
          clockProvider.overrideWithValue(
            FixedClock(
              DateTime.utc(2027, 3, 10, 12),
              tz.getLocation('America/New_York'),
            ),
          ),
          reminderSchedulerProvider.overrideWithValue(scheduler),
          appMetaStoreProvider.overrideWithValue(meta),
          deviceZoneProvider.overrideWithValue(() async => zone),
          reminderDebounceProvider.overrideWithValue(Duration.zero),
          syncControllerProvider.overrideWith(() => sync = _Sync()),
        ],
      );
      addTearDown(container.dispose);
    });

    Future<void> settle() async {
      for (int i = 0; i < 5; i++) {
        await pumpEventQueue();
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('plans at start, on a bill change, after a sync, and on a resume in a new zone', () async {
      final ProviderSubscription<void> sub = container.listen(
        reminderWatcherProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      container.read(syncControllerProvider);
      await settle();
      expect(scheduler.replaced, hasLength(1), reason: 'at start');
      expect(scheduler.replaced.last, isEmpty);

      await container.read(billRepositoryProvider).upsert(rent());
      await settle();
      expect(scheduler.replaced, hasLength(2), reason: 'a bill change');
      expect(scheduler.replaced.last, hasLength(2));

      sync.synced(DateTime.utc(2027, 3, 10, 12, 5));
      await settle();
      expect(scheduler.replaced, hasLength(3), reason: 'after a sync');

      final TestWidgetsFlutterBinding binding =
          TestWidgetsFlutterBinding.instance;
      void resume() {
        for (final AppLifecycleState state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          binding.handleAppLifecycleStateChanged(state);
        }
      }

      resume();
      await settle();
      expect(scheduler.replaced, hasLength(3), reason: 'same zone');

      zone = 'Europe/Berlin';
      resume();
      await settle();
      expect(scheduler.replaced, hasLength(4), reason: 'a new zone');
      for (final ScheduledReminder r in scheduler.replaced.last) {
        final tz.TZDateTime local = tz.TZDateTime.from(
          r.at,
          tz.getLocation('Europe/Berlin'),
        );
        expect((local.hour, local.minute), (9, 0));
      }
      expect(await meta.read(AppMetaKeys.remindersZone), 'Europe/Berlin');
      expect(container.read(inAppNotificationsProvider), isEmpty);
    });

    test('plans in the app zone when the device zone is unknown', () async {
      zone = 'Mars/Olympus_Mons';
      await container.read(billRepositoryProvider).upsert(rent());
      final ProviderSubscription<void> sub = container.listen(
        reminderWatcherProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      await settle();
      expect(await meta.read(AppMetaKeys.remindersZone), 'America/New_York');
      expect(scheduler.replaced.last, hasLength(2));
    });
  });
}

final class _ListNotifier implements Notifier {
  _ListNotifier(this._told);

  final List<AppNotification> _told;

  @override
  Future<void> notify(AppNotification notification) async =>
      _told.add(notification);
}
