/// The messenger a snack bar raised after an await goes to (`app-core.md`, **Snack
/// bars**).
///
/// A screen that shows a message once an awaited write has landed takes its messengers
/// with [VisibleMessenger.of] before the await, as an editor takes its page with
/// `OwnPage.of`, since its context may be gone by then. While the screen stays (a save
/// refused, a removal that failed) the message goes to its own pane's messenger
/// ([VisibleMessenger.pane]): the tab's, or the list's own beside a detail (`TwoPane`).
/// Once the screen has closed (a delete's Undo) it goes to the messenger of the tab
/// selected when the message is shown ([VisibleMessenger.afterClose]), which the shell
/// provides ([SelectedTabMessenger]), so a message is never left on a messenger whose
/// screens are offstage or gone.
library;

import 'package:flutter/material.dart';

/// The messenger of the shell's selected tab, read when it is asked for. Provided by
/// `AppShell` above its branches.
class SelectedTabMessenger extends InheritedWidget {
  const SelectedTabMessenger({
    super.key,
    required this.current,
    required super.child,
  });

  /// The selected tab's messenger now, or null before it is built.
  final ScaffoldMessengerState? Function() current;

  @override
  bool updateShouldNotify(SelectedTabMessenger oldWidget) => false;
}

/// The messengers a screen shows a message on after an await, taken before it.
final class VisibleMessenger {
  /// The messengers of the screen [context] is in.
  VisibleMessenger.of(BuildContext context)
    : pane = ScaffoldMessenger.of(context),
      _tab = context
          .getInheritedWidgetOfExactType<SelectedTabMessenger>()
          ?.current;

  /// The messenger of the pane the screen is in, for a message while it stays.
  final ScaffoldMessengerState pane;

  final ScaffoldMessengerState? Function()? _tab;

  /// The messenger of the tab selected now, for a message once the screen has closed;
  /// outside the shell, the pane's.
  ScaffoldMessengerState get afterClose => _tab?.call() ?? pane;
}
