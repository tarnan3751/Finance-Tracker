/// The account's devices (`docs/reference/auth.md`, **Devices**): the list from
/// `GET /devices` (those signed in, in the server's order), this one known by its id
/// (`syncDeviceIdProvider`, the signed-in session's device), and removal through
/// `DELETE /devices/{id}`, which revokes the device's tokens at once. Removing this
/// device signs out here with the local data kept; "Sign out everywhere else" removes
/// the others one by one, going on past a failure and counting it. A device already gone
/// (404) counts as removed, this one included. Nothing is set once the screen has gone.
library;

import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'devices_controller.g.dart';

/// What "Sign out everywhere else" did: how many devices it removed and how many it
/// could not.
typedef OthersRemoved = ({int removed, int failed});

/// The devices signed in to the account.
@riverpod
class DevicesController extends _$DevicesController {
  FinanceApi get _api => ref.read(financeApiProvider);

  @override
  Future<List<Device>> build() => ref.watch(financeApiProvider).listDevices();

  /// Reads the list again; a failure becomes the state's error. Nothing is set once the
  /// screen has gone.
  Future<void> refresh() async {
    final AsyncValue<List<Device>> next = await AsyncValue.guard(
      _api.listDevices,
    );
    if (ref.mounted) state = next;
  }

  /// Removes [device]; one already gone (404) counts as removed. This device signs out
  /// here, with its local data kept; another one leaves the list. Throws the
  /// `ApiException` when the server refuses.
  Future<void> remove(Device device) async {
    final FinanceApi api = _api;
    final bool current = device.id == ref.read(syncDeviceIdProvider);
    final SessionController session = ref.read(
      sessionControllerProvider.notifier,
    );
    try {
      await api.deleteDevice(device.id);
    } on NotFound {
      // Removed elsewhere meanwhile.
    }
    if (current) {
      await session.endLocally();
      return;
    }
    if (ref.mounted) await refresh();
  }

  /// Removes every device but this one, going on past a failure.
  Future<OthersRemoved> removeOthers() async {
    final FinanceApi api = _api;
    final String? current = ref.read(syncDeviceIdProvider);
    final List<Device> devices = state.value ?? await future;
    int removed = 0;
    int failed = 0;
    for (final Device device in devices) {
      if (device.id == current) continue;
      try {
        await api.deleteDevice(device.id);
        removed++;
      } on NotFound {
        // Gone already: signed out elsewhere meanwhile.
        removed++;
      } on ApiException {
        failed++;
      }
    }
    if (ref.mounted) await refresh();
    return (removed: removed, failed: failed);
  }
}
