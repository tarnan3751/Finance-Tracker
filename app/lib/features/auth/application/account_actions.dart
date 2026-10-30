/// Deleting the account and erasing this device (`docs/reference/auth.md`, **Deleting
/// the account**): what the Settings screens run, kept out of the widgets because the
/// app is stopped under them once the wipe starts.
///
/// - **Delete account**: `DELETE /me`, which answers 204 only once every Plaid Item is
///   removed, every server row deleted and every session revoked; nothing local is
///   touched before that answer, so a failure (a 502 `plaid_error`, no network, anything
///   else) throws with the local data in place. On the 204 the local wipe runs
///   (`core/db/local_wipe.dart`).
/// - **Erase this device**: logout on the server, best effort, then the local wipe; the
///   account stays.
library;

import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_actions.g.dart';

/// The account's actions.
@riverpod
AccountActions accountActions(Ref ref) => AccountActions(
  api: ref.watch(financeApiProvider),
  wipe: ref.watch(wipeLocalDataProvider),
  logOutOnServer: ref.read(sessionControllerProvider.notifier).logOutOnServer,
);

/// Deletes the account or erases this device. Everything it uses is taken when it is
/// made, so an action finishes after its screen has gone.
final class AccountActions {
  /// The actions over [api], [wipe] and [logOutOnServer].
  const AccountActions({
    required this.api,
    required this.wipe,
    required this.logOutOnServer,
  });

  final FinanceApi api;
  final WipeLocalData wipe;
  final Future<void> Function() logOutOnServer;

  /// Deletes the account on the server, then wipes this device. Throws the server's
  /// `ApiException` with nothing local changed when the deletion fails.
  Future<void> deleteAccount() async {
    await api.deleteMe();
    await wipe(WipeReason.accountDeleted);
  }

  /// Signs this device out and wipes it; the account stays.
  Future<void> eraseDevice() async {
    await logOutOnServer();
    await wipe(WipeReason.deviceErased);
  }
}
