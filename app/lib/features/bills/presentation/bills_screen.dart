/// `/bills`: the bills with their status, a placeholder until the Plan tab's Bills
/// segment (5e) replaces it with the list and the calendar (`docs/reference/bills.md`,
/// **Screens**). Each row shows the bill's name, its next due date and whether it is
/// paid, due, missed or upcoming; tapping one opens its editor, and New bill opens an
/// empty one.
library;

import 'package:finance_tracker/core/router/plan_scaffold.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The bills.
class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<BillStatus>? statuses = ref.watch(billStatusesProvider).value;
    final Map<String, String> streamNames =
        ref.watch(streamNamesProvider).value ?? const {};
    return PlanScaffold(
      segment: PlanSegment.bills,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => const NewBillRoute().push<void>(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.billNew),
      ),
      body: switch (statuses) {
        null => const Center(child: CircularProgressIndicator()),
        [] => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.billsEmpty, textAlign: TextAlign.center),
          ),
        ),
        final List<BillStatus> list => ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            for (final BillStatus s in list)
              ListTile(
                title: Text(
                  billName(s.bill.name ?? streamNames[s.bill.streamId], l10n),
                ),
                subtitle: Text(switch (s.nextDue) {
                  final next? => l10n.billNextDue(shortDateLabel(next)),
                  null => l10n.billNoNextDue,
                }),
                trailing: _StateChip(s.state),
                onTap: () => EditBillRoute(s.bill.id).push<void>(context),
              ),
          ],
        ),
      },
    );
  }
}

/// A bill's state, in words and colour.
class _StateChip extends StatelessWidget {
  const _StateChip(this.state);

  final BillState state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final (String label, Color color) = switch (state) {
      BillState.paid => (l10n.billStatePaid, colors.primary),
      BillState.due => (l10n.billStateDue, colors.tertiary),
      BillState.missed => (l10n.billStateMissed, colors.error),
      BillState.upcoming => (l10n.billStateUpcoming, colors.onSurfaceVariant),
    };
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
    );
  }
}
