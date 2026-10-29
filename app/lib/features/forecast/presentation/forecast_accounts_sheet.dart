/// The sheet choosing what the forecast covers: a switch per depository account (hidden
/// ones listed, off unless turned on), and, when the covered accounts hold more than one
/// currency, a chip per currency choosing the series shown. Each change is applied at
/// once (`ForecastSelectionController`); a change that cannot be kept goes back, and a
/// line under the switches says so (in the sheet, since the app's messenger is under it)
/// until the next change is kept.
library;

import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/forecast/application/forecast_providers.dart';
import 'package:finance_tracker/features/forecast/domain/forecast_selection.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// Opens the account sheet over the whole app.
Future<void> showForecastAccountsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const ForecastAccountsSheet(),
    );

/// The account switches and the currency chips.
class ForecastAccountsSheet extends ConsumerStatefulWidget {
  const ForecastAccountsSheet({super.key});

  @override
  ConsumerState<ForecastAccountsSheet> createState() =>
      _ForecastAccountsSheetState();
}

class _ForecastAccountsSheetState extends ConsumerState<ForecastAccountsSheet> {
  // Whether the last change could not be kept.
  bool _failed = false;

  // Runs [change], and shows or clears the failure line by whether it was kept.
  Future<void> _keep(Future<void> Function() change) async {
    bool failed = false;
    try {
      await change();
    } on Exception {
      failed = true;
    }
    if (mounted) setState(() => _failed = failed);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final List<Account> accounts = [
      for (final Account a in ref.watch(accountsProvider).value ?? const [])
        if (a.type == AccountType.depository) a,
    ];
    final ForecastSelection? selection = ref
        .watch(forecastSelectionControllerProvider)
        .value;
    if (selection == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final ForecastSelectionController controller = ref.read(
      forecastSelectionControllerProvider.notifier,
    );
    final List<String> currencies = {
      for (final Account a in selection.coveredAmong(accounts)) a.currencyCode,
    }.toList();
    final String? shown = selection.currencyFor(
      accounts,
      defaultCurrencyCode(),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              l10n.forecastAccountsTitle,
              style: theme.textTheme.titleLarge,
            ),
          ),
          for (final Account a in accounts)
            SwitchListTile(
              title: Text(a.name),
              subtitle: Text(
                a.isHidden
                    ? l10n.forecastAccountsHidden(a.currencyCode)
                    : a.currencyCode,
              ),
              value: selection.covers(a),
              onChanged: (_) => _keep(() => controller.toggle(a)),
            ),
          if (_failed)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l10n.forecastSelectionFailed,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          if (currencies.length > 1) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                l10n.forecastCurrency,
                style: theme.textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final String code in currencies)
                    ChoiceChip(
                      label: Text(code),
                      selected: code == shown,
                      onSelected: (_) =>
                          _keep(() => controller.showCurrency(code)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
