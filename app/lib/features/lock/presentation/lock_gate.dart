/// The lock's gate (`docs/reference/lock.md`, **The gate**): `MaterialApp.builder` puts it
/// above the router, so while the app is locked (or covered while a return is decided) the
/// lock screen covers every route, sheet and dialog, and the app below it is kept (its
/// state survives) but hidden from the screen reader, out of focus, and deaf to the back
/// button and the predictive back gesture. The lock screen shows only the app's name and
/// the unlock button (none while merely covered), and after an attempt that did not
/// unlock, why, with "Try again".
library;

import 'dart:async';

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/lock/application/lock_controller.dart';
import 'package:finance_tracker/features/lock/domain/device_auth.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [child] (the app), covered by the lock screen while the app is locked.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

// The gate's observer is registered before the router's back button dispatcher (the gate
// is built above the router), so it sees a back press first and keeps it while locked.
class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async => ref.read(lockControllerProvider).shown;

  @override
  Widget build(BuildContext context) {
    final bool shown = ref.watch(lockControllerProvider.select((s) => s.shown));
    final ThemeData theme = Theme.of(context);
    return Stack(
      children: [
        // While shown, Android pages take a transition that does not claim the predictive
        // back gesture, so no route pops under the lock screen: the gesture's commit falls
        // back to a pop route, which didPopRoute keeps. The Theme is always there, so the
        // app below keeps its state when the data changes.
        Theme(
          data: shown ? _withoutPredictiveBack(theme) : theme,
          child: ExcludeSemantics(
            excluding: shown,
            child: ExcludeFocus(excluding: shown, child: widget.child),
          ),
        ),
        if (shown) const Positioned.fill(child: LockScreen()),
      ],
    );
  }
}

ThemeData _withoutPredictiveBack(ThemeData theme) => theme.copyWith(
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      ...theme.pageTransitionsTheme.builders,
      TargetPlatform.android: const FadeForwardsPageTransitionsBuilder(),
    },
  ),
);

/// The lock screen: while the app is only covered (away, its return not yet decided), the
/// name alone.
class LockScreen extends ConsumerWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final AppLockState lock = ref.watch(lockControllerProvider);
    final AuthOutcome? failure = lock.failure;
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  ref.watch(appConfigProvider).appName,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                if (failure != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      lockFailureMessage(l10n, failure),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (lock.locked) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: lock.authenticating
                        ? null
                        : () => unawaited(
                            ref
                                .read(lockControllerProvider.notifier)
                                .unlock(l10n.lockPromptReason),
                          ),
                    icon: const Icon(Icons.fingerprint),
                    label: Text(
                      failure == null ? l10n.lockUnlock : l10n.lockTryAgain,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Why a prompt with [outcome] did not unlock, in the app's words.
String lockFailureMessage(AppLocalizations l10n, AuthOutcome outcome) =>
    switch (outcome) {
      AuthOutcome.success || AuthOutcome.failed => l10n.lockFailed,
      AuthOutcome.cancelled => l10n.lockCancelled,
      AuthOutcome.noCredentials => l10n.lockNoScreenLock,
      AuthOutcome.lockedOut => l10n.lockLockedOut,
      AuthOutcome.unavailable => l10n.lockUnavailable,
    };
