/// The full-screen category picker of the transaction editor, the filter sheet and the
/// rule editor: a search field, "None" (uncategorized) when allowed, the recently used
/// categories, then the whole hierarchy (only the built-in categories when asked), and a
/// link to category management.
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/categories/presentation/category_icons.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// What the user picked: a category id, or null for "None".
final class CategoryChoice {
  const CategoryChoice(this.categoryId);

  final String? categoryId;
}

/// How many recently used categories the picker lists first.
const int _recentCount = 5;

/// Shows the picker with [selectedId] marked; completes with the choice, or null when the
/// user backs out. [allowNone] offers "None"; [systemOnly] lists only the categories with
/// a Plaid code (the built-in ones).
Future<CategoryChoice?> showCategoryPicker(
  BuildContext context, {
  String? selectedId,
  bool allowNone = true,
  bool systemOnly = false,
}) => Navigator.of(context).push<CategoryChoice>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (context) => CategoryPickerScreen(
      selectedId: selectedId,
      allowNone: allowNone,
      systemOnly: systemOnly,
    ),
  ),
);

/// The picker's screen.
class CategoryPickerScreen extends ConsumerStatefulWidget {
  const CategoryPickerScreen({
    super.key,
    this.selectedId,
    this.allowNone = true,
    this.systemOnly = false,
  });

  final String? selectedId;
  final bool allowNone;
  final bool systemOnly;

  @override
  ConsumerState<CategoryPickerScreen> createState() =>
      _CategoryPickerScreenState();
}

/// A row of the picker: a section header, "None", or a category (indented under its
/// parent in the hierarchy, with its parent's name elsewhere).
sealed class _Row {
  const _Row();
}

final class _HeaderRow extends _Row {
  const _HeaderRow(this.title);
  final String title;
}

final class _NoneRow extends _Row {
  const _NoneRow();
}

final class _CategoryRow extends _Row {
  const _CategoryRow(this.category, {this.parentName, this.indented = false});
  final Category category;
  final String? parentName;
  final bool indented;
}

class _CategoryPickerScreenState extends ConsumerState<CategoryPickerScreen> {
  String _query = '';

  List<_Row> _rows(AppLocalizations l10n) {
    final List<CategoryGroup> tree = ref.watch(categoryTreeProvider);
    final Map<String, Category> byId = ref.watch(categoriesByIdProvider);
    final String query = _query.trim().toLowerCase();
    String? parentName(Category c) => byId[c.parentId]?.name;
    bool shown(Category c) => !widget.systemOnly || c.plaidCategory != null;
    if (query.isNotEmpty) {
      return [
        for (final CategoryGroup group in tree)
          for (final Category c in [group.primary, ...group.children])
            if (shown(c) && c.name.toLowerCase().contains(query))
              _CategoryRow(c, parentName: parentName(c)),
      ];
    }
    final List<Category> recent = [
      for (final String id
          in ref.watch(transactionUsageProvider).value?.recentCategoryIds ??
              const <String>[])
        if (byId[id] case final Category c when shown(c)) c,
    ].take(_recentCount).toList();
    return [
      if (widget.allowNone) const _NoneRow(),
      if (recent.isNotEmpty) ...[
        _HeaderRow(l10n.categoryPickerRecent),
        for (final Category c in recent)
          _CategoryRow(c, parentName: parentName(c)),
      ],
      _HeaderRow(l10n.categoryPickerAll),
      for (final CategoryGroup group in tree) ...[
        if (shown(group.primary)) _CategoryRow(group.primary),
        for (final Category c in group.children)
          if (shown(c)) _CategoryRow(c, indented: true),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final List<_Row> rows = _rows(l10n);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoryPickerTitle),
        actions: [
          TextButton(
            onPressed: () => const CategoriesRoute().push<void>(context),
            child: Text(l10n.categoriesManage),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.categoriesSearch,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, index) => switch (rows[index]) {
                _HeaderRow(:final String title) => Semantics(
                  header: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                _NoneRow() => ListTile(
                  leading: Icon(
                    fallbackCategoryIcon,
                    color: theme.colorScheme.outline,
                  ),
                  title: Text(l10n.categoryNone),
                  selected: widget.selectedId == null,
                  trailing: widget.selectedId == null
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () =>
                      Navigator.of(context).pop(const CategoryChoice(null)),
                ),
                _CategoryRow(
                  :final Category category,
                  :final String? parentName,
                  :final bool indented,
                ) =>
                  ListTile(
                    contentPadding: EdgeInsetsDirectional.only(
                      start: indented ? 56 : 16,
                      end: 16,
                    ),
                    leading: Icon(
                      categoryIconFor(category.icon),
                      color: categoryColor(context, category.color),
                    ),
                    title: Text(category.name),
                    subtitle: parentName == null ? null : Text(parentName),
                    selected: category.id == widget.selectedId,
                    trailing: category.id == widget.selectedId
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () =>
                        Navigator.of(context).pop(CategoryChoice(category.id)),
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
