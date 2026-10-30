/// The backup screen (`/settings/backup`, `docs/reference/backup.md`, **Screens**):
/// export everything into one file encrypted with a passphrase, saved through the
/// system's "Save as" dialog or shared, and restore one ([RestoreFlow]). The demo flavor
/// has no database to back up, and its Settings entry says so instead of opening this.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/file_exporter.dart';
import 'package:finance_tracker/core/platform/file_exporter_provider.dart';
import 'package:finance_tracker/features/backup/application/backup_providers.dart';
import 'package:finance_tracker/features/backup/application/backup_service.dart';
import 'package:finance_tracker/features/backup/application/backup_worker.dart';
import 'package:finance_tracker/features/backup/domain/passphrase_strength.dart';
import 'package:finance_tracker/features/backup/presentation/backup_messages.dart';
import 'package:finance_tracker/features/backup/presentation/restore_flow.dart';
import 'package:finance_tracker/features/lock/application/lock_hold.dart';
import 'package:finance_tracker/features/settings/presentation/settings_section_header.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('backup');

/// The MIME type a backup is handed over as.
const String backupMimeType = 'application/octet-stream';

/// A backup's file name: `finance-tracker-<local date>.ftbk`.
String backupFileName(String localDate) => 'finance-tracker-$localDate.ftbk';

/// The backup screen.
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SettingsSectionHeader(l10n.backupExportSection),
          const _ExportSection(),
          SettingsSectionHeader(l10n.backupRestoreSection),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(l10n.backupRestoreExplanation),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: RestoreFlow(entry: RestoreEntry.settings),
          ),
        ],
      ),
    );
  }
}

/// The passphrase, its confirmation and strength, Save as and Share, and the progress.
class _ExportSection extends ConsumerStatefulWidget {
  const _ExportSection();

  @override
  ConsumerState<_ExportSection> createState() => _ExportSectionState();
}

class _ExportSectionState extends ConsumerState<_ExportSection> {
  final TextEditingController _passphrase = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _busy = false;
  bool _tried = false;
  BackupProgress? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passphrase.addListener(_changed);
    _confirm.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _passphrase.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // The passphrase out of the fields once the backup has left the app.
  void _clear() {
    if (!mounted) return;
    _passphrase.clear();
    _confirm.clear();
    setState(() => _tried = false);
  }

  String? _passphraseError(AppLocalizations l10n) =>
      _tried &&
          passphraseStrength(_passphrase.text) == PassphraseStrength.tooShort
      ? l10n.backupPassphraseTooShort(minPassphraseLength)
      : null;

  String? _confirmError(AppLocalizations l10n) =>
      _tried && _confirm.text != _passphrase.text
      ? l10n.backupPassphraseMismatch
      : null;

  Future<void> _export({required bool share}) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _tried = true);
    if (_passphraseError(l10n) != null || _confirmError(l10n) != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    // Read before the awaits: the screen may be gone when they return.
    final BackupService service = ref.read(backupServiceProvider);
    final FileExporter exporter = ref.read(fileExporterProvider);
    final LockHold hold = ref.read(lockHoldProvider);
    final String name = backupFileName(ref.read(clockProvider).today().toIso());
    try {
      final ProgressThrottle throttle = ProgressThrottle();
      final Uint8List file = await service.export(_passphrase.text, (p) {
        if (mounted && throttle.admit(p)) setState(() => _progress = p);
      });
      if (mounted) setState(() => _progress = null);
      // The dialog and the share sheet are activities of their own: the lock stays open.
      if (share) {
        await hold.holdOpen(() => exporter.share(file, name, backupMimeType));
        _clear();
      } else if (await hold.holdOpen(
            () => exporter.saveAs(file, name, backupMimeType),
          ) ==
          SaveOutcome.saved) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.backupSaved(name))));
        _clear();
      }
    } on Object catch (e) {
      _log.warning('the backup failed: ${e.runtimeType}');
      if (mounted) setState(() => _error = l10n.backupExportFailed);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PassphraseStrength strength = passphraseStrength(_passphrase.text);
    final BackupProgress? progress = _progress;
    final String? error = _error;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.backupExportExplanation),
          const SizedBox(height: 16),
          TextField(
            controller: _passphrase,
            enabled: !_busy,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.backupPassphrase,
              helperText: _passphrase.text.isEmpty
                  ? l10n.backupPassphraseHelper(minPassphraseLength)
                  : _strengthLabel(l10n, strength),
              helperMaxLines: 3,
              errorText: _passphraseError(l10n),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirm,
            enabled: !_busy,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.backupPassphraseConfirm,
              errorText: _confirmError(l10n),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.backupNoRecovery,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.save_alt),
                label: Text(l10n.backupSave),
                onPressed: _busy
                    ? null
                    : () => unawaited(_export(share: false)),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.share),
                label: Text(l10n.backupShare),
                onPressed: _busy ? null : () => unawaited(_export(share: true)),
              ),
            ],
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
      ),
    );
  }
}

String? _strengthLabel(AppLocalizations l10n, PassphraseStrength strength) =>
    switch (strength) {
      PassphraseStrength.tooShort => l10n.backupPassphraseHelper(
        minPassphraseLength,
      ),
      PassphraseStrength.weak => l10n.backupStrengthWeak,
      PassphraseStrength.fair => l10n.backupStrengthFair,
      PassphraseStrength.strong => l10n.backupStrengthStrong,
    };
