# Items: linked banks

Linking a bank through Plaid Link, the Items the app keeps with their health, repairing an
Item's login, syncing one, and unlinking with the choice of keeping or deleting its
history. Code: `app/lib/features/items/` (`domain/`, `data/`, `application/`,
`presentation/`); the Items table and the Plaid apply paths are `data.md`'s, and the pull
that fills them is `sync-app.md`'s **The Plaid pull**. Tests: `app/test/features/items/`,
`app/test/core/plaid/`, `app/integration_test/items_flow_test.dart`. The server's side
is `server.md`; the facts about Plaid Link and update mode are `PLAN.md` §4.

## Items on the device

An Item is one login at one institution. The device keeps the server's list in the
`items` table (`data.md`, schema 3) through `ItemRepository` (`domain/item_repository.dart`;
Drift, in-memory and demo implementations under one contract suite), as `LinkedBank`
values: the `shared_models` `Item` (its `status`, Plaid's `errorCode`, the last successful
sync) and `Institution`, the institution's logo bytes when fetched, and when the pull last
wrote it. The pull fetches each logo once through `getInstitutionLogo` (the server's logo
route is bearer-secured, so the screen cannot load `logo_url` itself) and stores the
bytes against that URL (`ItemRepository.saveLogo`); a new URL clears them and they are
fetched again. Items are server-authoritative (`PLAN.md` §6.4,
§12): only the Plaid pull, an exchange's answer and a login-required answer write them,
and nothing about them is recorded in the change log. The demo flavor's store is loaded
with the persona's Items, which its fake server also lists.

## The launcher

`domain/link_launcher.dart` is the platform boundary for Plaid Link: `LinkLauncher.open
(linkToken)` answers `LinkSucceeded(publicToken, institution)` or `LinkExited(error)`, the
error null when the user simply closed Link. One session at a time: a second open while one
is open is a `StateError`. The public token is never logged (`toString` leaves it out).

| Launcher | Where | What |
|---|---|---|
| `PlaidFlutterLinkLauncher` (`data/`) | dev and prod on the network (the default of `linkLauncherProvider`) | `plaid_flutter` 5.2.1: it listens to the plugin's static `PlaidLink.onSuccess` and `onExit` streams from before `PlaidLink.create(configuration: LinkTokenConfiguration(token:))`, then `PlaidLink.open()`, takes the first outcome and cancels both subscriptions. A `PlatformException` from create or open (no activity attached, a token the SDK refuses) is an exit with the code `platform_error`. |
| `FakeLinkLauncher` (`data/`) | the demo flavor, `FT_FAKE_SERVER`, the tests (through `fakeApiOverrides`, as the API fake is wired) | No Plaid UI: it answers with `FakeServer.completeLink(linkToken)`, Plaid's side of Link played by the fake, which remembers each link token's user and update Item. A new link gets `public-demo-<item id>` of the first dataset Item the user has not linked (the first when all are); an update-mode token gets `public-demo-update-<item id>`. Test hooks: `exitNext([error])`, `hold`, `opened`. |

`plaid_flutter` compiles against Android SDK 34 (its own `compileSdk`) while the app
targets 36; it ships a consumer ProGuard file, and the app's `proguard-rules.pro` keeps
`com.plaid.**` and every Room database's constructor (the SDK's WorkManager needs it;
`build.md`). On Android, the link token is created with the app's package name
(`PackageInfo.packageName`: `dev.tarnan.financetracker` for dev and prod), which must be
registered with Plaid (`PLAN.md` §4).

**Known limitation.** `open` completes only when the plugin sends a success or an exit.
If the native side never sends one (the activity destroyed while Link is open), the
future never completes: the launcher stays open, and Link cannot be opened again (nor
the action leave its `linking` step) until the app restarts.

## The Link controller

`application/link_controller.dart`, `linkControllerProvider` (keep-alive), holds a
`LinkState`: the action of a new link (`newLink`, before its Item exists) and one
`ItemAction` per Item (`byItem`), each a running `ItemStep` or a failure
(`domain/item_action.dart`); a missing entry is idle.

| Action | Steps |
|---|---|
| `link()` | `linking`: `createLinkToken(androidPackageName)`, then the launcher. A plain exit ends idle; an exit with an error fails `ItemLinkFailure`. On success `exchanging`: `exchangePublicToken`, and the answered Item is stored at once (`applyPlaidItem`). Then the Item's own action: **sync and pull**. |
| `repair(itemId)` | `linking`: `createUpdateLinkToken(itemId, androidPackageName)`, then the launcher; on success **no exchange** (Plaid repaired the Item in update mode), then sync and pull. |
| `sync(itemId)` | Sync and pull. |
| `unlink(itemId, keepHistory:)` | `unlinking`: `deleteItem(itemId, history: keep or delete)` (a `NotFound` counts as already removed), then `pulling`. With `keep` the server lists the Item `removed` with its accounts and transactions, which stay on every device, no longer updated; with `delete` it drops the Item and its accounts and tombstones its transactions, and the pull takes them away (`data.md`, **The Plaid apply paths**). |

**Sync and pull**: `syncing` asks `syncItem` until it answers `completed`, waiting
`linkPollIntervalProvider` (5 s) between requests, at most `syncTries` (24) times;
`not_ready` and `started` keep asking (Plaid is still extracting; never "no
transactions"). Then `pulling`: `PlaidPull.run()` (`sync-app.md`). When the sync never
completed, the pull still runs, so the Item and what it has show, and the action ends
`ItemStillPreparing` ("still preparing; Sync now in a minute").

**Failures** stay on the action until that Item's next action, never thrown: an
`ApiException` becomes `ItemApiFailure` with its class (`offline` for a `NetworkError`,
`loginRequired`, `rateLimited` with the server's `Retry-After`, `notFound`, `plaid`,
`server` for any other answer; `other` for a failure that is not the server's). An `ItemLoginRequired` from any call also marks the stored Item
`loginRequired` (`ItemRepository.markLoginRequired`), so Fix connection appears before
the next pull confirms it. One action per Item at a time, and one Link session at a time
(`LinkState.linkBusy`): a link or repair asked for while Link is open does nothing.

## The screen

`presentation/items_screen.dart`, `ItemsRoute` (`/accounts/linked-banks`), opened from the
Accounts app bar ("Linked banks") and from Settings → Account → Linked banks. One card per
Item, as `ItemRepository.watchAll` orders them (`linkedBanksProvider`):

- the institution's logo when the server gave one (`Image` from the stored bytes), else
  its initial; its name; "Last synced <date time>" in the device's zone (the clock's
  location), or "Not synced yet";
- a status chip, drawn by hand so its label wraps at large text sizes, with its own
  semantics node ("Status: Connected"): healthy is Connected; login required and pending
  expiration Needs attention; error and unknown Error; removed Unlinked;
- for an Item not removed: Sync now; Fix connection only when the login must be
  repaired; Unlink, which asks in a
  dialog whether to keep the history on this device and others (its accounts and
  transactions stay, no longer updated) or delete its accounts and transactions (removed
  from every device signed in to the account, the user's own notes and categories on them
  included);
- the action's progress, or its failure in the error color, in a live region.

Each button's semantics label names its bank ("Sync now, First Platypus Bank"), so a
screen reader can tell the cards' buttons apart; the visible text stays short.

An Item unlinked with its history kept (`removed`) is listed, as Unlinked, only while one
of its accounts is still live on the device (`linkedBanksProvider`); the server keeps it
in `GET /plaid/items` for as long as it keeps its rows. Its one action is Delete history:
a dialog spells out that its accounts and transactions go from every device signed in to
the account, then `unlink(itemId, keepHistory: false)` (the server, and the fake, accept
`history=delete` on a `removed` Item: no Plaid call, the rows tombstoned). Otherwise the
kept history could never go, since a linked account cannot be deleted on the device.

"Link a bank" is the floating button and the empty state's action ("No linked banks");
the new link's progress and failure show above the list. Every string is in the ARB.

## Arrival

Each transaction a pull inserts goes once to the arrival processor (`ArrivalProcessor`,
`sync-app.md`, **The Plaid pull**), the seam the rules engine fills, inside the page's
transaction. The processor gets the row as stored: an override another device recorded
before the row arrived (a category, notes, tags, splits, a receipt) is already on it.

## Linked data elsewhere

A linked account cannot be deleted on the device, and neither can a Plaid transaction
(`BankDataNotDeletableException`; the account detail and the transaction editor offer no
Delete for them): bank data goes only when its Item is unlinked or the bank removes it,
so the pull can apply the server's tombstones as sent (`data.md`). Unlinking does not
deduplicate or touch manual entries: a manual transaction on a linked account outlives
the account's deletion and shows under the orphan rule (`sync-app.md`).

## The demo

The demo's fake server serves the persona's household, linked for the demo user, followed
by Houndstooth Bank (`ins_109512`, Item `demo-houndstooth`: the sample's accounts and
transactions at a Sandbox institution no persona uses), unlinked: Link a bank in the demo
adds it, through the fake launcher and the pull, with no network: the pull after the Link
brings Houndstooth Bank's accounts and transactions, so its three accounts show their
balances from transactions. The demo's pull cursor starts after the seed its store
already holds, at the version the fake recorded when it seeded the demo user (`sync-app.md`,
**The Plaid pull**), so that pull brings only Houndstooth Bank's rows and the demo's own
edits of its rows stand.

Under `FT_FAKE_SERVER` the dev flavor's database starts empty at sign-in and its cursor
at 0; the fake is new in each process, so after a relaunch the next pull applies the
fake's rows again over local edits of those `demo` rows.

## Tests

| Test | What it proves |
|---|---|
| `test/contract/item_repository_contract.dart` | Every field round-trips; the order; the server's list replacing the stored one; one Item upserted; the login-required mark; nothing recorded; in the three implementations |
| `test/features/items/data/link_launchers_test.dart` | The plaid_flutter launcher over a scripted platform (success with the institution, exits, Link failing to open, the subscriptions gone, one session at a time); the fake launcher's next Item, update-mode token, unknown token, scripted exit and held session |
| `test/features/items/application/demo_link_test.dart` | The demo wiring: a Link with no pull before it brings Houndstooth Bank's transactions; a deleted and a renamed demo transaction survive the pull, and a Link brings only Houndstooth Bank's rows |
| `test/features/items/application/link_controller_test.dart` | Link with the exchange, the sync through `not_ready` and the pull, and every step in order; exits; repair with no exchange, after the fake's reset-login; sync; login required marking the Item; unlink deleting the history, and unlink keeping it then deleting the kept history; a sync that never completes; a failure after the exchange shown on the new Item; a server error in its own class; a rate limit; one Link session at a time |
| `test/features/items/presentation/items_screen_test.dart` | The chips, the last sync in another zone, Fix connection only where needed, an unlinked bank shown only while its accounts are, linking from the empty state, a failure on its card, the unlink dialog, the entries from Accounts and Settings |
| `test/features/items/presentation/items_screen_golden_test.dart` | The screen with three banks and empty, light and dark |
| `test/accessibility_test.dart` | The screen empty and with banks, and the unlink dialog, against the three guidelines and at text scale 2 |
| `integration_test/items_flow_test.dart` | On the harness: the demo's banks, and the demo linking Houndstooth Bank (absent before, present after); under `FT_FAKE_SERVER`, the dev flavor registering, linking, seeing the accounts, the fake's reset-login showing Needs attention and Fix connection repairing it, then unlinking with its history deleted |
