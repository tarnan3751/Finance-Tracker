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
  The app bar's menu opens the rules (`rules.md`).
- **Editor** (`category_editor_screen.dart`). Name, parent ("Nothing (top level)" or any
  top-level category; a category with children stays at the top level, so the hierarchy
  keeps two levels), an icon from `category_icons.dart` and a color from the twelve
  swatches of `categoryPalette`. A system category changes only its icon and color (the
  other fields are disabled; the repository's `CategoryNotEditableException` is explained
  if it is ever raised). Delete, for user categories only, confirms with the number of
  live transactions filed under the category or its children (directly or by a split),
  then deletes it and its children.
- **Picker** (`category_picker.dart`). See `transactions.md`. The rule editor opens it
  without "None", and with `systemOnly` for a bank category condition, which lists only
  the categories with a Plaid code.

## Icons and colors

`Category.icon` is a key: the name of a Material icon. `categoryIcons` is the curated set,
about forty, each with a localized label; it holds every key the system categories use.
An unknown key draws `fallbackCategoryIcon`. A category's color as every screen draws it
is `categoryColorOf`: a system category still in its default taxonomy color takes the
brand's hue for its primary (`brandHues`, `core/theme/brand_hues.dart`, eight hues from the inks, assigned so
that neighbouring top-level categories differ in Plaid's order and by name, lifted on the
night print); any other color, one the user chose (on a user category or a system one),
stays as chosen: lightened in the dark theme by `categoryColor` so the deep palette stays
visible, and harmonized with the scheme's primary (`FinanceColors.custom`). The stored
colors do not change, so nothing syncs. Lists show the icon in that color on a disc of
its 20 % tint over `surfaceContainer` (`CategoryIconDisc`), the icon in the hue's
text-safe variant (a color the user chose moved until it reaches 3:1 on its disc); the budget cards and the
report's donut draw the same color.

## Uncategorized

Deleting a category leaves its transactions' `userCategoryId` as it is (`data.md`,
**Categories**). A transaction whose category is null, deleted or unknown shows the system
category of its Plaid code (`transactions.md`, **The effective category**), and is
"Uncategorized" when that resolves to none either. The "will become uncategorized" counts
count `userCategoryId` only.
