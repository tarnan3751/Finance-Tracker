/// One export run (`docs/reference/export.md`, **Screens**): the file made, handed to the
/// file exporter, and the user told: "Saved report-2026-10.pdf" after a save, nothing
/// after a cancel or a share (the share sheet is the answer), "The file could not be
/// exported" on any failure, making the file or handing it over (logged by its type).
/// Also the Save as and Share buttons and the privacy note.
library;

import 'dart:typed_data';

import 'package:finance_tracker/core/platform/file_exporter.dart';
import 'package:finance_tracker/core/platform/file_exporter_provider.dart';
import 'package:finance_tracker/features/lock/application/lock_hold.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('export');

/// Makes the file with [bytes] and saves it ([share] false) or shares it, as [fileName]
/// of [mimeType], telling the user through [messenger] in [l10n].
Future<void> runExport(
  WidgetRef ref, {
  required ScaffoldMessengerState messenger,
  required AppLocalizations l10n,
  required Future<Uint8List> Function() bytes,
  required String fileName,
  required String mimeType,
  required bool share,
}) async {
  final FileExporter exporter = ref.read(fileExporterProvider);
  // The dialog and the share sheet are activities of their own: the lock stays open.
  final LockHold hold = ref.read(lockHoldProvider);
  try {
    final Uint8List file = await bytes();
    if (share) {
      await hold.holdOpen(() => exporter.share(file, fileName, mimeType));
      return;
    }
    if (await hold.holdOpen(() => exporter.saveAs(file, fileName, mimeType)) ==
        SaveOutcome.saved) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.exportSaved(fileName))),
      );
    }
  } on Object catch (e) {
    // The exporter's own failure, or the file's: a font asset, the PDF's id, a report
    // too long for the page cap.
    _log.warning('the export failed: ${e.runtimeType}');
    messenger.showSnackBar(SnackBar(content: Text(l10n.exportFailed)));
  }
}

/// A pair of Save as and Share buttons, labelled for a screen reader by
/// [saveLabel] and [shareLabel], disabled without [onSave] and [onShare].
class ExportButtons extends StatelessWidget {
  const ExportButtons({
    super.key,
    required this.saveLabel,
    required this.shareLabel,
    required this.onSave,
    required this.onShare,
  });

  final String saveLabel;
  final String shareLabel;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        Semantics(
          label: saveLabel,
          excludeSemantics: true,
          button: true,
          enabled: onSave != null,
          onTap: onSave,
          child: OutlinedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_alt),
            label: Text(l10n.exportSaveAs),
          ),
        ),
        Semantics(
          label: shareLabel,
          excludeSemantics: true,
          button: true,
          enabled: onShare != null,
          onTap: onShare,
          child: FilledButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share),
            label: Text(l10n.exportShare),
          ),
        ),
      ],
    );
  }
}

/// The privacy note: a saved or shared file leaves the app; in the demo, where files go
/// nowhere, it says so too.
class ExportPrivacyNote extends StatelessWidget {
  const ExportPrivacyNote({super.key, required this.demo});

  final bool demo;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              demo
                  ? '${l10n.exportPrivacyNote} ${l10n.exportDemoNote}'
                  : l10n.exportPrivacyNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
