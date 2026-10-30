/// What the backup screens say: each failure's message, each stage's label, and the
/// progress line shared by the export, the restore and the restoring screen.
library;

import 'package:finance_tracker/core/platform/backup_picker.dart';
import 'package:finance_tracker/features/backup/application/backup_worker.dart';
import 'package:finance_tracker/features/backup/domain/backup_format.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The message for [error], a failure of a restore.
String backupErrorMessage(AppLocalizations l10n, Object error) =>
    switch (error) {
      NotABackupException() => l10n.backupErrorNotABackup,
      BackupTooLargeException() => l10n.backupErrorTooLarge,
      BackupTooNewException() => l10n.backupErrorTooNew,
      UnsafeBackupException() => l10n.backupErrorUnsafe,
      WrongPassphraseException() => l10n.backupErrorWrongPassphrase,
      BackupDamagedException() => l10n.backupErrorDamaged,
      BackupOtherAccountException() => l10n.backupErrorOtherAccount,
      InstallHasDataException() => l10n.backupErrorHasData,
      BackupPickFailedException() => l10n.backupErrorPick,
      _ => l10n.backupErrorFailed,
    };

/// Lets through the progress worth showing: a new stage, the last unit, ten percent more
/// than last shown, or a second since; so a screen reader is not read every 64 KiB frame.
final class ProgressThrottle {
  /// A throttle that has shown nothing yet.
  ProgressThrottle() : _since = Stopwatch()..start();

  final Stopwatch _since;
  BackupProgress? _shown;

  /// Whether [progress] is worth showing; when it is, it becomes the last shown.
  bool admit(BackupProgress progress) {
    final BackupProgress? shown = _shown;
    final double? now = progress.fraction;
    final double? before = shown?.fraction;
    final bool worth =
        shown == null ||
        shown.stage != progress.stage ||
        (progress.total > 0 && progress.done == progress.total) ||
        (now != null && before != null && now - before >= 0.1) ||
        _since.elapsed >= const Duration(seconds: 1);
    if (worth) {
      _shown = progress;
      _since.reset();
    }
    return worth;
  }
}

/// The label of [stage].
String backupStageLabel(AppLocalizations l10n, BackupStage stage) =>
    switch (stage) {
      BackupStage.reading => l10n.backupStageReading,
      BackupStage.deriving => l10n.backupStageDeriving,
      BackupStage.encrypting => l10n.backupStageEncrypting,
      BackupStage.checking => l10n.backupStageChecking,
      BackupStage.restoring => l10n.backupStageRestoring,
    };

/// [progress] as a labelled bar, announced as it changes: determinate (its percentage
/// spoken) when the stage counts its work, indeterminate otherwise.
class BackupProgressView extends StatelessWidget {
  const BackupProgressView(this.progress, {super.key});

  /// The progress shown.
  final BackupProgress progress;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String label = backupStageLabel(l10n, progress.stage);
    final double? fraction = progress.fraction;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: fraction, semanticsLabel: label),
        ],
      ),
    );
  }
}

/// [message] as an error line, announced when it appears.
class BackupErrorText extends StatelessWidget {
  const BackupErrorText(this.message, {super.key});

  /// The error.
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
