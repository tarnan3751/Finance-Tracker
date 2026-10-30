/// The restore offer (`/restore`, `docs/reference/backup.md`, **Restore**): shown, in
/// dev and prod, to a signed-in install whose database is empty until it is answered
/// (`RestoreOffer`). Sync waits meanwhile, so the backup lands before the server's
/// copy of the data does. "Start fresh" answers it, held while a restore is under way;
/// the router then leaves for the shell.
library;

import 'dart:async';

import 'package:finance_tracker/features/backup/application/backup_providers.dart';
import 'package:finance_tracker/features/backup/presentation/restore_flow.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The restore offer.
class RestoreOfferScreen extends ConsumerStatefulWidget {
  const RestoreOfferScreen({super.key});

  @override
  ConsumerState<RestoreOfferScreen> createState() => _RestoreOfferScreenState();
}

class _RestoreOfferScreenState extends ConsumerState<RestoreOfferScreen> {
  // Whether a restore is under way: Start fresh waits for it.
  bool _restoring = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.settings_backup_restore,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.restoreOfferTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.restoreOfferBody, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  RestoreFlow(
                    entry: RestoreEntry.offer,
                    onBusyChanged: (busy) => setState(() => _restoring = busy),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _restoring
                        ? null
                        : () => unawaited(
                            ref.read(restoreOfferProvider.notifier).answer(),
                          ),
                    child: Text(l10n.restoreOfferStartFresh),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
