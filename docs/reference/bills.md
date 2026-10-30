# Bills

The user's bills, when each is due, whether it was paid or missed, and the reminders
before each due date (`PLAN.md` §12 "Bills" and "Reminders", §6.8). The feature is
`app/lib/features/bills/`; the platform boundary is `app/lib/core/platform/
reminder_scheduler.dart`. The bills are the Plan tab's Bills segment, a list and a
calendar (**Screens**).

## The model

A bill is `BillReminder` (`shared_models`, `core.md`), user data, synced as the
`bill_reminder` record (`sync-app.md`) and stored in `bills` (`data.md`):

| Field | What |
|---|---|
| `name` | Required for new bills; null only on records older than the field, shown by the linked stream's name, else "Bill" |
| `amount` | The expected amount, `Money`, in the app's sign (an outflow is negative); optional |
| `dueDate` | The first due date, from which `cadence` repeats it; never moved by the app |
| `cadence` | `weekly`, `biweekly`, `semiMonthly`, `monthly`, `quarterly`, `annually`; null for once |
| `accountId` | The account it is paid from; null: any account |
| `streamId` | The recurring stream it was accepted from |
| `liabilityAccountId` | The liability it follows: its due dates follow the liability's `nextPaymentDueDate` |
| `reminderOffsetDays` | Days before each due date to remind, distinct, 0 to 30; default `[2]` |
| `reminderMinutes` | The reminders' local wall-clock time, minutes after midnight; default 540 (09:00) |
| `active` | An inactive bill is kept and never reminded |
| `autopay` | An autopay bill is never missed |
| `paidOccurrences` | The due dates the user marked paid, ascending, distinct, the latest 24 (normalized when read from JSON too) |

The paid marks are a field of the bill, not rows of their own: one record syncs the whole
bill. The field is one value under last-writer-wins, so two devices marking different
occurrences at the same time keep one device's list; a mark on one device and an edit of
another field on the other both survive (`test/sync/two_device_convergence_test.dart`).

## Occurrences

`domain/bill_schedule.dart`: the due dates of a bill from its anchor by its cadence. The
anchor is the bill's `dueDate`, and no occurrence is before it; a bill that follows a
liability with a next payment due date is anchored on that date instead, which is
always an occurrence (the institution's date is authoritative), and its series runs both
ways with no floor.
Weekly and biweekly step 7 and 14 days; monthly, quarterly and annually keep the anchor's
day of the month, clamped to short months from the anchor each time (January 31 gives
February 28, then March 31; February 29 gives February 28 in common years); semimonthly
runs on the anchor's day `d` and the day 15 away in the same month (`d` and `d + 15` when
`d` is 15 or less, else `d - 15` and `d`), each clamped; a one-off (or `unknown`) is its
date once. `between(from, to)`, `nextOnOrAfter(today)`, `previousBefore(today)`; the
last two find the neighbour however far it is (a one-off years past, an annual bill whose
first date is more than a year ahead).

A stream link gives the bill its values only when the suggestion is accepted; after that
the bill keeps its own schedule, since a stream's predicted date moves when a payment is
late and a missed payment could then never show.

## Status

`domain/bill_status.dart`, computed and never stored. An occurrence due `D` is:

- **paid** when the user marked it, or a payment matches: a live, non-hidden transaction
  (pending included) on the bill's account (any when it has none), an outflow in the
  bill's currency whose size is within the band (the linked stream's when it has one,
  else 10 % either side of the expected amount, in minor units), dated 7 days before `D`
  to 3 after. Payments are assigned once across every active bill (`assignPayments`,
  `PLAN.md` §12 "5c review rulings"; an inactive bill takes no payment, no reminder and no
  due notice, and stays in the list as paused): a transaction pays at most one occurrence of one bill and an
  occurrence takes at most one transaction, the candidates taken by the distance from
  the due date, then a bill on the transaction's account before an any-account bill, then
  the earlier due date, then the bill id, then the transaction id. So one payment of
  50.00 never pays two 50.00 bills, and on weekly bills, whose windows overlap, it pays
  its nearest occurrence. A bill with no expected amount and no band is paid only by a
  mark;
- **due** when unpaid from 7 days ahead until 3 days past;
- **missed** when unpaid more than 3 days past, unless the bill is on autopay;
- **upcoming** otherwise.

`billStatus(bill, today, paid:)`, with the bill's share of the assignment, gives `BillStatus { bill, nextDue,
lastOccurrence, state, matchedTransactionId }`, the first that applies: the next
occurrence already paid (paid early); the last one in its grace days (due); the next one
due; the last one missed (it stays missed until the next is due); the last one paid;
else upcoming. `occurrenceState` gives one occurrence's state, for the calendar.

## Suggestions

`domain/bill_suggestions.dart`, over `BillSourceData`, which `billSourceDataProvider`
fills: active, unmuted expense streams with a known cadence and a next date (by the name
the app shows), and liabilities with a next payment due date (named by their account),
that no live bill links. Accepting a stream makes a bill with its name, amount, next date,
cadence, account and link; accepting a liability makes a monthly bill at the minimum
payment (as an outflow) that follows it. By due date, then name.

## Reminders

`domain/reminder_times.dart`: for each occurrence on or after today and each offset, the
local date that many days before at the bill's time, built with `tz.TZDateTime(location,
y, m, d, h, min)` in the device's zone, never by adding a `Duration` across days. A time
a DST gap skips moves later by the gap (02:30 on a spring-forward day is 03:30); a time
a fall-back day has twice is its first occurrence. The `timezone` package gives the
first only west of UTC, so when the zone's previous period had a larger offset and the
instant earlier by the difference shows the same wall clock, that one is used. The
plugin sends Android the wall clock and the zone name and Java's `ZonedDateTime.of`
resolves them the same way (the earlier offset in an overlap, later by the gap in a
gap), so the platform schedules the instant computed here. Past instants are skipped,
and so is anything more than 60 days ahead (the zone database has no transitions after
2037, which a 60-day window never reaches).

`application/reminder_planner.dart`: `ReminderPlanner.plan` takes the active bills with
reminders, leaves out the occurrences already paid (by a mark, or in the same payment
assignment the statuses read, `billPaymentsProvider`), keeps the 64 soonest reminders (by
instant, then bill, due date, offset; Android refuses more than 500 alarms an app), gives
each its id (`reminderId`: a 31-bit FNV-1a hash of bill id, due date and offset, the next
free id on a collision), hands the set to the scheduler (`replaceAll`), and writes
`reminders_zone` and `reminders_scheduled_at` to `app_meta`. For each unpaid occurrence
due today or tomorrow of a bill with reminders it raises a `BillDueNotification` (key
`bill/<id>/<due>`) through the `Notifier`, once per occurrence (`bill_alerts`), so the
in-app list shows it even when the system notification is late. Plans run one at a time
and never throw; a failure is logged by type.

`ReminderWatcher` runs it a second after the last trigger:

- at start: `bootstrap` listens from the first frame, in every flavor;
- when the bills, the followed liabilities' due dates, the streams' names or the
  payment assignment change (`reminderInputsProvider`; the assignment follows the
  transactions around the due dates and today), which covers a bill edited here or
  arriving by sync and a payment arriving by the pull;
- after a sync session or a Plaid pull (`SyncStatus.lastSyncAt`, `plaidPulledAt`);
- on resume, when the device's zone (`deviceZoneName()` in `core/time/time_zone_setup.dart`,
  read each time) is not `reminders_zone`.

The platform keeps the instant each reminder was given and does not follow a zone change
(the plugin has no zone receiver), so planning again is the correction. The planner
plans in the device's zone as read then; the rest of the app keeps the zone it started
with until the next launch. A zone the database does not know plans in the app's zone.

The texts are localized when planned (`reminderTextProvider`): "Rent is due today",
"... tomorrow", "... Mon, Nov 2", and "Expected $1,500.00".

## The platform boundary

`ReminderScheduler` (`core/platform/reminder_scheduler.dart`, pure Dart):
`ensurePermission({request})`, `replaceAll(reminders)` (makes the pending set exactly
those, cancelling the rest by id, so a notification already shown stays), `pending()`,
`cancelAll()` (pending only), `clearAll()` (pending and shown: the local wipe's,
`data.md`), `openSettings()`, and `openedBillIds` (the bills whose
reminder was tapped, the one that launched the app first). `ScheduledReminder(id, billId,
dueDate, at, title, body)` carries `{"bill", "due", "at"}` as its payload, `at` a UTC
instant, from which `pending()` reads the set back: the platform keeps no time.
`reminderSchedulerProvider` is the fake (`fake_reminder_scheduler.dart`: the pending set
in memory, the permission set by the test, `fire(id)` and `tap(billId)`) by default and
in the demo flavor, and `LocalNotificationsScheduler` in dev and prod.

`local_notifications_scheduler.dart` is over `flutter_local_notifications` 22.3.2:
initialized on first use with the small icon `ic_stat_bill`; `zonedSchedule` with
`AndroidScheduleMode.inexactAllowWhileIdle` (no exact-alarm permission: Android 14
denies it by default, so a reminder may come up to about an hour late) on the one channel
`bill_reminders` (its id and default importance kept: Android never changes a created
channel's importance), named and described from the ARB; the app's other channels, their
creation at each start and Settings → Notifications are in `background.md`,
**Notifications**. The plugin's one initialization is shared through
`local_notifications.dart`. The permission is Android 13's `POST_NOTIFICATIONS`, asked
once on the device (`NotificationPermission`, `background.md`) when the user saves a bill
with reminders on, never at startup. A `BillDueNotification` stays in-app only: the
scheduled reminder is its tray notification. The background sync plans the reminders
again after each of its cycles. A tap pushes `/bills/:id`
(`bootstrap`). After a reboot the plugin's boot receiver schedules its pending
notifications again from its own cache; the planner's start-up run covers the rest. The
Android pieces (desugaring, the receivers, `RECEIVE_BOOT_COMPLETED`, the icon and its
keep file) are in `build.md`.

## Repositories and providers

`BillRepository` (`watchAll()` by first due date then id, `watchById`, `upsert`, `delete`,
`restore`) in Drift, in-memory and demo implementations under
`test/contract/bill_repository_contract.dart`; every write records what it changed. The
demo starts with two bills per persona (`data/demo_bills.dart`), from the persona's
recurring expectations without touching the engine: the largest fixed monthly outflow
(the rent or the mortgage), its last occurrence marked paid, and the largest
subscription, each linked to its demo stream (`demo-stream-<key>`), from the
expectation's first nominal date two months back. `BillAlertStore` is Drift
(`bill_alerts`) in dev and prod and in memory otherwise.

| Provider | What |
|---|---|
| `billsProvider` | The live bills |
| `billPaymentsProvider` | Which transaction paid which occurrence, one assignment across every active bill, over the occurrences due from 370 days back (or from the oldest one-off bill's date, when older: a one-off's only occurrence stays its last, so its payment is always looked for) to the end of the reminder window and its offsets, and the transactions from 7 days before that to 3 after |
| `billStatusesProvider` | Each bill's status today, from `billPaymentsProvider` |
| `paidBillKeysProvider` | The in-app keys of the occurrences paid now, so the alerts sheet hides a due notice a later pull paid |
| `streamNamesProvider`, `liabilityDueDatesProvider` | The streams' names, and the followed liabilities' next due dates by bill |
| `billSourceDataProvider`, `suggestedBillsProvider` | What suggestions are made from, and the suggestions |
| `reminderInputsProvider` | What the reminders are planned from, `billPaymentsProvider` among them |
| `reminderTextProvider` | The reminders' localized texts |
| `billActionsProvider` | `save`, `delete`, `restore`, `accept(suggestion, id)`, `setPaid(id, due, paid:)` |
| `reminderPlannerProvider`, `reminderWatcherProvider` | The planner, and the watcher that runs it |
| `deviceZoneProvider`, `reminderDebounceProvider` | The device's zone (tests override it), and the watcher's debounce |

## Screens

**The Bills segment** (`/bills`, `presentation/bills_screen.dart`), the Plan tab's second
segment (`app-core.md`, **The Plan tab**; `PLAN.md` §12 "5e rulings"). Its app bar opens
the subscriptions (`recurring.md`, **Screens**) and a new bill. A list and a calendar
view, switched by the control at the top of the body.

The list:
- **Suggested**, first, when `suggestedBillsProvider` has suggestions this device has not
  dismissed: the first three, then "Show all (N)", which reveals the rest, so the bills
  stay near the top; each with its name, cadence, next due date and amount; Add opens the editor
  prefilled from it (`/bills/new?stream-id=<id>` or `?liability-account-id=<id>`; nothing
  is saved until Save), Dismiss hides it on this device only: the keys (`stream/<id>`,
  `liability/<account id>`) are kept in `app_meta` under `bill_suggestions_dismissed`
  (`dismissedBillSuggestionsProvider`), never synced. A dismissed stream can still be made
  a bill from the subscriptions screen.
- The active bills in three groups, each row showing one occurrence (`billFocus`, `domain/bill_status.dart`, which the home
  screen widget's bills read too, `widgets.md`): the
  missed one, else the one due (the last, while in its grace days, before the next), else
  the next. **Overdue**: the last occurrence missed. **Due soon**: the occurrence shown is
  due within 7 days, or is in its grace days. **Later**: the rest, by date, the bills due
  past the 60 days and those with no next due date at the end (so every bill can be
  reached). Each row: the name, the due date (relative from 6 days back to 7 days ahead:
  "Due yesterday", "Due today", "Due in 3 days", "Due in 7 days"; else "Due Nov 10,
  2026"), the expected amount,
  a chip (Missed in the error colour; Paid; Autopay for an autopay bill not yet paid), and
  **Mark paid** when the occurrence shown is due or missed: `setPaid(id, due, paid:
  true)` for that occurrence, with an Undo. Tapping a row opens the editor.
- **Paused (N)**, folded: the inactive bills ("5c review rulings" item 8), with no chip,
  no Mark paid and no date; tapping one opens the editor, where the Active switch is.

The calendar: a month grid (previous and next month; the week starts on the locale's
first day; today ringed, the chosen day filled; the numbers stop growing at 1.5 times the
text size so a week fits) with a dot per active bill due that day from its
`BillSchedule` (in the error colour when that occurrence was missed; at most three), and
the chosen day's bills under it, as list rows for that occurrence. It opens on today's
month with today chosen. Each day reads "Nov 3, 2 bills due: Netflix, Rent". Paused bills
have no dot.

With no bills and no suggestions the segment shows an empty state with New bill.

The Plan tab's icon carries a badge with the number of active bills whose status is
missed (`AppShell`). Screen readers hear the count in words with the tab ("1 missed
bill", then "Plan"), since the destination's tooltip ("Plan, 1 missed bill") is left out
of semantics.

`/bills/new` and `/bills/:id` are the editor
(`presentation/bill_editor_screen.dart`): name, expected amount (in a currency of the
accounts), first due date, how often, the account it is paid from, the reminder days
(on the day, 1, 2, 3 or 7 days before) and time (the time picker), active, autopay, and
Delete with undo (the editor pops back where it was opened from, whose messenger is on
screen, so the Undo shows even when a reminder's tap opened it on another tab). Saving
saves first, then, with reminders on, asks for the permission when the app lacks it and
has never asked on this device; a refusal (now or earlier) shows
`notification_permission_sheet.dart` (the bill is saved; why, and Open settings). Both
happen only while the editor is the page on screen: a save that lands after the user went
elsewhere asks nothing.
`/bills/new?stream-id=<id>` and `?liability-account-id=<id>` start from that
stream's or liability's suggestion (one without a suggestion starts empty). The
in-app alerts sheet (`budgets.md`, **Alerts**) lists `BillDueNotification`s ("Rent is due
Nov 1") and opens the bill; a notice whose occurrence is paid since (a pull brought the
payment after the notice was raised) is left out of the sheet and the count, and the
`bill_alerts` row stays so it is not raised again.

## Tests

Domain: `test/features/bills/domain/` (every cadence across month ends and February,
the status cases, suggestions, reminder instants across DST in New York, Berlin and
Auckland both ways). The planner and the watcher with the fake scheduler, a zone change
between two runs among them: `test/features/bills/application/`. The scheduler over the
plugin's mocked channel: `test/core/platform/local_notifications_scheduler_test.dart`.
The record: `test/core/db/drift_sync_store_test.dart`; the schema step:
`test/drift/migration_test.dart`; convergence: `test/sync/two_device_convergence_test.dart`.
The screens: `test/features/bills/presentation/` (the groups, Mark paid, the badge, the
calendar across a month end in New York, the suggestions, goldens of the list, the
calendar and a suggestion), on `test/helpers/bill_seed.dart`.
On the harness: `app/integration_test/bills_reminders_test.dart` (a bill due tomorrow in
the demo, and the real plugin's pending set; firing is not awaited, since an inexact
alarm may come late).
