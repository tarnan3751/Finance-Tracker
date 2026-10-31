/// The platform boundary for the app shortcuts (`docs/reference/app-core.md`, **Launch
/// links**): the launcher's long-press menu on the app's icon. Each [AppShortcut] opens the
/// app at its launch link, which reaches the router through the `LaunchIntent` seam.
/// `quick_actions`' dynamic shortcuts are behind it in every flavor; a fake that records
/// stands in for the tests. Pure Dart, no Flutter import.
library;

/// One app shortcut: [title] beside the drawable resource [icon], opening [link].
final class AppShortcut {
  const AppShortcut({
    required this.link,
    required this.title,
    required this.icon,
  });

  final Uri link;
  final String title;
  final String icon;

  @override
  bool operator ==(Object other) =>
      other is AppShortcut &&
      other.link == link &&
      other.title == title &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(link, title, icon);

  @override
  String toString() => 'AppShortcut($link, $title, $icon)';
}

/// Sets the app's shortcuts.
abstract interface class AppShortcuts {
  /// Makes [shortcuts] the app's shortcuts, in order, replacing any before.
  Future<void> set(List<AppShortcut> shortcuts);
}
