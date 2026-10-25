/// The rule editor, for `/settings/rules/new` and `/settings/rules/:id`: the name, the
/// conditions (one row each, of any kind the model has: text the merchant or description
/// contains, an amount range in one currency, an account, a bank category) and the
/// actions (set the category, add a tag, rename, hide). A rule needs a name, a condition and an action, and every
/// row its value, before it saves. Deleting from here offers an undo.
///
/// Under the actions, the preview: how many of the existing transactions the rule as
/// edited would change (`rulePreviewProvider`), recomputed 300 ms after the last edit of
/// a condition or an action, once every row has a valid value; "Preview" lists them.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/presentation/currency_picker.dart';
import 'package:finance_tracker/features/categories/presentation/category_picker.dart';
import 'package:finance_tracker/features/rules/application/rule_preview.dart';
import 'package:finance_tracker/features/rules/application/rules_providers.dart';
import 'package:finance_tracker/features/rules/presentation/rule_preview_sheet.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/presentation/amount_input.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart'
    show undoDuration;
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

/// The editor of rule [ruleId], or of a new rule when it is null.
class RuleEditorScreen extends ConsumerWidget {
  const RuleEditorScreen({super.key, this.ruleId});

  final String? ruleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<Rule>? rules = ref.watch(rulesProvider).value;
    final List<Account>? accounts = ref.watch(accountsProvider).value;
    if (rules == null || accounts == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final String? id = ruleId;
    if (id == null) return _RuleForm(initial: null, accounts: accounts);
    final Rule? rule = rules.where((r) => r.id == id).firstOrNull;
    if (rule == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.ruleNotFound)),
      );
    }
    return _RuleForm(key: ValueKey(id), initial: rule, accounts: accounts);
  }
}

/// A condition row being edited.
final class _ConditionDraft {
  _ConditionDraft(this.kind, {RuleCondition? from, required this.currency})
    : text = TextEditingController(
        text: kind == RuleConditionKind.merchantContains ? from?.text : null,
      ),
      min = TextEditingController(text: from?.minAmount?.format(symbol: false)),
      max = TextEditingController(text: from?.maxAmount?.format(symbol: false)),
      choice =
          kind == RuleConditionKind.account ||
              kind == RuleConditionKind.plaidCategory
          ? from?.text
          : null;

  final RuleConditionKind kind;
  final TextEditingController text;
  final TextEditingController min;
  final TextEditingController max;

  /// The account id or the Plaid code.
  String? choice;

  /// The currency of the amount bounds.
  String currency;

  RuleCondition toCondition() => switch (kind) {
    RuleConditionKind.merchantContains => RuleCondition(
      kind: kind,
      text: text.text.trim(),
    ),
    RuleConditionKind.amountBetween => RuleCondition(
      kind: kind,
      minAmount: min.text.trim().isEmpty
          ? null
          : parseAmountInput(min.text, currency),
      maxAmount: max.text.trim().isEmpty
          ? null
          : parseAmountInput(max.text, currency),
    ),
    RuleConditionKind.account ||
    RuleConditionKind.plaidCategory => RuleCondition(kind: kind, text: choice),
  };

  /// Whether the row has a valid value, as saving requires.
  bool get isComplete => switch (kind) {
    RuleConditionKind.merchantContains => text.text.trim().isNotEmpty,
    RuleConditionKind.amountBetween => _boundsComplete,
    RuleConditionKind.account ||
    RuleConditionKind.plaidCategory => choice != null,
  };

  bool get _boundsComplete {
    final String low = min.text.trim();
    final String high = max.text.trim();
    if (low.isEmpty && high.isEmpty) return false;
    final Money? lower = low.isEmpty ? null : parseAmountInput(low, currency);
    final Money? upper = high.isEmpty ? null : parseAmountInput(high, currency);
    if (low.isNotEmpty && (lower == null || lower.isNegative)) return false;
    if (high.isNotEmpty && (upper == null || upper.isNegative)) return false;
    return lower == null ||
        upper == null ||
        lower.minorUnits <= upper.minorUnits;
  }

  void dispose() {
    text.dispose();
    min.dispose();
    max.dispose();
  }
}

/// An action row being edited.
final class _ActionDraft {
  _ActionDraft(this.kind, {RuleAction? from})
    : value = TextEditingController(
        text: kind == RuleActionKind.addTag || kind == RuleActionKind.rename
            ? from?.value
            : null,
      ),
      categoryId = kind == RuleActionKind.setCategory ? from?.value : null;

  final RuleActionKind kind;
  final TextEditingController value;
  String? categoryId;

  RuleAction toAction() => switch (kind) {
    RuleActionKind.setCategory => RuleAction(kind: kind, value: categoryId),
    RuleActionKind.addTag ||
    RuleActionKind.rename => RuleAction(kind: kind, value: value.text.trim()),
    RuleActionKind.hide => RuleAction(kind: kind),
  };

  /// Whether the row has a value, as saving requires.
  bool get isComplete => switch (kind) {
    RuleActionKind.setCategory => categoryId != null,
    RuleActionKind.addTag ||
    RuleActionKind.rename => value.text.trim().isNotEmpty,
    RuleActionKind.hide => true,
  };

  void dispose() => value.dispose();
}

class _RuleForm extends ConsumerStatefulWidget {
  const _RuleForm({super.key, required this.initial, required this.accounts});

  /// The rule being edited, or null for a new one.
  final Rule? initial;
  final List<Account> accounts;

  @override
  ConsumerState<_RuleForm> createState() => _RuleFormState();
}

class _RuleFormState extends ConsumerState<_RuleForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name,
  );
  late final List<_ConditionDraft> _conditions = [
    for (final RuleCondition c in widget.initial?.conditions ?? const [])
      _ConditionDraft(
        c.kind,
        from: c,
        currency:
            c.minAmount?.currencyCode ??
            c.maxAmount?.currencyCode ??
            _currencies.first,
      ),
  ];
  late final List<_ActionDraft> _actions = [
    for (final RuleAction a in widget.initial?.actions ?? const [])
      _ActionDraft(a.kind, from: a),
  ];
  bool _submitted = false;
  bool _saving = false;

  // The rule the preview shows, and the wait before the next one replaces it.
  Rule? _previewed;
  Timer? _previewDebounce;

  static const Duration _previewDelay = Duration(milliseconds: 300);

  bool get _isNew => widget.initial == null;

  /// The accounts' currencies, the device's default when there is no account.
  List<String> get _currencies {
    final List<String> codes = {
      for (final Account a in widget.accounts) a.currencyCode,
    }.toList()..sort();
    return codes.isEmpty ? [defaultCurrencyCode()] : codes;
  }

  @override
  void initState() {
    super.initState();
    _previewed = _draft();
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _draftChanged();
  }

  // The rule as the form holds it, for the preview: null while there is no condition or
  // no action, or a row has no valid value. The name and the position do not change what
  // the rule alone does to a transaction, so they are left out.
  Rule? _draft() {
    if (_conditions.isEmpty || _actions.isEmpty) return null;
    if (!_conditions.every((c) => c.isComplete)) return null;
    if (!_actions.every((a) => a.isComplete)) return null;
    return Rule(
      id: widget.initial?.id ?? '',
      name: '',
      position: 0,
      conditions: [
        for (final _ConditionDraft c in _conditions) c.toCondition(),
      ],
      actions: [for (final _ActionDraft a in _actions) a.toAction()],
    );
  }

  // Schedules the preview of the form's rule when it differs from the one shown.
  void _draftChanged() {
    final Rule? draft = _draft();
    _previewDebounce?.cancel();
    if (draft == _previewed) return;
    _previewDebounce = Timer(_previewDelay, () {
      if (mounted) super.setState(() => _previewed = draft);
    });
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _name.dispose();
    for (final _ConditionDraft c in _conditions) {
      c.dispose();
    }
    for (final _ActionDraft a in _actions) {
      a.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final bool valid = _form.currentState!.validate();
    if (!valid || _conditions.isEmpty || _actions.isEmpty) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final RuleActions actions = ref.read(ruleActionsProvider);
    final String name = _name.text.trim();
    final List<RuleCondition> conditions = [
      for (final _ConditionDraft c in _conditions) c.toCondition(),
    ];
    final List<RuleAction> ruleActions = [
      for (final _ActionDraft a in _actions) a.toAction(),
    ];
    setState(() => _saving = true);
    try {
      final Rule? initial = widget.initial;
      if (initial == null) {
        await actions.create(
          live: ref.read(rulesProvider).value ?? const [],
          name: name,
          conditions: conditions,
          actions: ruleActions,
        );
      } else {
        await actions.update(
          initial.copyWith(
            name: name,
            conditions: conditions,
            actions: ruleActions,
          ),
        );
      }
      if (mounted) context.pop();
    } on EntityDeletedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.ruleNotFound)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final RuleActions actions = ref.read(ruleActionsProvider);
    final String id = widget.initial!.id;
    context.pop();
    await actions.delete(id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.ruleDeleted),
        duration: undoDuration,
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => actions.restore(id),
        ),
      ),
    );
  }

  String _conditionLabel(AppLocalizations l10n, RuleConditionKind kind) =>
      switch (kind) {
        RuleConditionKind.merchantContains => l10n.ruleConditionMerchant,
        RuleConditionKind.amountBetween => l10n.ruleConditionAmount,
        RuleConditionKind.account => l10n.ruleConditionAccount,
        RuleConditionKind.plaidCategory => l10n.ruleConditionBankCategory,
      };

  String _actionLabel(AppLocalizations l10n, RuleActionKind kind) =>
      switch (kind) {
        RuleActionKind.setCategory => l10n.ruleActionSetCategory,
        RuleActionKind.addTag => l10n.ruleActionAddTag,
        RuleActionKind.rename => l10n.ruleActionRename,
        RuleActionKind.hide => l10n.ruleActionHide,
      };

  // A row's frame: its kind, its fields, and a remove button.
  Widget _row({
    required String title,
    required String removeTooltip,
    required VoidCallback onRemove,
    required List<Widget> children,
  }) => Card.outlined(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: removeTooltip,
                icon: const Icon(Icons.close),
                onPressed: onRemove,
              ),
            ],
          ),
          for (final Widget child in children)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12, top: 4),
              child: child,
            ),
        ],
      ),
    ),
  );

  // A field that opens a picker: [label], the chosen [value] or a placeholder, and
  // [error] after a save attempt.
  Widget _pickerField({
    required String label,
    required String? value,
    required Future<void> Function() onTap,
    required FormFieldValidator<String> validator,
  }) => FormField<String>(
    key: ValueKey('$label/$value'),
    initialValue: value,
    validator: validator,
    builder: (state) => InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: state.errorText,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(value ?? AppLocalizations.of(context).ruleChooseCategory),
      ),
    ),
  );

  Widget _condition(
    AppLocalizations l10n,
    CategoryLookup categories,
    _ConditionDraft c,
  ) {
    final String label = _conditionLabel(l10n, c.kind);
    void remove() => setState(() {
      _conditions.remove(c);
      c.dispose();
    });
    switch (c.kind) {
      case RuleConditionKind.merchantContains:
        return _row(
          title: label,
          removeTooltip: l10n.ruleRemoveCondition,
          onRemove: remove,
          children: [
            TextFormField(
              controller: c.text,
              decoration: InputDecoration(
                labelText: l10n.ruleText,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.ruleTextRequired : null,
            ),
          ],
        );
      case RuleConditionKind.amountBetween:
        final List<String> currencies = _currencies;
        String? boundError(String? text) =>
            amountInputError(l10n, text ?? '', c.currency, signed: false);
        return _row(
          title: label,
          removeTooltip: l10n.ruleRemoveCondition,
          onRemove: remove,
          children: [
            if (currencies.length > 1)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final String code in currencies)
                    ChoiceChip(
                      label: Text(code),
                      selected: code == c.currency,
                      onSelected: (_) => setState(() => c.currency = code),
                    ),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: c.min,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.filterAmountMin,
                      prefixText: currencySymbol(c.currency),
                      errorMaxLines: 3,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final String? error = boundError(v);
                      if (error != null) return error;
                      if (c.min.text.trim().isEmpty &&
                          c.max.text.trim().isEmpty) {
                        return l10n.ruleAmountRequired;
                      }
                      final RuleCondition range = c.toCondition();
                      final Money? min = range.minAmount;
                      final Money? max = range.maxAmount;
                      if (min != null &&
                          max != null &&
                          min.minorUnits > max.minorUnits) {
                        return l10n.ruleAmountOrder;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: c.max,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.filterAmountMax,
                      prefixText: currencySymbol(c.currency),
                      errorMaxLines: 3,
                      border: const OutlineInputBorder(),
                    ),
                    validator: boundError,
                  ),
                ),
              ],
            ),
          ],
        );
      case RuleConditionKind.account:
        final bool known = widget.accounts.any((a) => a.id == c.choice);
        return _row(
          title: label,
          removeTooltip: l10n.ruleRemoveCondition,
          onRemove: remove,
          children: [
            DropdownButtonFormField<String>(
              initialValue: known ? c.choice : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.ruleConditionAccount,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final Account a in widget.accounts)
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
              ],
              onChanged: (id) => setState(() => c.choice = id),
              validator: (id) => id == null ? l10n.ruleAccountRequired : null,
            ),
          ],
        );
      case RuleConditionKind.plaidCategory:
        final String? code = c.choice;
        return _row(
          title: label,
          removeTooltip: l10n.ruleRemoveCondition,
          onRemove: remove,
          children: [
            _pickerField(
              label: l10n.ruleConditionBankCategory,
              value: code == null
                  ? null
                  : categories.byPlaidCode[code]?.name ?? code,
              validator: (_) =>
                  c.choice == null ? l10n.ruleCategoryRequired : null,
              onTap: () async {
                final CategoryChoice? choice = await showCategoryPicker(
                  context,
                  selectedId: categories.byPlaidCode[code]?.id,
                  allowNone: false,
                  systemOnly: true,
                );
                final String? picked =
                    categories.byId[choice?.categoryId]?.plaidCategory;
                if (picked != null && mounted) {
                  setState(() => c.choice = picked);
                }
              },
            ),
          ],
        );
    }
  }

  Widget _action(
    AppLocalizations l10n,
    ThemeData theme,
    CategoryLookup categories,
    _ActionDraft a,
  ) {
    final String label = _actionLabel(l10n, a.kind);
    void remove() => setState(() {
      _actions.remove(a);
      a.dispose();
    });
    Widget caption(String text) => Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    return _row(
      title: label,
      removeTooltip: l10n.ruleRemoveAction,
      onRemove: remove,
      children: switch (a.kind) {
        RuleActionKind.setCategory => [
          _pickerField(
            label: l10n.ruleActionSetCategory,
            value: categories.byId[a.categoryId]?.name,
            validator: (_) => categories.byId[a.categoryId] == null
                ? l10n.ruleCategoryRequired
                : null,
            onTap: () async {
              final CategoryChoice? choice = await showCategoryPicker(
                context,
                selectedId: a.categoryId,
                allowNone: false,
              );
              if (choice?.categoryId case final String id when mounted) {
                setState(() => a.categoryId = id);
              }
            },
          ),
          caption(l10n.ruleActionSetCategoryCaption),
        ],
        RuleActionKind.addTag => [
          TextFormField(
            controller: a.value,
            decoration: InputDecoration(
              labelText: l10n.ruleTag,
              border: const OutlineInputBorder(),
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? l10n.ruleTagRequired : null,
          ),
        ],
        RuleActionKind.rename => [
          TextFormField(
            controller: a.value,
            decoration: InputDecoration(
              labelText: l10n.ruleNewDescription,
              border: const OutlineInputBorder(),
            ),
            validator: (v) => (v ?? '').trim().isEmpty
                ? l10n.ruleNewDescriptionRequired
                : null,
          ),
          caption(l10n.ruleActionRenameCaption),
        ],
        RuleActionKind.hide => [caption(l10n.ruleActionHideCaption)],
      },
    );
  }

  // What the rule as edited would change in the existing transactions.
  Widget _preview(AppLocalizations l10n, ThemeData theme) {
    final TextStyle? style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final Rule? draft = _previewed;
    if (draft == null) return Text(l10n.rulePreviewIncomplete, style: style);
    final AsyncValue<RulePreview> preview = ref.watch(
      rulePreviewProvider(draft),
    );
    final RulePreview? value = preview.value;
    if (value == null) {
      return Text(
        preview.hasError ? l10n.loadFailed : l10n.rulePreviewChecking,
        style: style,
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.rulePreviewCount(value.changes.length, value.total),
            style: style,
          ),
        ),
        TextButton(
          onPressed: value.changes.isEmpty
              ? null
              : () => showRulePreviewSheet(context, value),
          child: Text(l10n.rulePreviewOpen),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final CategoryLookup categories = ref.watch(
      transactionCategoryLookupProvider,
    );
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(title, style: theme.textTheme.titleMedium),
    );
    Widget problem(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.ruleNewTitle : l10n.ruleEditTitle),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
          TextButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ],
      ),
      body: Form(
        key: _form,
        onChanged: _draftChanged,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.ruleName,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.ruleNameRequired : null,
            ),
            section(l10n.ruleConditionsHeader),
            for (final _ConditionDraft c in _conditions)
              _condition(l10n, categories, c),
            if (_submitted && _conditions.isEmpty)
              problem(l10n.ruleNeedsCondition),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PopupMenuButton<RuleConditionKind>(
                tooltip: l10n.ruleAddCondition,
                onSelected: (kind) => setState(
                  () => _conditions.add(
                    _ConditionDraft(kind, currency: _currencies.first),
                  ),
                ),
                itemBuilder: (context) => [
                  for (final RuleConditionKind kind in RuleConditionKind.values)
                    PopupMenuItem(
                      value: kind,
                      child: Text(_conditionLabel(l10n, kind)),
                    ),
                ],
                child: _AddLabel(l10n.ruleAddCondition),
              ),
            ),
            section(l10n.ruleActionsHeader),
            for (final _ActionDraft a in _actions)
              _action(l10n, theme, categories, a),
            if (_submitted && _actions.isEmpty) problem(l10n.ruleNeedsAction),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PopupMenuButton<RuleActionKind>(
                tooltip: l10n.ruleAddAction,
                onSelected: (kind) =>
                    setState(() => _actions.add(_ActionDraft(kind))),
                itemBuilder: (context) => [
                  for (final RuleActionKind kind in RuleActionKind.values)
                    PopupMenuItem(
                      value: kind,
                      child: Text(_actionLabel(l10n, kind)),
                    ),
                ],
                child: _AddLabel(l10n.ruleAddAction),
              ),
            ),
            const SizedBox(height: 16),
            _preview(l10n, theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// What an "Add …" menu button shows: a plus and its label, at least 48 high.
class _AddLabel extends StatelessWidget {
  const _AddLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
