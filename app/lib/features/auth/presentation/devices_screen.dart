/// Devices (`/settings/devices`): every device signed in to the account
/// (`devices_controller.dart`) with its name, when it last synced ("Last seen", in the
/// device's zone) and this one marked; each with a menu to Remove it after a
/// confirmation (this device then signs out here, its data kept); "Sign out everywhere
/// else" for the others, reporting what it could not do; pull to refresh.
library;

import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/date_time_format.dart';
import 'package:finance_tracker/features/auth/application/devices_controller.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// The devices screen.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Device>> devices = ref.watch(
      devicesControllerProvider,
    );
    final String? current = ref.watch(syncDeviceIdProvider);
    final DevicesController controller = ref.read(
      devicesControllerProvider.notifier,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.devicesTitle)),
      body: switch (devices) {
        AsyncValue(:final List<Device> value) => RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              for (final Device device in value)
                _DeviceTile(device: device, current: device.id == current),
              if (value.any((d) => d.id != current))
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.devices_other),
                    label: Text(l10n.devicesSignOutOthers),
                    onPressed: () => _signOutOthers(context, controller),
                  ),
                ),
            ],
          ),
        ),
        AsyncValue(hasError: true) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.devicesLoadFailed, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: controller.refresh,
                  child: Text(l10n.devicesRetry),
                ),
              ],
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Future<void> _signOutOthers(
    BuildContext context,
    DevicesController controller,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool confirmed = await _confirm(
      context,
      title: l10n.devicesSignOutOthersTitle,
      body: l10n.devicesSignOutOthersBody,
      action: l10n.devicesSignOutOthers,
    );
    if (!confirmed) return;
    final OthersRemoved result = await controller.removeOthers();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.failed > 0
                ? l10n.devicesSignOutOthersFailed(result.failed)
                : l10n.devicesSignOutOthersDone(result.removed),
          ),
        ),
      );
  }
}

class _DeviceTile extends ConsumerWidget {
  const _DeviceTile({required this.device, required this.current});

  final Device device;
  final bool current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DateTime? lastSyncAt = device.lastSyncAt;
    final String seen = lastSyncAt == null
        ? l10n.devicesNeverSynced
        : l10n.devicesLastSeen(
            formatDateTime(lastSyncAt, ref.watch(clockProvider).location),
          );
    return ListTile(
      leading: Icon(current ? Icons.smartphone : Icons.devices_outlined),
      title: Text(device.name),
      subtitle: Text(current ? '${l10n.devicesThisDevice} · $seen' : seen),
      trailing: PopupMenuButton<void>(
        tooltip: l10n.devicesActions(device.name),
        itemBuilder: (_) => [
          PopupMenuItem<void>(
            onTap: () => _remove(context, ref),
            child: Text(l10n.devicesRemove),
          ),
        ],
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final DevicesController controller = ref.read(
      devicesControllerProvider.notifier,
    );
    final bool confirmed = await _confirm(
      context,
      title: current
          ? l10n.devicesRemoveThisTitle
          : l10n.devicesRemoveTitle(device.name),
      body: current ? l10n.devicesRemoveThisBody : l10n.devicesRemoveBody,
      action: l10n.devicesRemove,
    );
    if (!confirmed) return;
    try {
      // Removing this device signs out: the router leaves this screen.
      await controller.remove(device);
    } on ApiException {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.devicesRemoveFailed(device.name))),
        );
    }
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
