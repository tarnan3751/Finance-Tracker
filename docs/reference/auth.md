# Auth

Signing in, registering and signing out, the session the app keeps, the gate in front
of the shell, deleting the account and erasing this device, and the account's devices.
Code: `app/lib/features/auth/` (`domain/`, `application/`, `presentation/`); the token
store and the client that refreshes tokens are in `app/lib/core/api/` (`app-core.md`,
**The API client**). Tests: `app/test/features/auth/`,
`app/test/core/router/auth_redirect_test.dart`, `app/integration_test/auth_flow_test.dart`,
`app/integration_test/account_deletion_test.dart`. The server's rules are `server.md`,
**Tokens** and **Users and devices**.

## The session

`SessionState` (`domain/session_state.dart`) is `SessionUnknown` (the stored session is
still being read), `SignedOut`, or `SignedIn(User, Device)`, this installation's device.
`sessionControllerProvider` (`application/session_controller.dart`, keep-alive) holds it.

| Transition | When |
|---|---|
| unknown to signed in or out | **Restore**, at startup: the token store's session, or none. `bootstrap` waits for it (`restored()`) before the first frame, so the router never shows sign-in to a signed-in user. |
| signed out to signed in | `signIn(email, password)`, `register(email, password, displayName?)` |
| signed in to signed out | `signOut()`; `endLocally()` after this device removed itself (**Devices**); or the client ending the session (`FinanceApi.sessionEnded`) |

- **Restore.** A stored session is signed in at once, from its stored user and device,
  so the app opens offline; if the store throws, startup still finishes, signed out, with
  the error's type logged. `GET /me` then runs in the background: its user is written
  into the latest stored session (`TokenStore.update`, so a refresh that landed meanwhile
  is kept); a 401 (after the client's own refresh) clears the session and signs out, but
  only while the store still holds that session's device: a 401 that arrives after the
  user signed in again leaves the newer session alone. Any other failure (offline, a 5xx)
  keeps the session.
- **Sign-in and registration.** The call, then `GET /me` with the new access token (the
  token pair carries the device, not the user); only then is the session stored. If
  `GET /me` fails, the new device is logged out best-effort and the error rethrown. The
  access token's expiry is the device clock's now plus `access_expires_in`.
- **Sign-out.** `POST /auth/logout` best-effort, then the session is cleared whatever the
  answer. Logout is never refreshed by the client (its body is the refresh token a refresh
  would revoke), so on `token_expired` the controller refreshes once through `GET /me` and
  logs out with the new token. The local data stays: sign-out is not account deletion.
  It has two halves: `logOutOnServer()` calls logout and changes nothing here, and
  `signOut()` (Settings' Sign out) runs it and then clears the session and signs out.
  The erase calls `logOutOnServer()` alone; its wipe clears the session with the app
  stopped (**Deleting the account and erasing this device**).
- **A session the server ends.** When a request is answered `token_revoked`, or a refresh
  is refused, the client clears the stored session and fires `sessionEnded`; the
  controller signs out and the router shows sign-in. That, and the restore's 401, leave
  a notice the sign-in screen takes once (`takeRemoteSignOutNotice()`): "This device was
  signed out remotely", the local data kept (one user per install still holds). A new
  sign-in drops a notice not yet shown; a sign-out here, or `endLocally()`, never leaves
  one, even when the sign-out's logout has its refresh refused and the client ends the
  session meanwhile. A session the background sync found ended (its own client cleared
  it) is recorded in `app_meta` (`session_ended_in_background`); the next start turns it
  into the same notice (`noteEndedRemotely()`) and posts it on `sync_problems` from the
  worker (`background.md`).
- **The device name** (`application/device_name.dart`) is the Android model from
  `device_info_plus`, at most 100 characters, or "Android device"; it is data sent to
  the server, not localized.

## One user per install

`PLAN.md` §6.6: the database, its key and the session belong to one account. The first
account to sign in or register is recorded as the install's user (`TokenStore`
`installUserId`, `install_user_v1` in secure storage), which survives sign-out.

- **Registration** is refused before any network call once an install user is recorded:
  it would always create another account.
- **The marker is read before any network call**, by registration and sign-in alike. A
  marker that cannot be read is an error that propagates (the screens show their generic
  failure), never "no install user", so it can neither let a registration through nor be
  overwritten.
- **A sign-in that yields another user** is logged out best-effort and refused, and
  nothing is stored.

Both throw `OtherAccountOnDeviceException`, which the screens show as "This device
already holds another account's data. Sign in with that account, or erase this device's
data to start over." Without this, sync would push one account's local data into
another's. The local wipe (account deletion, or erasing the device) is the way out: it
clears the marker last, once the data is gone.

## The token store

`core/api/token_store.dart`. `TokenStore` reads, writes and clears the `Session`, updates
it atomically, and reads and writes the install's user. `write`, `clear` and
`update(change)` run one after another; `update` applies `change` to the latest session
with no other change landing between its read and its write (returning the same
session leaves the store untouched, null clears it). The client's refreshed tokens, its
compare-and-clear and the restore's user write all go through `update`.

- **`Session`**: the access and refresh tokens, `accessExpiresAt` (UTC), the `User` as
  `GET /me` last returned it and the `Device`. Its `toString` names only the ids.
- **`SecureTokenStore`** keeps it in `flutter_secure_storage` with the database key's
  options (`resetOnError: false`, the `finance_tracker` namespace) as one JSON value under
  `session_v1`: `{access_token, refresh_token, access_expires_at, user, device}`, the user
  and the device as `shared_models` writes them. It caches the value after the first read;
  `reload()` reads it again from storage, which the client does before every refresh, so
  a session the background sync's isolate refreshed is reused rather than refreshed again
  with its spent refresh token (the server's reuse detection would end it). A storage
  failure during `reload()` keeps the copy in memory (the type logged); only a value that
  cannot be parsed is deleted.
  A value that cannot be read (a storage failure such as a decryption error, or any
  failure to parse it) is deleted and read as signed out; only the error's type is
  logged. A failure to read the install user is not caught. The database key
  (`db_key_v1`) is never touched.
- **`InMemoryTokenStore`**: tests, the demo flavor, and the dev flavor on the fake server.

## The gate

`core/router/app_router.dart`. In dev and prod the router follows the session through
`refreshListenable`:

| Session | On `/sign-in` or `/register` | Anywhere else |
|---|---|---|
| unknown | stays | stays (`/` goes to `/accounts`) |
| signed out | stays | `/sign-in` |
| signed in | `/accounts` | stays (`/` goes to `/accounts`) |
| signed in, the restore offer pending | `/restore` | `/restore` |

The restore offer is pending on a signed-in install whose database is empty until it is
answered (`backup.md`, **Restore**), so the first sign-in or registration of a new
install lands on `/restore` first. The demo flavor has no gate: it is always the demo
user, signed in by its fake server.

## Screens

`presentation/`. Both screens sit outside the shell and share `auth_form.dart`: the
field rules, the password field with its show and hide button, the inline error and the
submit button with its progress indicator.

- **Sign-in** (`sign_in_screen.dart`, `/sign-in`): email, password, Sign in, and "Create
  an account"; after a remote sign-out, its notice, once. While the install's user is
  recorded (the install still holds an account's data; `installUserProvider`), a line of
  its own under the form: "Erase this device's data" (the erase's confirmation and
  wipe). It is the way out for an install whose account is gone, deleted from another
  device or by a deletion whose 204 was lost and whose retry then found the session
  revoked, where sign-in can only answer wrong credentials.
- **Registration** (`register_screen.dart`, `/register`): email, a password of 8 to 128
  characters (counted as the server counts, in characters), an optional name of at most
  100, the device name it registers under, Create account, and a link back to sign-in; beside the another-account refusal, "Erase this device's data".
- **Validation** runs before anything is sent. A `validation_failed` answer marks the
  fields the server named, with the screen's own text.
- **Failures** are shown inline, in an error-coloured live region: wrong credentials, an
  email that has an account, too many attempts (with the server's `Retry-After` when it
  gave one), no server, another account on this install, and anything else.
- A successful submission navigates nowhere itself: the router follows the session.

**Settings** (`account_section.dart`): "Signed in as <email>" with the display name,
Linked banks (`items.md`); outside demo, Devices, Sign out, Sign out and erase this
device, and Delete account; and in dev the server the app talks to ("In-app fake server"
under `FT_FAKE_SERVER`).

## Deleting the account and erasing this device

`application/account_actions.dart`, `presentation/delete_account_screen.dart`,
`presentation/erase_device_dialog.dart`; the wipe is `data.md`, **The local wipe**, run
through `wipeLocalDataProvider` with the app stopped (`app-core.md`, **Startup**). Not in
the demo flavor, which has no account to leave.

- **Delete account** (`/settings/delete-account`) says what happens (every linked bank
  disconnected at Plaid, every server record deleted, this device wiped, the other
  devices signed out) and enables its button only once the account's email is typed
  (trimmed, in any case). Then `DELETE /me`, which answers 204 only when all of that is
  done on the server (`server.md`). Nothing local is touched before that answer: a 502
  `plaid_error`, a lost connection or any other failure shows "Your account was not
  deleted." with the reason, inline, and the button stays to try again. On the 204 the
  wipe runs; its confirmation, "Your account and this device's data were deleted",
  shows only once the wipe finished, and Done starts the app again at sign-in on a fresh
  database under a new key.
- **Sign out and erase this device** asks first, saying that changes not yet synced
  (with the sync ledger's count when it is known) and receipt photos are lost and that
  the rest comes back at the next sign-in; then logout on the server, best effort, and
  the wipe, confirmed with "This device's data was erased". The account stays.
- `AccountActions` takes the API and the wipe when it is made, so an action finishes
  whatever happens to its screen (a sync answered `token_revoked` during the deletion
  can send the router to sign-in for a moment before the erasing screen replaces the
  app).

## Devices

`application/devices_controller.dart`, `presentation/devices_screen.dart`
(`/settings/devices`): the devices signed in to the account, from `GET /devices` in the
server's order, each with its name and "Last seen" (`last_sync_at` in the device's zone,
or "Not synced yet"); this one is marked by comparing ids with `syncDeviceIdProvider`
(the signed-in session's device). Pull to refresh; an error state with Try again.

- **Remove** (each device's menu, after a confirmation): `DELETE /devices/{id}`, which
  revokes that device's tokens at once. A refusal is reported and the list kept; a
  device the server has already removed (404) counts as removed, this one included.
  Removing this device signs out here through `endLocally()`: the stored session
  cleared with no logout call (the tokens are already revoked) and no remote notice;
  the local data stays.
- **Sign out everywhere else** (after a confirmation) removes the others one by one,
  goes on past a failure and reports how many could not be signed out; a device already
  gone (404) counts as removed.
- A list that answers after the screen has gone sets nothing.

## Tests

| Test | What it proves |
|---|---|
| `test/features/auth/session_controller_test.dart` | restore (nothing stored, signed in at once then confirmed, a session the server ended, a 401 for the restored session after a newer sign-in, a store that throws, offline), sign-in, wrong credentials, registration, one user per install both ways, an install user that cannot be read, sign-out (with an expired access token, offline), a revoked session; the remote notice (a revocation and the restore's 401 leave it, taken once; sign-out and `endLocally()` leave none and call nothing; a new sign-in drops it) |
| `test/features/auth/account_deletion_test.dart` | the tiles outside demo only, the typed confirmation, a 204 handing over to the wipe, a 502, a lost connection and a 500 each saying why with nothing local changed and a retry working, the erase asking first then logging out and wiping, the erase confirmation's pending count (the outbox's when signed out after a restart), text scale 2.0 |
| `test/features/auth/devices_test.dart` | the list with this device marked and last seen, pull to refresh, removing another device and a refusal, sign out everywhere else past a failure, removing this device (signed out, no notice, data kept; also when the server answers 404), the error state, a refresh answering after the screen has gone; the sign-in notice once; the erase offer on the sign-in screen whenever the install's user is recorded (none on a fresh install) and beside registration's another-account refusal |
| `test/bootstrap_wipe_test.dart`, `test/bootstrap_resume_wipe_test.dart`, `test/bootstrap_resume_wipe_dev_test.dart`, `test/core/db/local_wipe_test.dart` | the wipe under `startApp` (erasing screen, a failure and Try again, the confirmation, Done starting a new container signed out, a double tap counting once, the repeated failure's pointer at Android's storage settings); a start finishing a pending wipe before anything opens, the dev flavor's database never built first; the wipe's files, keys, order, pending record and idempotence, a cut at each step leaving exactly the later steps and the next run finishing it, and the next open a fresh database under a new key (`data.md`) |
| `test/features/auth/auth_screens_test.dart` | the gate to sign-in and into the shell, each failure's text, validation before sending, show and hide, registration, sign-out from Settings, a session the server ends, dev's server row, demo's missing gate and sign-out, text scale 2.0 with errors showing |
| `test/features/auth/auth_screens_golden_test.dart` | both screens, light and dark |
| `test/core/router/auth_redirect_test.dart` | the redirect rules case by case |
| `test/accessibility_test.dart` | the auth screens, Devices and Delete account against the three guidelines, light and dark |
| `integration_test/auth_flow_test.dart` | on the emulator: the demo signed in; under `FT_FAKE_SERVER`, the dev flavor's register, sign out, sign in, a refresh after expiry, and sign out |
| `integration_test/account_deletion_test.dart` | on the emulator, the dev wiring started as `bootstrap` starts it: Devices with this one marked and another removed; Delete account to the confirmation with the database files, receipts, key, session and install user gone; Done at sign-in on a fresh database under a new key; a new account registering |
