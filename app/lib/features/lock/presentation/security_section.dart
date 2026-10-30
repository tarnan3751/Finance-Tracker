/// The settings screen's Security section (`docs/reference/lock.md`, **Settings**):
/// "Require unlock", which turns on only after one successful prompt and is disabled, with
/// the reason, on a device with no screen lock (asked again whenever the app returns, so
/// setting one up takes effect); "Lock after", enabled with the lock; and "Block
/// screenshots". All three describe this device and are kept in `app_meta`.
library;

import 'dart:async';

import 'package:finance_tracker/features/lock/application/device_auth_provider.dart';
import 'package:finance_tracker/features/lock/application/lock_controller.dart';
import 'package:finance_tracker/features/lock/domain/device_auth.dart';
import 'package:finance_tracker/features/lock/domain/lock_settings.dart';
import 'package:finance_tracker/features/lock/presentation/lock_gate.dart';
import 'package:finance_tracker/features/settings/presentation/settings_section_header.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Security section.
class SecuritySection extends ConsumerStatefulWidget {
  const SecuritySection({super.key});

  @override
  ConsumerState<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends ConsumerState<SecuritySection> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(deviceAuthSupportedProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _setEnabled(bool on) async {
    final LockController controller = ref.read(lockControllerProvider.notifier);
    if (!on) return controller.disable();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AuthOutcome outcome = await controller.enable(
      l10n.lockEnablePromptReason,
    );
    if (outcome != AuthOutcome.success) {
      messenger.showSnackBar(
        SnackBar(content: Text(lockFailureMessage(l10n, outcome))),
      );
    }
  }

  Future<void> _chooseLockAfter(LockAfter current) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final LockAfter? chosen = await showDialog<LockAfter>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.lockAfterTitle),
        children: [
          RadioGroup<LockAfter>(
            groupValue: current,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final LockAfter choice in LockAfter.values)
                  RadioListTile<LockAfter>(
                    value: choice,
                    title: Text(lockAfterLabel(l10n, choice)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (chosen != null) {
      await ref.read(lockControllerProvider.notifier).setLockAfter(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppLockState lock = ref.watch(lockControllerProvider);
    // Until the device answers, the switch waits rather than offering what may not work.
    final bool supported =
        ref.watch(deviceAuthSupportedProvider).value ?? false;
    final bool canToggle = (supported || lock.enabled) && !lock.authenticating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(l10n.settingsSecurity),
        SwitchListTile(
          title: Text(l10n.lockRequireUnlock),
          subtitle: Text(
            supported || lock.enabled
                ? l10n.lockRequireUnlockSubtitle
                : l10n.lockNoScreenLock,
          ),
          value: lock.enabled,
          onChanged: canToggle ? (on) => unawaited(_setEnabled(on)) : null,
        ),
        ListTile(
          enabled: lock.enabled,
          title: Text(l10n.lockAfterTitle),
          subtitle: Text(lockAfterLabel(l10n, lock.lockAfter)),
          onTap: lock.enabled
              ? () => unawaited(_chooseLockAfter(lock.lockAfter))
              : null,
        ),
        SwitchListTile(
          title: Text(l10n.lockBlockScreenshots),
          subtitle: Text(l10n.lockBlockScreenshotsSubtitle),
          value: lock.secureScreen,
          onChanged: (on) => unawaited(
            ref.read(lockControllerProvider.notifier).setSecureScreen(on: on),
          ),
        ),
      ],
    );
  }
}

/// The "Lock after" choice [choice], as the settings show it.
String lockAfterLabel(AppLocalizations l10n, LockAfter choice) =>
    switch (choice) {
      LockAfter.off => l10n.lockAfterOff,
      LockAfter.immediately => l10n.lockAfterImmediately,
      LockAfter.oneMinute => l10n.lockAfterMinutes(1),
      LockAfter.fiveMinutes => l10n.lockAfterMinutes(5),
      LockAfter.fifteenMinutes => l10n.lockAfterMinutes(15),
    };
