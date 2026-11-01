/// The in-app help's sections, in the order the Help screen lists them
/// (`docs/reference/onboarding.md`, **Help**), each with the slug of its route
/// (`/settings/help/<slug>`). Pure Dart.
library;

/// A section of the help.
enum HelpSection {
  gettingStarted('getting-started'),
  accounts('accounts'),
  transactions('transactions'),
  budgets('budgets'),
  bills('bills'),
  forecast('forecast'),
  insights('insights'),
  sync('sync'),
  backupSecurity('backup-security'),
  widgets('widgets'),
  notifications('notifications');

  const HelpSection(this.slug);

  /// The section's part of its route.
  final String slug;

  /// The section whose slug is [slug], or null.
  static HelpSection? fromSlug(String slug) =>
      values.where((s) => s.slug == slug).firstOrNull;
}
