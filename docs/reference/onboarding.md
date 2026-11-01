# Onboarding: app mode, Welcome, server URL, help and privacy

How a fresh install of the dev or prod build chooses between the demo and the user's own
server, how the demo is marked and left, how a build with no compiled server asks for
one, and the in-app help, the privacy page and the licences (`PLAN.md` §12, 2026-10-31,
"Demo mode inside the release APK", "In-app help and privacy", "Demo mode in the release
APK confirmed"). Code: `app/lib/core/config/app_config.dart` and `app_mode_store.dart`,
`app/lib/core/api/server_address.dart`, `app/lib/features/onboarding/`,
`app/lib/features/auth/application/server_check.dart` and
`presentation/server_field.dart`, `app/lib/features/help/`, `PRIVACY.md`.

## The app mode

`AppConfig.mode` is `AppMode.demo`, `AppMode.live` or null (not chosen). The `Flavor`
stays what it is; the mode says how the app runs.

- **The demo flavor** is always `demo` and reads nothing from the device; its household
  is `FT_DEMO_PERSONA`'s (`data.md`, **The demo seed**).
- **Dev and prod** are built `live` (`AppConfig.dev()`, `AppConfig.prod()`, which every
  test that builds them gets), and `startApp` replaces that with what the device stores
  (`AppConfig.withChoices`, `AppConfig.choosesMode` then true): the mode, the demo's
  household (`demoPersona`) and the server URL entered at sign-in (`enteredServerUrl`).
- **The store** (`AppModeStore`, `core/config/app_mode_store.dart`) keeps `app_mode`
  (`demo` or `live`), `demo_persona` (the persona's slug) and `server_url` in the
  shared preferences beside the wipe's `wipe_pending_v1`, outside the database, so they
  are read before anything local opens. `PreferencesAppModeStore` on the device
  (`deviceAppModeStore()`, which also reads the install's user from secure storage),
  `InMemoryAppModeStore` in the tests and the demo flavor (`appModeStoreProvider`).
- **An install built before the mode existed** has no `app_mode` but holds an account
  (`install_user_v1` is recorded): it resolves to `live` and the store writes it, so it
  never lands on Welcome. A marker that cannot be read counts as an account, since
  Welcome's demo ends in a wipe.
- **Reading it.** `bootstrap` gives `startApp` the device's store (not in the demo
  flavor), and `startApp` reads it at every start: the first, the restart after a Welcome
  choice, and the restart after a wipe, so leaving the demo starts on "not chosen". A
  store that cannot be read is logged by type and leaves the configuration as built. A
  `startApp` without `modes` (the tests, the integration tests that start a flavor
  directly) takes its configuration as it is. The background worker resolves its
  configuration the same way (`background.md`).

**The wiring per mode** (`overridesFor`, `app-core.md`, **Dependency injection**):

| Mode | Local data | API | Pickers |
|---|---|---|---|
| `live` | Drift over the encrypted database, the change log, WorkManager | the network at the `ServerAddress` | the system's dialogs |
| `demo` | the demo flavor's exactly: the demo repositories over the persona's seed, `NoChangeRecorder`, the fake image source | the in-process fake server, signed in as the demo user | the demo's CSV picker, the fakes |
| not chosen | the in-memory defaults: nothing written to the device | the network (nothing is asked) | the system's dialogs |

In dev and prod every mode also gets the device's store and `DriftLocalWipe` (its
pending record in the preferences), so leaving the demo is finished after a cut too and
clears the stored mode; the demo flavor keeps `InMemoryLocalWipe`. Those two are the
only providers in which prod's demo mode is wired differently from the demo flavor, which
`test/core/di/demo_mode_wiring_test.dart` checks provider by provider. The checks that
meant "the demo" (no session gate, no sync, no database at `stopApp`, the snapshot writer,
the widgets, the export's note, the Account and Backup rows) ask `config.isDemo`; the
checks about the build (logging, HTTPS, the dev request log, the plain database, the
pseudo-locale, the flavor banner) still ask the flavor; and the screenshot-blocking
default asks both, on only in prod's live mode (`lock.md`: the flavor is the build's
part, the mode the data's; the user's own setting still wins).
The demo's receipt photo (`assets/demo/receipt.jpg`) ships in every flavor.

## Welcome

`/welcome` (`welcome_screen.dart`): the brand's mark over the wordmark of the app's name
(`AppConfig.appName`; `BrandMark` and `Wordmark`, `design.md`, **The mark and the
wordmark**), one sentence, "Try the demo" as a `FilledButton` and "Use my own server" as
an `OutlinedButton`. The router holds every location at `/welcome`
or `/welcome/demo` while no mode is chosen, and sends both to where `/` goes once one is
(`app-core.md`, **Routing and the shell**).

- **Try the demo** opens `/welcome/demo` (`demo_persona_screen.dart`): the persona
  engine's four households, each a `BrandCard` (dimmed and read as disabled while a choice
  is being stored), with the lines Settings → Demo data shows
  (`demoPersonaName`, `demoPersonaDetail`). Choosing one stores it and `demo`, then
  calls `appModeRestartProvider`.
- **Use my own server** stores `live` and restarts the same way, onto sign-in.
- **The mode restart** (`startApp` supplies it, as it supplies the restore's and the
  wipe's): the plain starting screen (`starting_app.dart`), two frames, `stopApp()`, then
  `startApp` again, which reads the new mode. A store that refuses the choice
  (`mode_choice.dart`) leaves the screen usable and says so, its failure logged by type.

## The demo strip and leaving

While the demo runs in dev or prod (`isDemo` and not the demo flavor), `DemoStrip`
(`demo_strip.dart`) sits above `AppShell` at every size class: one line, "Demo data"
with a Leave button, in ink on the brand's pink (`design.md`, **Strips**), laid out
between the status bar and the shell as the flavor banner
is. Both are in the semantics tree, read before the screen; the shell under it is a
semantics container of its own, since a branch route's modal barrier blocks the semantics
painted before it up to the nearest container. The demo flavor draws no strip (its DEMO
banner marks it) and offers no way out.

**Leaving** (`leave_demo.dart`): the strip's Leave and Settings → Demo data → "Leave
the demo" ask first, then run the local wipe for `WipeReason.demoLeft` (`data.md`,
**The local wipe**): the erasing screen says the demo is being left, the wipe runs in
its order (its last step clears the stored mode, household and server URL), and the app
starts again at once on Welcome, with no confirmation to dismiss. A household chosen in
Settings → Demo data is stored too, for the next start.

## The server URL

`ServerAddress` (`core/api/server_address.dart`, `serverAddressProvider`) is the compiled
URL (`AppConfig.serverBaseUrl`, `FT_SERVER_URL`) or else the entered one; the network
client reads it for every request (`app-core.md`, **The API client**), so an address
entered while the app runs needs no new client. Over the in-app fake server it is the
fake's, fixed.

- **The field.** While the address is editable (no compiled URL, not the fake), the
  sign-in and registration screens show a Server field first (`server_field.dart`),
  holding the address entered before. `checkServerUrl` takes an absolute `http` or
  `https` URL with a host and no spaces, user, query or fragment; prod takes `https`
  only. A compiled URL wins and hides the field.
- **The check.** On submit, an address other than the one already kept is checked with
  `GET /v1/health` on a client of its own (`ServerCheck`, `serverCheckProvider`):
  `ok` keeps it (`server_url`) and makes it the address, then the sign-in or
  registration runs; `unreachable` (no answer) and `notAServer` (any other answer) are
  shown under the field and nothing else is sent.
- **Settings → Account** shows the server in dev (its compiled one) and in any flavor
  when it was entered.
- **The way back.** On an install whose live mode was chosen on Welcome and that holds
  no account yet, sign-in offers "Try the demo instead": the stored choices are cleared
  and the app restarts on Welcome.

## Help

`features/help/`: `HelpSection` (`domain/help_section.dart`, each with its slug), the
prose in the ARB (one message per heading, paragraph or bullet, each described), laid
out by `HelpHeading`, `HelpParagraph` and `HelpBullets` (`help_widgets.dart`, no Markdown
dependency) from `help_content.dart`.

- `/settings/help` (`help_screen.dart`, from Settings → About → Help) lists the eleven
  sections; `/settings/help/<slug>` (`help_section_screen.dart`) shows one; a slug no
  section has shows the list.
- Each tab's app bar carries a "More options" menu with Help (`HelpMenuButton`,
  `help_menu.dart`): Accounts opens `accounts`; the Plan scaffold opens `budgets`,
  `bills` or `forecast` by segment; the Insights scaffold opens `insights`; the
  transaction list's own menu carries the same item (`transactions`). Each opens its
  section through `openDetail`, on top of the current tab.
- The text is written from the reference files: each section under about two hundred
  words, no amounts, nothing the app does not do (a test counts the words).

## Privacy and About

`/settings/privacy` (`privacy_screen.dart`, from Settings → About): what leaves the
device in the live mode (changes and settings and the device's model name to the
user's server, receipt photos stored there, bank data pulled by that server from Plaid,
Plaid Link talking to Plaid directly, merchant logos loaded from Plaid's addresses), what
never does, and the demo, which sends nothing. Its blocks are `privacy<N>` messages in
the ARB (`privacy_content.dart`); `PRIVACY.md` at the repository's root carries the same
text as Markdown, and `test/features/help/privacy_parity_test.dart` keeps them equal.
`test/features/help/about_test.dart` checks that no demo household carries an address
off the device.

Settings → About also opens Flutter's licence page (`showLicensePage`, under the app's
name and version), with the bundled Roboto fonts' Apache-2.0 licence
(`assets/fonts/LICENSE.txt`) registered by `bootstrap` (`registerBundledLicenses`).

## Tests

| Test | What it proves |
|---|---|
| `test/core/config/app_mode_store_test.dart` | the store's round trip and clear, an install with an account (or an unreadable marker) resolving to live, unknown values, the configuration's choices, the demo flavor untouched |
| `test/core/di/demo_mode_wiring_test.dart` | prod's demo mode overrides what the demo flavor does and reads the same implementations, but for the wipe and the store; the stored household; no database before a mode is chosen |
| `test/bootstrap_mode_test.dart`, `test/bootstrap_leave_demo_test.dart`, `test/bootstrap_resume_leave_demo_test.dart` | prod's demo mode running the demo launch smoke; Welcome → demo → household and Welcome → own server through real restarts; leaving the demo through the wipe back to Welcome; a leave cut short (its pending record and the demo mode in the preferences) finished at the next start, before anything opens, landing on Welcome; a pending wipe found with no mode chosen (its last step had cleared the mode) still finished through the preferences, confirmed, then Welcome (`test/bootstrap_resume_unset_wipe_test.dart`) |
| `test/core/router/auth_redirect_test.dart` | the Welcome hold and its routes once a mode is chosen |
| `test/features/onboarding/` | Welcome and its choices, and a store that refuses one (`welcome_test.dart`), its goldens, the strip and leaving in every way and size (`demo_strip_test.dart`) |
| `test/core/api/server_address_test.dart`, `test/core/api/api_config_test.dart`, `test/features/auth/application/server_check_test.dart`, `test/features/auth/server_field_test.dart` | the URL rule, the per-request address, the health check's outcomes, the field on both screens with every failure and the kept address, Settings' row, "Try the demo instead" |
| `test/features/help/` | the help from Settings and from each tab's menu, the word count, the golden, the privacy parity, About's rows and the licence registration |
| `test/accessibility_test.dart` | Welcome, the households, the strip and its dialog, the auth screens with the field, Help and Privacy at text scales 1 and 2 in both themes and in the pseudo-locale |
| `integration_test/onboarding_test.dart`, `integration_test/app_launch_test.dart` | on the emulator: prod's Welcome → demo → renter → Accounts with the strip → Leave → Welcome on the device's store; the demo smoke under prod's demo mode |
