/// The category editor, for a new category and an existing one: the name, the parent (none,
/// or any top-level category), an icon from the curated set and a color from a
/// twelve-swatch palette. A system category changes only its icon and color. Deleting a
/// user category (and the categories under it) asks first, counting the transactions it
/// leaves uncategorized.
library;

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/router/own_page.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:finance_tracker/features/categories/presentation/category_icons.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// The palette a category's color comes from: ARGB values and their names.
const List<({int color, String Function(AppLocalizations) name})>
categoryPalette = [
  (color: 0xFFC62828, name: _red),
  (color: 0xFFAD1457, name: _pink),
  (color: 0xFF6A1B9A, name: _purple),
  (color: 0xFF4527A0, name: _violet),
  (color: 0xFF283593, name: _indigo),
  (color: 0xFF1565C0, name: _blue),
  (color: 0xFF00838F, name: _cyan),
  (color: 0xFF00695C, name: _teal),
  (color: 0xFF2E7D32, name: _green),
  (color: 0xFFEF6C00, name: _orange),
  (color: 0xFF5D4037, name: _brown),
  (color: 0xFF616161, name: _grey),
];

String _red(AppLocalizations l) => l.colorRed;
String _pink(AppLocalizations l) => l.colorPink;
String _purple(AppLocalizations l) => l.colorPurple;
String _violet(AppLocalizations l) => l.colorViolet;
String _indigo(AppLocalizations l) => l.colorIndigo;
String _blue(AppLocalizations l) => l.colorBlue;
String _cyan(AppLocalizations l) => l.colorCyan;
String _teal(AppLocalizations l) => l.colorTeal;
String _green(AppLocalizations l) => l.colorGreen;
String _orange(AppLocalizations l) => l.colorOrange;
String _brown(AppLocalizations l) => l.colorBrown;
String _grey(AppLocalizations l) => l.colorGrey;

/// The editor of category [categoryId], or of a new category when it is null.
class CategoryEditorScreen extends ConsumerWidget {
  const CategoryEditorScreen({super.key, this.categoryId});

  final String? categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!ref.watch(categoriesProvider).hasValue) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final String? id = categoryId;
    if (id == null) return const _CategoryForm(initial: null);
    final Category? category = ref.watch(categoriesByIdProvider)[id];
    if (category == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.categoryNotFound)),
      );
    }
    return _CategoryForm(key: ValueKey(id), initial: category);
  }
}

class _CategoryForm extends ConsumerStatefulWidget {
  const _CategoryForm({super.key, required this.initial});

  /// The category being edited, or null for a new one.
  final Category? initial;

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  /// What the form edits: the screen's entity, or once a save has landed, the saved
  /// one, so a later Save rewrites it rather than creating another.
  late Category? _initial = widget.initial;

  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: _initial?.name,
  );
  late String? _parentId = _initial?.parentId;
  late String _icon = _initial?.icon ?? categoryIcons.first.key;
  late int _color = _initial?.color ?? categoryPalette.first.color;
  bool _saving = false;

  bool get _isSystem => _initial?.isSystem ?? false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final CategoryActions actions = ref.read(categoryActionsProvider);
    final OwnPage page = OwnPage.of(context);
    setState(() => _saving = true);
    try {
      final Category? initial = _initial;
      final Category saved;
      if (initial == null) {
        saved = await actions.create(
          name: _name.text.trim(),
          parentId: _parentId,
          icon: _icon,
          color: _color,
        );
      } else {
        saved = _isSystem
            ? initial.copyWith(icon: _icon, color: _color)
            : initial.copyWith(
                name: _name.text.trim(),
                parentId: _parentId,
                icon: _icon,
                color: _color,
              );
        await actions.update(saved);
      }
      if (mounted) setState(() => _initial = saved);
      page.close();
    } on CategoryNotEditableException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.categorySystemReadOnly)),
      );
    } on EntityDeletedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.categoryNotFound)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(List<Category> children) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final CategoryActions actions = ref.read(categoryActionsProvider);
    final Category category = _initial!;
    final OwnPage page = OwnPage.of(context);
    final int count = await actions.transactionCount({
      category.id,
      for (final Category c in children) c.id,
    });
    if (!mounted) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.categoryDeleteTitle(category.name)),
        content: Text(
          children.isEmpty
              ? l10n.categoryDeleteBody(count)
              : l10n.categoryDeleteWithChildrenBody(children.length, count),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    page.close();
    try {
      await actions.delete(category.id);
    } on CategoryNotDeletableException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.categorySystemReadOnly)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Category? initial = _initial;
    final List<CategoryGroup> tree = ref.watch(categoryTreeProvider);
    final List<Category> children = [
      for (final CategoryGroup group in tree)
        if (group.primary.id == initial?.id) ...group.children,
    ];
    // Two levels only: a category with children stays at the top level.
    final bool parentEditable = !_isSystem && children.isEmpty;
    final List<Category> parents = [
      for (final CategoryGroup group in tree)
        if (group.primary.id != initial?.id) group.primary,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          initial == null ? l10n.categoryNewTitle : l10n.categoryEditTitle,
        ),
        actions: [
          if (initial != null && !_isSystem)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : () => _delete(children),
            ),
          TextButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isSystem)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.categorySystemNote,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            TextFormField(
              controller: _name,
              enabled: !_isSystem,
              autofocus: initial == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.categoryName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.categoryNameRequired
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: parents.any((p) => p.id == _parentId)
                  ? _parentId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.categoryParent,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.categoryParentNone),
                ),
                for (final Category parent in parents)
                  DropdownMenuItem<String?>(
                    value: parent.id,
                    child: Text(parent.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: parentEditable
                  ? (id) => setState(() => _parentId = id)
                  : null,
            ),
            const SizedBox(height: 24),
            Text(l10n.categoryIcon, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final CategoryIconOption option in categoryIcons)
                  IconButton(
                    tooltip: option.label(l10n),
                    isSelected: option.key == _icon,
                    style: IconButton.styleFrom(
                      backgroundColor: option.key == _icon
                          ? theme.colorScheme.secondaryContainer
                          : null,
                    ),
                    icon: Icon(
                      option.icon,
                      color: categoryColor(context, _color),
                    ),
                    onPressed: () => setState(() => _icon = option.key),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(l10n.categoryColor, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final swatch in categoryPalette)
                  _Swatch(
                    color: Color(swatch.color),
                    label: swatch.name(l10n),
                    selected: swatch.color == _color,
                    onTap: () => setState(() => _color = swatch.color),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                : null,
          ),
          child: selected ? const Icon(Icons.check, color: Colors.white) : null,
        ),
      ),
    );
  }
}
