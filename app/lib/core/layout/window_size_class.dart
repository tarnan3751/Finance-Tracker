/// The window size classes of the Material 3 and Android guidance, by width
/// (`PLAN.md` §8, Phase 8): compact below 600 dp (a phone held upright, a
/// folded foldable), medium from 600 to 839 dp (a phone on its side, a small tablet or
/// an unfolded foldable upright), expanded from 840 dp (a tablet, an unfolded foldable
/// on its side). The shell computes the class once, from its own width, which is the
/// window's, and lays out its navigation and its panes for it (`app_shell.dart`);
/// nothing else reads the window's size to choose a layout.
library;

/// A window's width class.
enum WindowSizeClass {
  /// Narrower than 600 dp.
  compact,

  /// From 600 dp to narrower than 840 dp.
  medium,

  /// 840 dp and wider.
  expanded;

  /// The class of a window [width] logical pixels wide.
  static WindowSizeClass fromWidth(double width) => width < 600
      ? compact
      : width < 840
      ? medium
      : expanded;
}
