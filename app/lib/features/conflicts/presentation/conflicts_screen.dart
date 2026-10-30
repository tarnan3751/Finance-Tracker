/// The Conflicts screen (`/settings/conflicts`, from Settings → Sync): one card per field
/// whose value, written on this device, a change from another device replaced within
/// minutes. Each shows the record (its kind and name) and the field, both values with
/// the device that wrote each and when (in this device's zone), and two actions: "Keep
/// this device's value", which writes it again so it syncs and wins, and "Keep the
/// other", which keeps what is there and forgets the conflict. A receipt photo's conflict
/// shows each photo as on this device or not, and keeping this device's photo is offered
/// only while its bytes are still here, so it can be uploaded
/// (`docs/reference/sync-app.md`, **Conflicts**).
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/time/date_time_format.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/conflicts/application/conflicts_providers.dart';
import 'package:finance_tracker/features/conflicts/domain/sync_conflict.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// The conflicts.
class ConflictsScreen extends ConsumerWidget {
  const ConflictsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<SyncConflict>> conflicts = ref.watch(
      conflictsProvider,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.conflictsTitle)),
      body: switch (conflicts.value) {
        null when conflicts.hasError => Center(child: Text(l10n.loadFailed)),
        null => const Center(child: CircularProgressIndicator()),
        [] => EmptyState(
          icon: Icons.done_all,
          headline: l10n.conflictsEmptyHeadline,
          body: l10n.conflictsEmptyBody,
        ),
        final List<SyncConflict> list => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.conflictsIntro,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final SyncConflict c in list)
              _ConflictCard(key: ValueKey(c.key), conflict: c),
          ],
        ),
      },
    );
  }
}

class _ConflictCard extends ConsumerStatefulWidget {
  const _ConflictCard({super.key, required this.conflict});

  final SyncConflict conflict;

  @override
  ConsumerState<_ConflictCard> createState() => _ConflictCardState();
}

class _ConflictCardState extends ConsumerState<_ConflictCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function(ConflictActions) action) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String failed = AppLocalizations.of(context).conflictKeepFailed;
    setState(() => _busy = true);
    try {
      await action(ref.read(conflictActionsProvider));
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // "Keep this device's value", saying so when its photo turned out to be gone.
  Future<void> _keep() {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String gone = AppLocalizations.of(context).conflictPhotoGone;
    return _run((a) async {
      if (!await a.keepLocal(widget.conflict)) {
        messenger.showSnackBar(SnackBar(content: Text(gone)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final SyncConflict c = widget.conflict;
    final Clock clock = ref.watch(clockProvider);
    final String? thisDevice = ref.watch(syncDeviceIdProvider);
    final Map<String, String> names =
        ref.watch(conflictDeviceNamesProvider).value ?? const {};
    final CategoryLookup categories = ref.watch(
      transactionCategoryLookupProvider,
    );
    final Map<String, Account> accounts = ref.watch(accountsByIdProvider);
    String device(Hlc clock) => clock.nodeId == thisDevice
        ? l10n.conflictThisDevice
        : names[clock.nodeId] ?? clock.nodeId;
    String from(Hlc hlc) => l10n.conflictFrom(
      device(hlc),
      formatDateTime(hlc.wall, clock.location),
    );
    // A receipt photo's hash is no value to read: whether this device has the photo is.
    final bool photo = c.field == _receiptHashField;
    bool photoHere(Object? hash) =>
        hash is String &&
        ref.watch(localReceiptProvider(c.entityId, hash)).value != null;
    String value(Object? v) => photo && v is String
        ? (photoHere(v) ? l10n.conflictPhotoHere : l10n.conflictPhotoNotHere)
        : conflictValueText(l10n, c.field, v, categories, accounts);
    // Keeping a photo this device no longer has would name one nobody can fetch.
    final bool canKeep =
        !photo || c.localValue == null || photoHere(c.localValue);
    final String kind = l10n.conflictEntityType(c.entityType.name);
    final String fieldName = conflictFieldName(l10n, c.field);

    Widget side(String label, Object? v, Hlc hlc) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            const SizedBox(height: 2),
            Text(value(v), style: theme.textTheme.bodyLarge),
            Text(
              from(hlc),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              c.entityLabel == null ? kind : '$kind · ${c.entityLabel}',
              style: theme.textTheme.titleMedium,
            ),
            Text(
              fieldName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            side(l10n.conflictThisValue, c.localValue, c.localClock),
            side(l10n.conflictOtherValue, c.remoteValue, c.remoteClock),
            const SizedBox(height: 12),
            if (!canKeep)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.conflictPhotoGone,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => _run((a) => a.keepOther(c)),
                  child: Text(l10n.conflictKeepOther),
                ),
                FilledButton.tonal(
                  onPressed: _busy || !canKeep ? null : _keep,
                  child: Text(l10n.conflictKeepThis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The name of record field [field]: the screen's own word for the common ones, else the
/// field's name with spaces.
String conflictFieldName(AppLocalizations l10n, String field) {
  final String key = switch (field) {
    'user_category_id' || 'category_id' => 'category',
    'receipt_path' || 'receipt_sha256' => 'receipt',
    'account_id' => 'account',
    'theme_mode' => 'theme',
    'use_dynamic_color' => 'dynamicColor',
    'display_name' => 'name',
    'is_subscription' => 'subscription',
    'target_date' => 'targetDay',
    'date' => 'day',
    _ => field,
  };
  final String name = l10n.conflictField(key);
  return name.isNotEmpty ? name : field.replaceAll('_', ' ');
}

/// A conflict's value [value] of [field], as text: none, yes or no, an amount in its
/// currency, a category or an account by name, a list joined, splits counted, else the
/// value itself.
String conflictValueText(
  AppLocalizations l10n,
  String field,
  Object? value,
  CategoryLookup categories,
  Map<String, Account> accounts,
) => switch (value) {
  null || '' => l10n.conflictNoValue,
  true => l10n.conflictYes,
  false => l10n.conflictNo,
  {'minor_units': final int units, 'currency': final String currency} => Money(
    units,
    currency,
  ).format(),
  final String id when field == 'user_category_id' || field == 'category_id' =>
    categories.byId[id]?.name ?? id,
  final String id when field == 'account_id' => accounts[id]?.name ?? id,
  final List<Object?> splits when field == 'splits' => l10n.conflictSplits(
    splits.length,
  ),
  final List<Object?> list =>
    list.isEmpty ? l10n.conflictNoValue : list.join(', '),
  _ => '$value',
};

const String _receiptHashField = 'receipt_sha256';
