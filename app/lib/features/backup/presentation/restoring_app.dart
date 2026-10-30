/// What the app shows while a restore runs with the app stopped (`bootstrap`'s
/// restart): a plain screen with the restore's progress and, when it fails, that it did
/// and a Continue button that starts the app on whatever the device now holds.
library;

import 'dart:async';

import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/features/backup/application/backup_worker.dart';
import 'package:finance_tracker/features/backup/presentation/backup_messages.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// A callback that completes [completer] once: a second tap on the button it backs
/// (a double tap reaches the handler twice before the screen changes) does nothing,
/// where `completer.complete` would throw a [StateError].
VoidCallback completeOnce(Completer<void> completer) => () {
  if (!completer.isCompleted) completer.complete();
};

/// The restore's state as the screen shows it: its progress, then a failure if any.
final class RestoringState {
  /// The state.
  const RestoringState({this.progress, this.failure, this.onContinue});

  /// The progress so far, null before the first report.
  final BackupProgress? progress;

  /// What the restore failed with, null while it runs or after it succeeded.
  final Object? failure;

  /// Starts the app after a failure.
  final VoidCallback? onContinue;
}

/// The restoring screen's app, following [state].
class RestoringApp extends StatelessWidget {
  const RestoringApp({required this.state, super.key});

  /// The restore's state.
  final ValueNotifier<RestoringState> state;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ValueListenableBuilder<RestoringState>(
              valueListenable: state,
              builder: (context, value, _) {
                final AppLocalizations l10n = AppLocalizations.of(context);
                final Object? failure = value.failure;
                final BackupProgress? progress = value.progress;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      failure == null
                          ? l10n.backupRestoringTitle
                          : l10n.backupRestoreFailedTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (failure != null) ...[
                      BackupErrorText(l10n.backupRestoreFailedBody),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: value.onContinue,
                        child: Text(l10n.backupContinue),
                      ),
                    ] else
                      BackupProgressView(
                        progress ?? const BackupProgress(BackupStage.restoring),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
