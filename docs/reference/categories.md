# Categories

Category management (Settings, Data, Categories), the category editor, and the category
picker the transaction editor and the filter sheet use. Code:
`app/lib/features/categories/` (`application/`, `presentation/`; the repository and the
seeded system categories are `data.md`'s). Tests: `app/test/features/categories/`.

## Providers

`application/categories_providers.dart`: `categoriesProvider` (`watchAll()`),
`categoriesByIdProvider`, `categoryTreeProvider` (each top-level category with the
categories under it; a child whose parent is not live shows at the top level), and
`categoryActionsProvider` (`create`, `update`, `transactionCount`, `delete`).

## Screens

- **List** (`categories_screen.dart`). The top-level categories, each expandable to the
  categories under it; system categories carry a lock icon labelled "Built-in category".
  The search field lists matches at every level with their parent's name. "Add category".
- **Editor** (`category_editor_screen.dart`). Name, parent ("Nothing (top level)" or any
  top-level category; a category with children stays at the top level, so the hierarchy
  keeps two levels), an icon from `category_icons.dart` and a color from the twelve
  swatches of `categoryPalette`. A system category changes only its icon and color (the
  other fields are disabled; the repository's `CategoryNotEditableException` is explained
  if it is ever raised). Delete, for user categories only, confirms with the number of
  live transactions filed under the category or its children (directly or by a split),
  then deletes it and its children.
- **Picker** (`category_picker.dart`). See `transactions.md`.

## Icons and colors

`Category.icon` is a key: the name of a Material icon. `categoryIcons` is the curated set,
about forty, each with a localized label; it holds every key the system categories use.
An unknown key draws `fallbackCategoryIcon`. In the dark theme `categoryColor` lightens the
stored color so the deep palette stays visible.

## Uncategorized

Deleting a category leaves its transactions' `userCategoryId` as it is (`data.md`,
**Categories**); every screen shows a transaction whose category is null, deleted or
unknown as "Uncategorized".
