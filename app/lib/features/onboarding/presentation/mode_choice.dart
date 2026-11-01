/// Storing a choice of app mode and restarting on it (`docs/reference/onboarding.md`):
/// what the Welcome screen, the demo's households and the sign-in screen's "Try the demo
/// instead" share. A store that refuses leaves the screen as it was, says so, and logs
/// the failure's type only.
library;

import 'package:finance_tracker/core/config/app_mode_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('app');

/// Runs [store] on the device's app mode store, then the mode restart; returns false,
/// having shown why, when the store refused.
Future<bool> storeChoiceAndRestart(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function(AppModeStore modes) store,
) async {
  // Read before the awaits: the restart replaces this app.
  final AppModeStore modes = ref.read(appModeStoreProvider);
  final Future<void> Function() restart = ref.read(appModeRestartProvider);
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  final String failed = AppLocalizations.of(context).modeChoiceFailed;
  try {
    await store(modes);
  } on Object catch (e) {
    _log.warning('the app mode was not stored: ${e.runtimeType}');
    messenger?.showSnackBar(SnackBar(content: Text(failed)));
    return false;
  }
  await restart();
  return true;
}
