/// Restoring a backup (`docs/reference/backup.md`, **Restore**): the "Restore from a
/// backup" button and what follows it, the same from Settings → Backup, the fresh
/// install's offer (`/restore`) and the screen of a lost database key.
///
/// 1. On an install that already has data (`hasLocalData`), refused before anything
///    else ("Delete the app's data first"); the lost-key screen has no data it can read.
/// 2. The file, from the backup picker, refused unread when it is over 512 MiB or its
///    header is not a backup's this build opens; then its passphrase.
/// 3. The file opened and checked whole in an isolate (`openBackupFile`), its progress
///    shown; then the account: the signed-in user's, or on the lost-key screen the
///    install's recorded user, or when none is recorded the stored session's.
/// 4. A confirmation with the backup's date, app version and counts; on the lost-key
///    screen, that the unreadable data will be deleted.
/// 5. The app restarts around the restore (`appRestartProvider`): the database files
///    deleted, a new key, the import; on the lost-key screen the backup's user becomes
///    the install's when none was recorded, so another account cannot sign in onto it.
///
/// A failure before the restart is shown under the button and nothing has changed.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/backup_picker.dart';
import 'package:finance_tracker/core/platform/backup_picker_provider.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/features/backup/application/backup_providers.dart';
import 'package:finance_tracker/features/backup/application/backup_service.dart';
import 'package:finance_tracker/features/backup/application/backup_worker.dart';
import 'package:finance_tracker/features/backup/data/database_dump.dart';
import 'package:finance_tracker/features/backup/domain/backup_format.dart';
import 'package:finance_tracker/features/backup/domain/backup_manifest.dart';
import 'package:finance_tracker/features/backup/presentation/backup_messages.dart';
import 'package:finance_tracker/features/lock/application/lock_hold.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('backup');

/// Where a restore starts from.
enum RestoreEntry {
  /// Settings → Backup.
  settings,

  /// The fresh install's offer.
  offer,

  /// The screen shown when the database key is lost.
  keyLost,
}

/// The restore button, its progress and its failure.
class RestoreFlow extends ConsumerStatefulWidget {
  const RestoreFlow({required this.entry, this.onBusyChanged, super.key});

  /// Where the restore starts from.
  final RestoreEntry entry;

  /// Told when the flow starts and stops working, so the screen can hold its other
  /// actions meanwhile.
  final ValueChanged<bool>? onBusyChanged;

  @override
  ConsumerState<RestoreFlow> createState() => _RestoreFlowState();
}

class _RestoreFlowState extends ConsumerState<RestoreFlow> {
  bool _busy = false;
  BackupProgress? _progress;
  String? _error;

  bool get _keyLost => widget.entry == RestoreEntry.keyLost;

  Future<void> _refuseIfData(AppDatabase? database) async {
    if (database != null && await hasLocalData(database)) {
      throw const InstallHasDataException();
    }
  }

  // The user the backup must belong to, null when none is known: the signed-in one, or
  // on the lost-key screen the install's when it can be read, else the stored
  // session's (its account would otherwise receive the backup's outbox at the next sync).
  // [marker] says whether the expected user is the install's recorded one.
  Future<({String? user, bool marker})> _expectedUser(
    String? signedIn,
    TokenStore tokens,
  ) async {
    if (!_keyLost) return (user: signedIn, marker: false);
    try {
      final String? marker = await tokens.readInstallUserId();
      if (marker != null) return (user: marker, marker: true);
    } on Object catch (e) {
      // An unreadable marker on the lost-key screen: secure storage lost it with the key.
      _log.warning('the install user could not be read: ${e.runtimeType}');
    }
    try {
      return (user: (await tokens.read())?.user.id, marker: false);
    } on Object catch (e) {
      _log.warning('the session could not be read: ${e.runtimeType}');
      return (user: null, marker: false);
    }
  }

  // The chosen file's bytes, null when none was chosen: refused unread when it is over
  // [maxBackupBytes] or its header is not a backup's this build opens.
  Future<Uint8List?> _readPicked(BackupPicker picker, LockHold hold) async {
    // The file dialog is an activity of its own: the lock stays open.
    final PickedFile? picked = await hold.holdOpen(picker.pick);
    if (picked == null) return null;
    try {
      if (picked.length > maxBackupBytes) throw const BackupTooLargeException();
      BackupHeader.read(await picked.read(0, backupHeaderLength));
      return await picked.read();
    } finally {
      await picked.close();
    }
  }

  void _setBusy(bool busy) {
    setState(() => _busy = busy);
    widget.onBusyChanged?.call(busy);
  }

  Future<void> _restore() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    _setBusy(true);
    setState(() {
      _error = null;
      _progress = null;
    });
    // Read before the awaits: the flow may be gone when they return. The lost-key
    // screen has no database it can read.
    final AppDatabase? database = _keyLost ? null : ref.read(databaseProvider);
    final BackupPicker picker = ref.read(backupPickerProvider);
    final LockHold hold = ref.read(lockHoldProvider);
    final BackupEnvironment environment = ref.read(backupEnvironmentProvider);
    final TokenStore tokens = ref.read(tokenStoreProvider);
    final DatabaseKeyStore keyStore = ref.read(databaseKeyStoreProvider);
    final AppRestart restart = ref.read(appRestartProvider);
    final String? signedIn = _keyLost
        ? null
        : switch (ref.read(sessionControllerProvider)) {
            SignedIn(:final user) => user.id,
            _ => null,
          };
    final ProgressThrottle throttle = ProgressThrottle();
    try {
      await _refuseIfData(database);
      final Uint8List? file = await _readPicked(picker, hold);
      if (file == null || !mounted) return;
      final String? passphrase = await showDialog<String>(
        context: context,
        builder: (_) => const _PassphraseDialog(),
      );
      if (passphrase == null || !mounted) return;
      final OpenedBackup opened = await openBackupFile(
        environment.runner,
        file,
        passphrase,
        (p) {
          if (mounted && throttle.admit(p)) setState(() => _progress = p);
        },
      );
      final ({String? user, bool marker}) expected = await _expectedUser(
        signedIn,
        tokens,
      );
      checkBackupAccount(opened.manifest, expected.user);
      if (!mounted) return;
      setState(() => _progress = null);
      final bool confirmed =
          await showDialog<bool>(
            context: context,
            builder: (_) =>
                _ConfirmDialog(manifest: opened.manifest, keyLost: _keyLost),
          ) ??
          false;
      if (!confirmed || !mounted) return;
      await _refuseIfData(database);
      final String? owner = opened.manifest.userId;
      // With no recorded user, the backup's becomes the install's, so a later sign-in
      // by another account is refused.
      final bool recordOwner = _keyLost && !expected.marker && owner != null;
      await restart((report) async {
        await replaceDatabase(
          file: file,
          opened: opened,
          directory: await environment.directory(),
          keyStore: keyStore,
          report: report,
          runner: environment.runner,
        );
        if (recordOwner) await tokens.writeInstallUserId(owner);
      });
    } on Object catch (e) {
      _log.warning('the restore was refused: ${e.runtimeType}');
      if (mounted) setState(() => _error = backupErrorMessage(l10n, e));
    } finally {
      if (mounted) {
        _setBusy(false);
        setState(() => _progress = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BackupProgress? progress = _progress;
    final String? error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.settings_backup_restore),
          label: Text(l10n.backupRestoreButton),
          onPressed: _busy ? null : () => unawaited(_restore()),
        ),
        if (progress != null) ...[
          const SizedBox(height: 16),
          BackupProgressView(progress),
        ],
        if (error != null) ...[
          const SizedBox(height: 16),
          BackupErrorText(error),
        ],
      ],
    );
  }
}

/// Asks for the backup's passphrase; pops it, or null on cancel.
class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog();

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final TextEditingController _passphrase = TextEditingController();

  @override
  void dispose() {
    _passphrase.dispose();
    super.dispose();
  }

  void _open() {
    if (_passphrase.text.isEmpty) return;
    Navigator.of(context).pop(_passphrase.text);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.backupRestorePassphraseTitle),
      content: TextField(
        controller: _passphrase,
        autofocus: true,
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        decoration: InputDecoration(labelText: l10n.backupPassphrase),
        onSubmitted: (_) => _open(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _open, child: Text(l10n.backupOpen)),
      ],
    );
  }
}

/// What the backup holds, and the last chance to stop; pops true to restore.
class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.manifest, required this.keyLost});

  final BackupManifest manifest;
  final bool keyLost;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String made = DateFormat.yMMMd().add_jm().format(
      manifest.createdAt.toLocal(),
    );
    return AlertDialog(
      title: Text(l10n.backupConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.backupConfirmBody(
              made,
              manifest.appVersion,
              manifest.rowCount,
              manifest.receipts,
            ),
          ),
          if (keyLost) ...[
            const SizedBox(height: 12),
            Text(l10n.backupConfirmLostKey),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.backupConfirmRestore),
        ),
      ],
    );
  }
}
