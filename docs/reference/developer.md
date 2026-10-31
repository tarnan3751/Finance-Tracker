# The developer menu

The dev flavor's tools for driving the development server's Plaid Sandbox controls from
the emulator (`PLAN.md` §6.5, §8 Phase 3): diagnostics, the Plaid pull on demand, the
Item operations of contract 0.3.0 and persona provisioning. Dev only: the settings screen
lists the section only when `AppConfig.flavor` is `dev`, so demo and prod have none.
Code: `app/lib/features/developer/` (`application/`, `presentation/`). Tests:
`app/test/features/developer/`, `app/integration_test/developer_menu_test.dart`. The
operations themselves are `api.md`'s (**Items and the Sandbox controls**) and the
server's (`server.md`); the pull is `sync-app.md`'s **The Plaid pull**.

Every call goes through `FinanceApi`: nothing here reaches Plaid or holds a key, and on
a server that cannot drive Sandbox the controls answer `409 conflict`, shown as such.
Under `FT_FAKE_SERVER` the in-app fake answers every operation (`app-core.md`, **The
fake server**), which is how the menu is tested on the harness.

## The section

`presentation/developer_section.dart`, the last section of Settings:

- **Diagnostics**: the server's API base URL (or "In-app fake server"), this device's id
  at the server (`syncDeviceIdProvider`; "Not signed in" without a session), the last
  sync, when the bank data was last pulled (the later of the sync controller's
  `plaidPulledAt` and the menu's own last pull), and the outbox and held records from
  the sync ledger ("Not read yet" before the controller has read it, and always in a
  build whose data does not sync).
- **Pull now**: `PlaidPull.run()`, its outcome on one line (when the last whole pull
  finished, or the exception).
- **Copy diagnostics**: the rows above as plain `label: value` lines to the clipboard.
  Ids, times and counts only, never a token.
- **Sandbox controls** opens `DeveloperScreen` (pushed on the Settings tab's stack, not a
  route, so prod and demo have no path to it).

## The Sandbox controls

`presentation/developer_screen.dart`:

- **Item**: a picker of the stored Items not `removed` (`developerItemsProvider`, over
  `ItemRepository.watchAll`), then Refresh transactions (`refreshItem`), Refresh balances
  (`refreshBalances`), Reset login (`sandboxResetLogin`) and Fire webhook
  (`sandboxFireWebhook`, a picker of the contract's `WebhookCode`s in Plaid's spelling).
- **Inject transactions** into the picked Item (`sandboxCreateTransactions`): one of its
  accounts on the device (`developerItemAccountsProvider`), how many (1 to 10, numbered
  after the description when more than one), a description, an amount in the app's
  sign (negative is money out; the client negates it for the wire) in the account's
  currency, and how many days before **Plaid's today** they are dated, 0 to 728
  (`maxDaysBack`: Plaid refuses a date older than the UTC date minus 729, and Plaid's
  today is the UTC date or the day before, so 728 back is always accepted). Plaid's
  today is the calendar date at UTC−12 of the device clock (`plaidToday`): the server
  refuses a later date, so before 12:00 UTC it is yesterday's UTC date (`PLAN.md` §12,
  contract 0.3.0 as delivered). The form shows the resulting date.
- **Provision a persona** (`provisionPersona`): persona, seed (at least 1) and days of
  history (30 to 730), Start; then the job's state, a progress bar over Items linked and
  batches sent, the skipped count and the job's error, asked for (`getProvisionJob`)
  every 5 s while the job is queued or running **and the screen is open**, a tick
  skipped while the last request is still unanswered. The job id is
  kept in the controller, so closing the screen stops the polling and opening it again
  resumes it. A finished job offers Pull now.
- **Background worker**: Run the background worker in 20 seconds
  (`developerWorkerDelay`) asks `BackgroundWork.runSyncLater` for one sync 20 s out
  (unique work `ft.sync.dev`, `background.md`, **Scheduling**) and says when it was
  scheduled for, or why it was not. It is how the worker is run with no app: kill the
  process inside the delay, as `adb shell run-as dev.tarnan.financetracker kill -9
  <pid>` does, and the job then starts the dispatcher's engine alone (`background.md`,
  **Testing**, says why a forced run, a force-stop and `am kill` do not serve).

## The controller

`application/developer_controller.dart`, `developerControllerProvider` (keep-alive),
holds a `DeveloperState`: the operation running (one at a time; every control is
disabled meanwhile), the last Item operation's `DeveloperResult`, the last pull's
outcome, and the provisioning job (its id, its last state, why starting or polling it
last failed).

- Each Item operation is followed by the pull. Its result line is what the call answered
  (the `SyncRun`, the number of accounts, the number injected) or the failure; a pull
  that fails after a successful operation is named beside it. A failed operation pulls
  nothing; an `ItemLoginRequired` also marks the stored Item for repair, as the Link
  controller does (`items.md`).
- A failure is shown as `ApiException.toString` names it (its type, status and code; a
  validation failure adds the fields at fault), any other exception by its type. Only
  exception types are logged.

## Tests

| Test | What it proves |
|---|---|
| `test/features/developer/developer_controller_test.dart` | Over the fake server through a recording adapter: each operation's request for the Item with its body (the webhook code, the injected transactions in Plaid's sign dated from Plaid's today), then the pull; a failed operation pulling nothing; an `item_login_required` answer marking the stored healthy Item `loginRequired` with Plaid's code; a failed pull named beside the operation; the provisioning request, one job at a time, a poll skipped while a held one is unanswered, polled to completion and not after; Plaid's today either side of 12:00 UTC |
| `test/features/developer/developer_menu_test.dart` | The section only in dev; the diagnostics, Pull now and the copied text; every control answered for the Item and followed by the pull; a failure on its line; injection on the chosen account and date; the form's validation; provisioning polled with `advanceClock`, stopping with the screen and resuming on its return, and Pull now bringing the persona's banks; Run the background worker asking for one sync 20 s out |
| `test/features/developer/developer_accessibility_test.dart` | The section and the controls, light and dark, against the three guidelines and at text scale 2 (the controls are pushed, not routed, so they are not in `test/accessibility_test.dart`'s list) |
| `test/features/developer/developer_section_golden_test.dart` | The section, light and dark |
| `integration_test/developer_menu_test.dart` | On the harness under `FT_FAKE_SERVER`: register, link, reset login from the menu and repair it from Linked banks, inject two transactions and see them in Transactions |
