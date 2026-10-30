/// The platform boundary for the links the app is opened at (`docs/reference/app-core.md`,
/// **Launch links**): a home screen widget's tap or an app shortcut starts or resumes the
/// app at a `financetracker://` link, which the router turns into a location
/// (`core/router/launch_links.dart`). [initial] is the link of a cold start, read once
/// before the router is built so it opens there; [opened] the links that reach the
/// running app (`MainActivity`'s `onNewIntent`), so a second tap after backgrounding goes
/// where it says. Behind it in every flavor, `home_widget`'s launch action; a fake stands
/// in for the tests. Pure Dart, no Flutter import.
library;

/// Where the app is asked to open.
abstract interface class LaunchIntent {
  /// The link the app was started at, or null for a plain start. Call once, before
  /// listening to [opened].
  Future<Uri?> initial();

  /// The links that arrive while the app runs.
  Stream<Uri> get opened;
}
