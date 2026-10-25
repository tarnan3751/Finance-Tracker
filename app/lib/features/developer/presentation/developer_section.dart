/// The settings screen's Developer section (dev flavor only, `docs/reference/developer.md`):
/// diagnostics (the server, this device's id, the last sync and bank data pull, the
/// outbox and held records), Pull now with its outcome, Copy diagnostics (plain text,
/// never a token), and Sandbox controls, which opens `DeveloperScreen`.
library;

import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/developer/application/developer_controller.dart';
import 'package:finance_tracker/features/developer/presentation/developer_screen.dart';
import 'package:finance_tracker/features/settings/presentation/settings_section_header.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// The Developer section.
class DeveloperSection extends ConsumerWidget {
  const DeveloperSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DeveloperState developer = ref.watch(developerControllerProvider);
    final SyncStatus status = ref.watch(syncControllerProvider);
    final Clock clock = ref.watch(clockProvider);
    String local(DateTime? utc) => utc == null
        ? l10n.developerNever
        : DateFormat.yMMMd().add_jm().format(
            tz.TZDateTime.from(utc, clock.location),
          );

    final Uri? server = ref.watch(appConfigProvider).serverBaseUrl;
    final String? deviceId = ref.watch(syncDeviceIdProvider);
    // The last whole pull, whether the sync controller or this menu ran it.
    final DateTime? pulledAt = switch ((
      developer.pull?.pulledAt,
      status.plaidPulledAt,
    )) {
      (final DateTime a?, final DateTime b?) => a.isAfter(b) ? a : b,
      (final DateTime? a, final DateTime? b) => a ?? b,
    };
    final rows = <(IconData, String, String)>[
      (
        Icons.dns_outlined,
        l10n.settingsServer,
        fakeServerInDev || server == null
            ? l10n.settingsServerFake
            : apiBaseUrl(server),
      ),
      (
        Icons.smartphone_outlined,
        l10n.developerDevice,
        deviceId ?? l10n.developerDeviceNone,
      ),
      (Icons.sync, l10n.developerLastSync, local(status.lastSyncAt)),
      (Icons.account_balance_outlined, l10n.developerBankData, local(pulledAt)),
      (
        Icons.outbox_outlined,
        l10n.developerLedger,
        switch (status.ledger) {
          final ledger? => l10n.developerLedgerValue(
            ledger.pending,
            ledger.held,
          ),
          null => l10n.developerLedgerUnknown,
        },
      ),
    ];
    final DeveloperPull? pull = developer.pull;
    final bool pulling = developer.running == DeveloperOperation.pull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(l10n.settingsDeveloper),
        for (final (IconData icon, String title, String value) in rows)
          ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(value),
          ),
        if (pulling)
          DeveloperRunningLine(label: l10n.developerRunning)
        else if (pull != null)
          DeveloperResultLine(
            text: switch (pull.failure) {
              final failure? => l10n.developerPullFailed(failure),
              null => l10n.developerPulled(local(pull.pulledAt)),
            },
            failed: pull.failure != null,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: developer.running == null
                    ? () => ref
                          .read(developerControllerProvider.notifier)
                          .pullNow()
                    : null,
                icon: const Icon(Icons.download_outlined),
                label: Text(l10n.developerPullNow),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text: [
                        for (final (_, String title, String value) in rows)
                          '$title: $value',
                      ].join('\n'),
                    ),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.developerCopied)));
                },
                icon: const Icon(Icons.copy_outlined),
                label: Text(l10n.developerCopy),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.developer_mode_outlined),
          title: Text(l10n.developerOpenSandbox),
          subtitle: Text(l10n.developerOpenSandboxDetail),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const DeveloperScreen()),
          ),
        ),
      ],
    );
  }
}

/// An operation in flight: a small spinner and [label], announced.
class DeveloperRunningLine extends StatelessWidget {
  const DeveloperRunningLine({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    ),
  );
}

/// An operation's outcome, in the error color when it [failed], announced.
class DeveloperResultLine extends StatelessWidget {
  const DeveloperResultLine({
    required this.text,
    required this.failed,
    super.key,
  });

  final String text;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: failed ? theme.colorScheme.error : null,
          ),
        ),
      ),
    );
  }
}
