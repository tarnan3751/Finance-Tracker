/// Category management (Settings, Categories): the hierarchy, each top-level category
/// expandable to the categories under it, the system categories (seeded from Plaid's
/// taxonomy) marked with a lock; search; "Add category". Tapping a category opens its
/// editor.
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/categories/presentation/category_icons.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// The category list.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

/// A row on screen: a category, indented when it is under another, with its parent's
/// name in search results, and an expand control when it has children.
typedef _Row = ({
  Category category,
  bool indented,
  String? parentName,
  int childCount,
});

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final Set<String> _expanded = {};
  String _query = '';

  List<_Row> _rows(List<CategoryGroup> tree, Map<String, Category> byId) {
    final String query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      return [
        for (final CategoryGroup group in tree)
          for (final Category c in [group.primary, ...group.children])
            if (c.name.toLowerCase().contains(query))
              (
                category: c,
                indented: false,
                parentName: byId[c.parentId]?.name,
                childCount: 0,
              ),
      ];
    }
    return [
      for (final CategoryGroup group in tree) ...[
        (
          category: group.primary,
          indented: false,
          parentName: null,
          childCount: group.children.length,
        ),
        if (_expanded.contains(group.primary.id))
          for (final Category c in group.children)
            (category: c, indented: true, parentName: null, childCount: 0),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool loading = !ref.watch(categoriesProvider).hasValue;
    final List<_Row> rows = _rows(
      ref.watch(categoryTreeProvider),
      ref.watch(categoriesByIdProvider),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => const NewCategoryRoute().push<void>(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.categoryAdd),
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
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final _Row row = rows[index];
                      final Category category = row.category;
                      final bool expanded = _expanded.contains(category.id);
                      return ListTile(
                        key: ValueKey(category.id),
                        contentPadding: EdgeInsetsDirectional.only(
                          start: row.indented ? 56 : 16,
                          end: 8,
                        ),
                        leading: Icon(
                          categoryIconFor(category.icon),
                          color: categoryColor(context, category.color),
                        ),
                        title: Row(
                          children: [
                            Flexible(child: Text(category.name)),
                            if (category.isSystem) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                                semanticLabel: l10n.categorySystem,
                              ),
                            ],
                          ],
                        ),
                        subtitle: row.parentName == null
                            ? null
                            : Text(row.parentName!),
                        trailing: row.childCount == 0
                            ? null
                            : IconButton(
                                tooltip: expanded
                                    ? l10n.categoryCollapse(category.name)
                                    : l10n.categoryExpand(
                                        category.name,
                                        row.childCount,
                                      ),
                                icon: Icon(
                                  expanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                ),
                                onPressed: () => setState(
                                  () => expanded
                                      ? _expanded.remove(category.id)
                                      : _expanded.add(category.id),
                                ),
                              ),
                        onTap: () =>
                            EditCategoryRoute(category.id).push<void>(context),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
