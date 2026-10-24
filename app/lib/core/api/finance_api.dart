/// The app's view of the server: one method per contract operation (`api/openapi.yaml`),
/// taking and returning `shared_models` values, the sync engine's push and pull types, and
/// the small values of `api_models.dart`.
///
/// `HttpFinanceApi` (`http_finance_api.dart`) implements it over the generated client; the
/// demo flavor and the tests run the same implementation against the in-app fake server
/// (`fake/`). Every method throws an `ApiException` (`problems.dart`) on failure. The
/// webhook receiver has no method: the app never receives webhooks. Nothing outside
/// `core/api/` imports the generated client.
library;

import 'package:finance_tracker/core/api/api_models.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

/// The API.
abstract interface class FinanceApi {
  /// Fires when the client ended the session on its own: the server answered
  /// `token_revoked`, or a refresh was refused. The token store is already cleared.
  Stream<void> get sessionEnded;

  // auth: these four return a token pair and never touch the token store; the session
  // controller stores it.

  /// `POST /auth/register`. [displayName] defaults, on the server, to the email's local
  /// part.
  Future<AuthResult> register({
    required String email,
    required String password,
    required String deviceName,
    String? displayName,
  });

  /// `POST /auth/login`.
  Future<AuthResult> login({
    required String email,
    required String password,
    required String deviceName,
  });

  /// `POST /auth/refresh`. The client refreshes on its own; this is for tests and tools.
  Future<AuthResult> refreshTokens(String refreshToken);

  /// `POST /auth/logout` with this device's [refreshToken], authenticated with
  /// [accessToken] when given, else with the stored session. Never refreshed and retried
  /// on `token_expired`, since the body carries the refresh token a refresh revokes.
  Future<void> logout(String refreshToken, {String? accessToken});

  // me and devices

  /// `GET /me`, authenticated with [accessToken] when given (signing in, before a session
  /// is stored; never refreshed), else with the stored session.
  Future<User> getMe({String? accessToken});

  /// `DELETE /me`.
  Future<void> deleteMe();

  /// `GET /devices`.
  Future<List<Device>> listDevices();

  /// `DELETE /devices/{device_id}`.
  Future<void> deleteDevice(String deviceId);

  // plaid

  /// `POST /plaid/link-token`.
  Future<LinkToken> createLinkToken({
    required String androidPackageName,
    String? updateItemId,
  });

  /// `POST /plaid/exchange`.
  Future<LinkedItem> exchangePublicToken(String publicToken);

  /// `GET /plaid/items`.
  Future<List<LinkedItem>> listItems();

  /// `DELETE /plaid/items/{item_id}`.
  Future<void> deleteItem(String itemId);

  /// `POST /plaid/items/{item_id}/sync`. `notReady` means retry shortly, never "no
  /// transactions" (`PLAN.md` §4).
  Future<SyncRun> syncItem(String itemId);

  /// `POST /plaid/items/{item_id}/update-link-token`.
  Future<LinkToken> createUpdateLinkToken(
    String itemId, {
    required String androidPackageName,
  });

  // data

  /// `GET /accounts`.
  Future<List<Account>> listAccounts();

  /// `GET /transactions`; a [since] past the server's version throws `SyncCursorInvalid`.
  Future<VersionPage<Transaction>> listTransactions({
    int since = 0,
    int limit = 500,
  });

  /// `GET /liabilities`.
  Future<Liabilities> getLiabilities();

  /// `GET /investments/holdings`.
  Future<Holdings> listHoldings();

  /// `GET /investments/transactions`, paged like [listTransactions].
  Future<VersionPage<InvestmentTransaction>> listInvestmentTransactions({
    int since = 0,
    int limit = 500,
  });

  /// `GET /recurring`.
  Future<List<RecurringStream>> listRecurringStreams();

  // sync

  /// `POST /sync/push`.
  Future<PushResult> pushChanges(List<ChangeLogEntry> entries);

  /// `GET /sync/pull`; a [since] past the server's last `seq` throws `SyncCursorInvalid`.
  Future<PullPage> pullChanges({required int since, required int limit});

  // health

  /// `GET /health`.
  Future<Health> getHealth();
}
