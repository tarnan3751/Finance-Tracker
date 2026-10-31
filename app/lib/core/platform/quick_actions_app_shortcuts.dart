/// The [AppShortcuts] of every flavor on a device: `quick_actions`' dynamic shortcuts,
/// each typed by its launch link, which `PlatformLaunchIntent` reads back when one is
/// chosen.
library;

import 'package:finance_tracker/core/platform/app_shortcuts.dart';
import 'package:quick_actions/quick_actions.dart';

/// The app shortcuts through `quick_actions`.
final class QuickActionsAppShortcuts implements AppShortcuts {
  const QuickActionsAppShortcuts();

  @override
  Future<void> set(List<AppShortcut> shortcuts) =>
      const QuickActions().setShortcutItems([
        for (final AppShortcut s in shortcuts)
          ShortcutItem(
            type: s.link.toString(),
            localizedTitle: s.title,
            icon: s.icon,
          ),
      ]);
}
