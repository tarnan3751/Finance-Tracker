/// The Sandbox controls of the developer menu (dev flavor only, opened from the settings
/// screen's Developer section; `docs/reference/developer.md`):
///
/// - **Item**: a picker of the stored Items not removed, then Refresh transactions,
///   Refresh balances, Reset login and Fire webhook (a picker of the contract's
///   `WebhookCode`s), each followed by the Plaid pull, with the outcome on one line;
/// - **Inject transactions** into the picked Item: an account of it, how many (1 to 10),
///   a description, an amount in the app's sign and the days before Plaid's today (the
///   date at UTC−12, the latest the server accepts), then the pull;
/// - **Provision a persona**: persona, seed and days, Start, then the job's progress,
///   asked for every [provisionPollInterval] while this screen is open and the job runs
///   (the job id stays in the controller, so closing the screen stops the polling and
///   opening it again resumes it), and Pull now once it has finished.
library;

import 'dart:async';

import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/date_time_format.dart';
import 'package:finance_tracker/features/developer/application/developer_controller.dart';
import 'package:finance_tracker/features/developer/application/developer_providers.dart';
import 'package:finance_tracker/features/developer/presentation/developer_section.dart';
import 'package:finance_tracker/features/items/domain/linked_bank.dart';
import 'package:finance_tracker/features/settings/presentation/settings_section_header.dart';
import 'package:finance_tracker/features/transactions/presentation/amount_input.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// The Sandbox controls screen.
class DeveloperScreen extends ConsumerStatefulWidget {
  const DeveloperScreen({super.key});

  @override
  ConsumerState<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends ConsumerState<DeveloperScreen> {
  String? _itemId;
  SandboxWebhookCode _webhook = SandboxWebhookCode.values.first;
  String? _accountId;
  final GlobalKey<FormState> _injectForm = GlobalKey<FormState>();
  final TextEditingController _count = TextEditingController(text: '1');
  TextEditingController? _description;
  final TextEditingController _amount = TextEditingController(text: '-12.34');
  final TextEditingController _daysBack = TextEditingController(text: '0');
  final GlobalKey<FormState> _provisionForm = GlobalKey<FormState>();
  ProvisionPersona _persona = ProvisionPersona.values.first;
  final TextEditingController _seed = TextEditingController(text: '1');
  final TextEditingController _days = TextEditingController(text: '730');
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _followJob(ref.read(developerControllerProvider));
  }

  @override
  void dispose() {
    _poll?.cancel();
    for (final TextEditingController c in [
      _count,
      ?_description,
      _amount,
      _daysBack,
      _seed,
      _days,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // Polls while the job runs and this screen is open.
  void _followJob(DeveloperState state) {
    if (state.jobActive) {
      _poll ??= Timer.periodic(
        provisionPollInterval,
        (_) => ref.read(developerControllerProvider.notifier).pollJob(),
      );
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  DeveloperController get _controller =>
      ref.read(developerControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    _description ??= TextEditingController(
      text: l10n.developerDescriptionDefault,
    );
    ref.listen<DeveloperState>(
      developerControllerProvider,
      (_, next) => _followJob(next),
    );
    final DeveloperState state = ref.watch(developerControllerProvider);
    final List<LinkedBank>? items = ref.watch(developerItemsProvider).value;
    final String? itemId = switch (items) {
      final items? when items.any((b) => b.id == _itemId) => _itemId,
      [final LinkedBank first, ...] => first.id,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.developerOpenSandbox)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SettingsSectionHeader(l10n.developerItemSection),
          if (items == null)
            const LinearProgressIndicator()
          else if (itemId == null)
            _Padded(Text(l10n.developerNoItems))
          else ...[
            _Padded(
              DropdownButtonFormField<String>(
                key: ValueKey('item-$itemId'),
                initialValue: itemId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.developerItem,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final LinkedBank bank in items)
                    DropdownMenuItem(
                      value: bank.id,
                      child: Text(
                        l10n.developerItemOption(
                          bank.institution.name,
                          bank.id,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) => setState(() => _itemId = id),
              ),
            ),
            _Padded(
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: state.running == null
                        ? () => _controller.refreshTransactions(itemId)
                        : null,
                    child: Text(l10n.developerRefreshTransactions),
                  ),
                  FilledButton.tonal(
                    onPressed: state.running == null
                        ? () => _controller.refreshBalances(itemId)
                        : null,
                    child: Text(l10n.developerRefreshBalances),
                  ),
                  FilledButton.tonal(
                    onPressed: state.running == null
                        ? () => _controller.resetLogin(itemId)
                        : null,
                    child: Text(l10n.developerResetLogin),
                  ),
                ],
              ),
            ),
            _Padded(
              DropdownButtonFormField<SandboxWebhookCode>(
                initialValue: _webhook,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.developerWebhookCode,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final SandboxWebhookCode code
                      in SandboxWebhookCode.values)
                    DropdownMenuItem(
                      value: code,
                      // Plaid's identifier, not prose, so it is not localized.
                      child: Text(code.wire, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (code) {
                  if (code != null) setState(() => _webhook = code);
                },
              ),
            ),
            _Padded(
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonal(
                  onPressed: state.running == null
                      ? () => _controller.fireWebhook(itemId, _webhook)
                      : null,
                  child: Text(l10n.developerFireWebhook),
                ),
              ),
            ),
            if (_isItemOperation(state.running))
              DeveloperRunningLine(label: l10n.developerRunning)
            else if (state.result case final DeveloperResult result?)
              DeveloperResultLine(
                text: _resultText(l10n, result),
                failed: result.failure != null || result.pullFailure != null,
              ),
            SettingsSectionHeader(l10n.developerInjectSection),
            _inject(l10n, state, itemId),
          ],
          SettingsSectionHeader(l10n.developerProvisionSection),
          _provision(l10n, state),
        ],
      ),
    );
  }

  Widget _inject(AppLocalizations l10n, DeveloperState state, String itemId) {
    final List<Account>? accounts = ref
        .watch(developerItemAccountsProvider(itemId))
        .value;
    if (accounts == null) return const LinearProgressIndicator();
    final Account? account =
        accounts.where((a) => a.id == _accountId).firstOrNull ??
        accounts.firstOrNull;
    if (account == null) return _Padded(Text(l10n.developerNoAccounts));
    final int? daysBack = _intIn(_daysBack.text, 0, 730);
    final LocalDate today = plaidToday(ref.watch(clockProvider).nowUtc());

    return Form(
      key: _injectForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Padded(
            DropdownButtonFormField<String>(
              key: ValueKey('account-${account.id}'),
              initialValue: account.id,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.developerAccount,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final Account a in accounts)
                  DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (id) => setState(() => _accountId = id),
            ),
          ),
          _Padded(
            TextFormField(
              controller: _count,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.developerCount,
                border: const OutlineInputBorder(),
              ),
              validator: (text) => _intIn(text ?? '', 1, maxInjected) == null
                  ? l10n.developerCountInvalid
                  : null,
            ),
          ),
          _Padded(
            TextFormField(
              controller: _description,
              decoration: InputDecoration(
                labelText: l10n.developerDescription,
                border: const OutlineInputBorder(),
              ),
              validator: (text) {
                final int length = text?.trim().length ?? 0;
                return length < 1 || length > 196
                    ? l10n.developerDescriptionInvalid
                    : null;
              },
            ),
          ),
          _Padded(
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.developerAmount,
                helperText: l10n.developerAmountHelper,
                suffixText: account.currencyCode,
                border: const OutlineInputBorder(),
              ),
              validator: (text) => amountInputError(
                l10n,
                text ?? '',
                account.currencyCode,
                required: true,
                nonZero: true,
              ),
            ),
          ),
          _Padded(
            TextFormField(
              controller: _daysBack,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.developerDaysBack,
                helperText: daysBack == null
                    ? null
                    : l10n.developerDate(
                        DateFormat.yMMMd().format(
                          today.addDays(-daysBack).toDateTime(),
                        ),
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (text) => _intIn(text ?? '', 0, 730) == null
                  ? l10n.developerDaysBackInvalid
                  : null,
            ),
          ),
          _Padded(
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton(
                onPressed: state.running == null
                    ? () {
                        if (!_injectForm.currentState!.validate()) return;
                        _controller.injectTransactions(
                          itemId,
                          accountId: account.id,
                          count: _intIn(_count.text, 1, maxInjected)!,
                          description: _description!.text.trim(),
                          amount: parseAmountInput(
                            _amount.text,
                            account.currencyCode,
                          )!,
                          daysBack: _intIn(_daysBack.text, 0, 730)!,
                        );
                      }
                    : null,
                child: Text(l10n.developerInject),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _provision(AppLocalizations l10n, DeveloperState state) {
    final ProvisionJob? job = state.job;
    final ThemeData theme = Theme.of(context);
    return Form(
      key: _provisionForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Padded(
            DropdownButtonFormField<ProvisionPersona>(
              initialValue: _persona,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.developerPersona,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final ProvisionPersona persona in ProvisionPersona.values)
                  DropdownMenuItem(
                    value: persona,
                    child: Text(switch (persona) {
                      ProvisionPersona.renter => l10n.demoPersonaRenter,
                      ProvisionPersona.family => l10n.demoPersonaFamily,
                      ProvisionPersona.student => l10n.demoPersonaStudent,
                      ProvisionPersona.smallBusiness =>
                        l10n.demoPersonaSmallBusiness,
                    }, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (persona) {
                if (persona != null) setState(() => _persona = persona);
              },
            ),
          ),
          _Padded(
            TextFormField(
              controller: _seed,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.developerSeed,
                border: const OutlineInputBorder(),
              ),
              validator: (text) => _intIn(text ?? '', 1, 0x7FFFFFFF) == null
                  ? l10n.developerSeedInvalid
                  : null,
            ),
          ),
          _Padded(
            TextFormField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.developerDays,
                border: const OutlineInputBorder(),
              ),
              validator: (text) => _intIn(text ?? '', 30, 730) == null
                  ? l10n.developerDaysInvalid
                  : null,
            ),
          ),
          _Padded(
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton(
                onPressed: state.running == null && !state.jobActive
                    ? () {
                        if (!_provisionForm.currentState!.validate()) return;
                        _controller.provision(
                          _persona,
                          seed: _intIn(_seed.text, 1, 0x7FFFFFFF)!,
                          days: _intIn(_days.text, 30, 730)!,
                        );
                      }
                    : null,
                child: Text(l10n.developerProvision),
              ),
            ),
          ),
          if (state.running == DeveloperOperation.provision)
            DeveloperRunningLine(label: l10n.developerRunning),
          if (job != null) ...[
            Semantics(
              liveRegion: true,
              child: _Padded(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.developerJobStatus(job.status.name),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _fraction(job.progress),
                      semanticsLabel: l10n.developerJobProgress,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.developerJobItems(
                        job.progress.itemsLinked,
                        job.progress.itemsTotal,
                      ),
                    ),
                    Text(
                      l10n.developerJobBatches(
                        job.progress.batchesSent,
                        job.progress.batchesTotal,
                      ),
                    ),
                    Text(l10n.developerJobSkipped(job.progress.skipped)),
                    if (job.error case final String error)
                      Text(
                        l10n.developerJobError(error),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (state.jobFailure case final String failure)
            DeveloperResultLine(
              text: l10n.developerFailed(failure),
              failed: true,
            ),
          if (job != null && !state.jobActive) ...[
            if (state.running == DeveloperOperation.pull)
              DeveloperRunningLine(label: l10n.developerRunning)
            else if (state.pull case final DeveloperPull pull?)
              DeveloperResultLine(
                text: switch (pull.failure) {
                  final failure? => l10n.developerPullFailed(failure),
                  null => l10n.developerPulled(_local(pull.pulledAt)),
                },
                failed: pull.failure != null,
              ),
            _Padded(
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonalIcon(
                  onPressed: state.running == null ? _controller.pullNow : null,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(l10n.developerPullNow),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _local(DateTime? utc) {
    if (utc == null) return AppLocalizations.of(context).developerNever;
    return formatDateTime(utc, ref.read(clockProvider).location);
  }
}

bool _isItemOperation(DeveloperOperation? operation) => switch (operation) {
  null || DeveloperOperation.pull || DeveloperOperation.provision => false,
  _ => true,
};

String _resultText(AppLocalizations l10n, DeveloperResult result) {
  if (result.failure case final String failure) {
    return l10n.developerFailed(failure);
  }
  final String done = switch (result.operation) {
    DeveloperOperation.refreshTransactions => l10n.developerRefreshed(
      result.run!.status.name,
      result.run!.added,
      result.run!.modified,
      result.run!.removed,
    ),
    DeveloperOperation.refreshBalances => l10n.developerBalancesRefreshed(
      result.accounts!,
    ),
    DeveloperOperation.resetLogin => l10n.developerLoginReset,
    DeveloperOperation.fireWebhook => l10n.developerWebhookFired,
    DeveloperOperation.injectTransactions => l10n.developerInjected(
      result.injected!,
    ),
    DeveloperOperation.pull || DeveloperOperation.provision => '',
  };
  return switch (result.pullFailure) {
    final String failure => l10n.developerThenPullFailed(done, failure),
    null => done,
  };
}

// The job's share done: Items linked and batches sent of both totals; 0 before they
// are known, so the bar never animates.
double _fraction(ProvisionProgress p) {
  final int total = p.itemsTotal + p.batchesTotal;
  return total == 0 ? 0 : (p.itemsLinked + p.batchesSent) / total;
}

int? _intIn(String text, int min, int max) =>
    switch (int.tryParse(text.trim())) {
      final int n when n >= min && n <= max => n,
      _ => null,
    };

class _Padded extends StatelessWidget {
  const _Padded(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: child,
  );
}
