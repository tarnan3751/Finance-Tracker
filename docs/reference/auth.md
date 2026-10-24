# Auth

Signing in, registering and signing out, the session the app keeps, and the gate in
front of the shell. Code: `app/lib/features/auth/` (`domain/`, `application/`,
`presentation/`); the token store and the client that refreshes tokens are in
`app/lib/core/api/` (`app-core.md`, **The API client**). Tests:
`app/test/features/auth/`, `app/test/core/router/auth_redirect_test.dart`,
`app/integration_test/auth_flow_test.dart`. The server's rules are `server.md`, **Tokens**.

## The session

`SessionState` (`domain/session_state.dart`) is `SessionUnknown` (the stored session is
still being read), `SignedOut`, or `SignedIn(User, Device)`, this installation's device.
`sessionControllerProvider` (`application/session_controller.dart`, keep-alive) holds it.

| Transition | When |
|---|---|
| unknown to signed in or out | **Restore**, at startup: the token store's session, or none. `bootstrap` waits for it (`restored()`) before the first frame, so the router never shows sign-in to a signed-in user. |
| signed out to signed in | `signIn(email, password)`, `register(email, password, displayName?)` |
| signed in to signed out | `signOut()`, or the client ending the session (`FinanceApi.sessionEnded`) |

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
- **A session the server ends.** When a request is answered `token_revoked`, or a refresh
  is refused, the client clears the stored session and fires `sessionEnded`; the
  controller signs out and the router shows sign-in.
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
already holds another account's data. Sign in with that account, or clear the app's
storage in Android settings to start over." Without this, sync would push one account's
local data into another's. Phase 7's local-data deletion is the other way out.

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
  and the device as `shared_models` writes them. It caches the value after the first read.
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

The demo flavor has no gate: it is always the demo user, signed in by its fake server.

## Screens

`presentation/`. Both screens sit outside the shell and share `auth_form.dart`: the
field rules, the password field with its show and hide button, the inline error and the
submit button with its progress indicator.

- **Sign-in** (`sign_in_screen.dart`, `/sign-in`): email, password, Sign in, and "Create
  an account".
- **Registration** (`register_screen.dart`, `/register`): email, a password of 8 to 128
  characters (counted as the server counts, in characters), an optional name of at most
  100, the device name it registers under, Create account, and a link back to sign-in.
- **Validation** runs before anything is sent. A `validation_failed` answer marks the
  fields the server named, with the screen's own text.
- **Failures** are shown inline, in an error-coloured live region: wrong credentials, an
  email that has an account, too many attempts (with the server's `Retry-After` when it
  gave one), no server, another account on this install, and anything else.
- A successful submission navigates nowhere itself: the router follows the session.

**Settings** (`account_section.dart`): "Signed in as <email>" with the display name,
Sign out (not in demo), and in dev the server the app talks to ("In-app fake server"
under `FT_FAKE_SERVER`).

## Tests

| Test | What it proves |
|---|---|
| `test/features/auth/session_controller_test.dart` | restore (nothing stored, signed in at once then confirmed, a session the server ended, a 401 for the restored session after a newer sign-in, a store that throws, offline), sign-in, wrong credentials, registration, one user per install both ways, an install user that cannot be read, sign-out (with an expired access token, offline), a revoked session |
| `test/features/auth/auth_screens_test.dart` | the gate to sign-in and into the shell, each failure's text, validation before sending, show and hide, registration, sign-out from Settings, a session the server ends, dev's server row, demo's missing gate and sign-out, text scale 2.0 with errors showing |
| `test/features/auth/auth_screens_golden_test.dart` | both screens, light and dark |
| `test/core/router/auth_redirect_test.dart` | the redirect rules case by case |
| `test/accessibility_test.dart` | both screens against the three guidelines, light and dark |
| `integration_test/auth_flow_test.dart` | on the emulator: the demo signed in; under `FT_FAKE_SERVER`, the dev flavor's register, sign out, sign in, a refresh after expiry, and sign out |
