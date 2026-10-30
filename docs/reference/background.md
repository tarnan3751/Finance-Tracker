# Background sync and notifications

The app syncs while it is closed: WorkManager runs a sync cycle about every hour on a
network with the battery not low, through Doze's maintenance windows. It also owns its
notification channels, posts what it tells the user to the system tray as well as the
in-app list, asks for the permission to notify once, and shows all of it in
Settings → Notifications. The decisions are in `PLAN.md` §12: "Background sync design",
"Database sharing with the worker", "Notification channels and the sync finding",
"Phase 8 package pins and platform rulings" and "8a plan rulings".

Code:
- `app/lib/core/platform/`: the seams, each an interface, a fake and a provider that
  defaults to the fake:
  - `background_work.dart`, `workmanager_background_work.dart`,
    `fake_background_work.dart`, `background_work_provider.dart`: the schedule;
  - `connectivity.dart`, `platform_connectivity.dart`, `fake_connectivity.dart`,
    `connectivity_provider.dart`: whether a network is up;
  - `notification_channels.dart`, `local_notification_channels.dart`,
    `fake_notification_channels.dart`, `system_settings.dart`: the channels and Android's
    settings screens;
  - `local_notifications.dart`, `local_notifications_provider.dart`: the one
    `flutter_local_notifications` instance and its taps;
  - `system_notifier.dart`: the tray's `Notifier` and the `CompositeNotifier`;
  - `notification_providers.dart`: the providers of the above, the channels' names and
    each kind's text, and `NotificationPermission`.
- `app/lib/core/background/`: `background_dispatcher.dart` (the task's entry point),
  `background_cycle.dart` (the cycle), `background_ports.dart` (the app and the worker in
  one process), `background_sync_watcher.dart` (the app's side), `background_hooks.dart`.
- `app/lib/features/settings/application/notifications_overview.dart` and
  `presentation/notifications_screen.dart`: Settings → Notifications.
- `MainActivity.kt`: the `dev.tarnan.financetracker/system_settings` channel (`build.md`).

## Scheduling

`BackgroundWork` has `schedulePeriodicSync(every:, constraints:)`, `runSyncNow()`,
`cancelAll()` and `periodicState()`. Over `workmanager` 0.10.10 (dev and prod):

- The periodic sync is unique work `ft.sync.periodic`, every 60 minutes (WorkManager's
  window makes it 60 to 75), on a connected network with the battery not low,
  `ExistingPeriodicWorkPolicy.keep` (a restart keeps the cadence; the plugin's own
  default would update it), a linear backoff from WorkManager's default delay of 30 s,
  and no foreground service.
- The one-off is unique work `ft.sync.once` (kept while one waits) on a connected
  network: expedited on Android 12 and later, plain work when the quota is out; plain
  work below Android 12, where expedited work needs a foreground notification the
  plugin's worker does not give.
- Both carry the tag `ft.sync`. `cancelAll()` cancels that tag, never WorkManager's
  cancel-everything, which would also cancel the Plaid SDK's work.
- The flavor travels in the input data, so one dispatcher serves dev and prod.

`BackgroundSyncWatcher` (listened to by `bootstrap` in every flavor; it does nothing where
the data does not sync, so the demo flavor never schedules) schedules the periodic sync
whenever someone is signed in and the device-local switch is on
(`app_meta.background_sync_enabled`, absent meaning on), and cancels it on a sign-out or
when the switch goes off. The local wipe cancels it too (`data.md`, **The local wipe**),
so account deletion and erasing the device do. The sync controller queues the one-off
when the app is left while changes wait after a failed session (`sync-app.md`, **The
controller**).

## The isolate

WorkManager starts the task in a new Flutter engine of the app's process: its own
isolate, its own heap, the same native SQLite library. `backgroundDispatcher` (a
top-level `@pragma('vm:entry-point')` function) calls `Workmanager().executeTask`, which
sets up the binding, then does what the app's `bootstrap` does once per process: logging
with the flavor's sink (prod keeps sanitised records in memory, `app-core.md`,
**Logging**), the time zones, intl's default locale, and then every locale's date
symbols (`initializeDateFormatting()`: the app has them from flutter_localizations at its
first frame, which this engine never draws, and a step formatting a date in another
locale, such as the widgets' snapshot, would throw without them); the database opener
sets SQLite's temporary directory itself. It then runs `runBackgroundCycle` on the flavor's own wiring
(`overridesFor`), in a new `ProviderContainer`.

## One session at a time

Two sessions on one account in one process would share the server's rotating refresh
token (the server's reuse detection would end the session) and race their pushes, and
the app's Drift streams would not see what another connection wrote. So the app and the
worker coordinate through named ports every engine in the process sees
(`IsolateNameServer`, `background_ports.dart`):

Each side registers its own name before it looks at the other's, so a worker and an app
that start together always see each other.

- **`ft.background`** is a lock, taken by a cycle before anything else
  (`acquireBackgroundCycle`). A name already registered is taken: when its holder answers
  a ping within a second another cycle runs (the periodic sync and a one-off are
  different unique works, and can start together) and this one returns done without a
  cycle; when it does not answer, its engine is gone and left the name behind, so the
  cycle removes it, only if it still holds the same port, and takes it. That check and
  removal is not atomic across isolates, so a worker that took a dead holder's name looks
  again 50 ms later and steps aside if the name is no longer its own. `startApp` waits for
  the lock to go, at most 45 s (the cycle's 30 s deadline plus its 10 s close), before it
  opens anything local (the native launch screen covers the wait), pinging the holder
  each time it looks: a holder that stops answering (its engine died with its cycle
  pending) is stale and removed, if it still holds the same port. The
  lock is released when the cycle has stopped, and released at once when the app takes
  the sync.
- **`ft.app`**, registered by `bootstrap` once per process (dev and prod) and again on
  every resume (an app whose name a worker removed comes back). A cycle that holds the
  lock asks it. While no app runs in it (a restore or a wipe has stopped it) the app
  answers `busy` and the cycle does nothing, so it never touches files being replaced or
  deleted. Otherwise the app answers `ack`, runs Sync now itself (the session and the
  Plaid pull; the reminder watcher and the widgets follow the sync as they always do),
  records the run as delegated (held, while the restore offer holds sync) and answers
  `done` with the outcome; a second ask while it runs joins the same sync. No `ack`
  within 2 s is followed by a second ask with 5 s: no answer to that either means the
  app's engine is gone, and the cycle removes the name, only if it still holds the port
  it asked, and runs its own session. An `ack` with no `done` within 30 s ends the cycle
  as done.
- Before every refresh the client reads the session again from storage
  (`TokenStore.reload`, `auth.md`), so a refresh made in the other isolate is reused
  rather than repeated with a spent token. A storage that fails during that read keeps
  the session in memory (its type logged); only a value that cannot be parsed is
  discarded.

## The cycle

`runBackgroundCycle(BackgroundEnvironment)` returns true (done) or false (WorkManager
retries on its backoff), in order:

1. The demo flavor has no server: done ("background: demo, nothing to sync").
2. The `ft.background` lock is taken, then the app is asked (**One session at a time**):
   a live cycle holding the lock, a busy app or an app that ran the sync ends the cycle.
3. Guards, before anything is opened, each done with nothing touched: a pending wipe
   (`wipe_pending_v1`, read after a reload of the preferences, which another engine may
   have written), no stored session, or no database file or no key. The cycle never
   creates a key or a database.
4. A probe connection reads `PRAGMA user_version`, `app_meta.fts_definition` and the
   full-text objects: a schema this build does not open as it is (the app has not
   migrated yet, or a newer build has), a definition that is absent or another, or a
   missing full-text object is done, so the cycle never runs a schema step (they run
   outside a transaction and must not race the app's) or builds the full-text index.
5. The database opens (**The database**); the stored session is read
   (`SessionController.restored()`, as at the app's start); a pending restore offer
   (`backup.md`) holds the cycle, recorded as `held`, since a restore must land before
   the server's copy does.
6. The sync controller's start session runs and is awaited (`firstSession()`): adopt the
   device id, push, pull, then the Plaid pull. The reminders are planned again
   (`reminderPlannerProvider` over `reminderInputsProvider`, in the device's zone), and
   `backgroundCycleHooksProvider`'s steps run in order, after the session, so the
   session is restored and the stored tokens wired: the home screen widgets' snapshot
   written once (`writeWidgetsNow`, `widgets.md`), a failing step logged by type.
7. The outcome is recorded in `app_meta.background_last_run` as `{at, result,
   delegated}`: `synced`, `offline` (the one result that returns false), `failed` (the
   server's or another failure), `sessionEnded`, `skipped` (a guard), `held` (the restore
   offer) or `timedOut`. A session the
   server ended (the cycle's client cleared it on a 401) is recorded in
   `app_meta.session_ended_in_background`, which the app's next start turns into the
   sign-in screen's notice (`auth.md`), and told on `sync_problems`.

Steps 3 to 7 run under a 30 s deadline (`backgroundCycleDeadline`). Past it the cycle
records `timedOut` if it can within 2 s and returns done. On every path, the deadline's
included, the cycle disposes its container and closes the database (waiting at most
10 s) before it returns: Drift's database isolate is spawned with `Isolate.spawn` and
nothing ties it to the engine, so the engine's end is not known to end it, and a
connection left open could keep the WAL write lock; closing the connection makes Drift
roll back whatever transaction it left open (a host test cuts one with the deadline and
finds nothing written on a fresh open). The `ft.background` lock is released when the
cycle has actually stopped, not when the deadline returned, so a starting app never
opens the database beside a cycle still running. Nothing is logged but types and outcomes. On the
harness AVD, with the family persona, the app's first full sync took about 8 s and a
delta cycle about 0.3 s.

## The database

Every connection sets `PRAGMA busy_timeout = 5000` (right after the key) and
`journal_mode = WAL` at open (`data.md`, **Encryption and the key**). A write that meets
the other connection's write waits up to five seconds; past that it fails with
`SQLITE_BUSY` and the cycle's session fails as any session does. Readers never block the
writer. Both connections load the one SQLite3 Multiple Ciphers library of the process, so
SQLite's in-process lock bookkeeping sees both. Drift streams never see another
connection's writes: on resume, when `background_last_run` moved since the app last looked
and the worker ran it (not delegated), the app calls `markTablesUpdated` on every table
(`BackgroundSyncWatcher`).

## Notifications

**Channels.** Four, with fixed ids, created at every start by `bootstrap` after the first
frame with their names and descriptions in the device's locale (`channelTextsProvider`);
Android takes a second creation as a rename and never changes a created channel's
importance, so an id keeps its importance for good:

| Id | Importance | What |
|---|---|---|
| `budget_alerts` | default | A budget reached 80 % or 100 % (`budgets.md`, **Alerts**) |
| `bill_reminders` | default (the id Phase 5 created) | The scheduled bill reminders (`bills.md`, **Reminders**) |
| `weekly_summary` | low | The weekly summary is ready (`reports.md`) |
| `sync_problems` | default | Sync has failed for a day, the session ended, or a bank needs its sign-in |

**The tray.** In dev and prod `appNotifierProvider` is a `CompositeNotifier` of the in-app
list and `SystemNotifier`, which tells each in order, one failure not stopping the next.
`SystemNotifier` posts a notification with `systemNoticeTextProvider`'s text (title,
body, the route its tap opens) on its channel, tagged with the channel's id (so its id,
a 31-bit hash of the notification's key, never meets a bill reminder's), alerting once
(raising the same key again replaces it quietly). A `BillDueNotification` stays in-app
only: the bill's scheduled reminder is its tray notification. A tap's payload is
`{"route": <location>}`; `LocalNotifications` hands reminder payloads to the scheduler and
route payloads to `routes`, which `bootstrap` pushes. The plugin keeps one tap callback
per engine, so everything shares `LocalNotifications`' one initialization.

**Sync problems.** `SyncProblemNotification` (`core/platform/notifier.dart`): `failing`
(every session since the last success, `since`, has failed for a day; told once per last
success), `bankNeedsAttention` (an Item `login_required` or `pending_expiration` after a
Plaid pull; told once per Item while it stays so), and `signedOut` (the background cycle
found the session ended). The first two are told once on the device, whichever container
meets them (the app's, or each background cycle's, which is a container of its own): the
keys told are kept in `app_meta.sync_problems_told` (device-local) and dropped when the
problem clears (a session that succeeds, a bank that no longer needs its sign-in), so a
later occurrence is told again. The in-app list shows all three, and a tap opens the
linked banks or Settings.

**The permission.** `NotificationPermission.ask()` asks for Android 13's
`POST_NOTIFICATIONS` once on the device (`app_meta.notification_permission_asked`), the
first time a notifying feature is turned on (a bill saved with reminders on, a new budget
saved) or from Settings → Notifications, never at launch. Once refused it is not asked
again: the bill editor shows its sheet pointing to Android's settings, and the
Notifications screen says notifications are off with a button to them.

## Settings

Settings → Notifications (`/settings/notifications`, from the Notifications row in
Settings) reads `notificationsOverviewProvider` again on every resume:

- "Notifications are off for this app" with "Turn on notifications" while the app may
  not notify: it asks (once), then opens Android's app notification settings;
- one row per channel: its name and description and its state, read from the platform
  (a channel is off when its importance reads `none`, which `areNotificationsEnabled`
  does not show; every channel reads off while the whole app is), each opening that
  channel's settings (`android.settings.CHANNEL_NOTIFICATION_SETTINGS`);
- Background sync: a switch over `background_sync_enabled`, where WorkManager has the
  periodic sync (`BackgroundWork.periodicState()`: scheduled, with its cadence; running
  now; or not scheduled while signed out), and the last run and its outcome, a held one
  included (dev and prod; the demo says it has none);
- when Android restricts the app's background work (restricted by the user, or the
  restricted standby bucket), a note and a button to the app's settings in Android.

A state that cannot be read says so, with Try again. The demo flavor shows the screen
over the fakes' state.

## Testing

- `app/test/core/platform/background_work_test.dart`: the workmanager implementation's
  calls over a recording platform, and the fake.
- `app/test/core/platform/connectivity_test.dart`, `system_notifications_test.dart`: the
  connectivity fake; the channels, the tray notifier, the composite and the permission
  against the plugin's mocked channel.
- `app/test/core/db/open_database_wal_test.dart`: WAL and the busy timeout on every
  connection, a write waiting for the other connection's transaction, an uncommitted
  transaction leaving nothing.
- `app/test/core/background/`: the cycle on a real encrypted file (what it runs and
  records, its result, every guard, the full-text and key-less ones included, a session
  ended, a held run, two cycles at once of which one runs, the deadline, and a
  transaction the deadline cut leaving nothing on a fresh open); the ports (the lock
  taken once, a live holder kept, a dead one replaced, two workers racing a dead holder
  of which one keeps it, a holder that stops answering ending the app's wait, a worker
  and an app starting
  together, a slow app asked twice and kept, a mapping replaced meanwhile kept, the app
  registering again); the watcher (the schedule, and the streams told to read again on
  resume after the worker's own run).
- `app/test/core/sync/sync_controller_test.dart`: a failed session followed by a
  returning network runs a session with no tap; the backoff, its cap, the debounce
  waiting for it, resume bypassing it, no retry armed while paused or offline, the
  connections dropped; the sync problems told once across containers and again once
  cleared.
- `app/test/core/api/token_store_test.dart`, `auth_interceptor_test.dart`: the reload
  before a refresh, keeping the session on a storage failure.
- `app/test/core/db/local_wipe_test.dart`: the background step among the wipe's cuts.
- `app/test/features/settings/notifications_screen_test.dart` (the error state, the
  schedule line, a held run) and the accessibility test.
- `app/integration_test/background_sync_test.dart` (the harness's `integration`): the
  cycle's body in the test isolate on an encrypted database on the device and the fake
  server with the family persona (the widgets' step writing its snapshot), and the
  periodic sync scheduled with the real plugin and read back from WorkManager.
- `tools/scripts/background_doze_check.sh` (`testing-tools.md`) proves, on `ft-lane`,
  that WorkManager keeps the periodic sync's job, that Doze defers it while the device is
  idle (JobScheduler reports `readyNotDozing: false`) and that the job runs the
  dispatcher's engine in Doze's maintenance window; only that run counts, nothing forces
  the job. It does not prove a sync under Doze: the demo flavor's cycle returns at its
  first step. A real sync against the dev server under Doze is the coordinator's
  dev-flavor acceptance.
