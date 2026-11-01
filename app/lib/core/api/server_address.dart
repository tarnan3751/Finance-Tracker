/// The server the API talks to (`docs/reference/onboarding.md`, **The server URL**): the
/// one compiled into the build (`AppConfig.serverBaseUrl`, `FT_SERVER_URL`), or else the
/// one entered on the sign-in or registration screen, which the device keeps
/// (`server_url`, `core/config/app_mode_store.dart`) and `startApp` reads back
/// (`AppConfig.enteredServerUrl`). The network client reads [ServerAddress.current] for
/// every request (`api_config.dart`), so an address entered while the app runs needs no
/// new client. A compiled URL wins and cannot be changed; over the in-app fake server the
/// address is the fake's, fixed the same way.
///
/// [checkServerUrl] is the entered address's rule: an absolute `http` or `https` URL with
/// a host and nothing after its path, and `https` only in prod.
library;

import 'package:finance_tracker/core/config/app_config.dart';

/// The API's server.
final class ServerAddress {
  ServerAddress({this.compiled, this.entered});

  /// The compiled URL (or the fake server's), or null.
  final Uri? compiled;

  /// The entered URL, or null; set when one is entered (storing it is the caller's).
  Uri? entered;

  /// Whether the address is entered by the user: no URL is compiled in.
  bool get editable => compiled == null;

  /// The server requests go to, or null when there is none yet.
  Uri? get current => compiled ?? entered;
}

/// What is wrong with an entered server URL.
enum ServerUrlProblem {
  /// Nothing entered.
  empty,

  /// Not an absolute `http` or `https` URL with a host and no spaces, user, query or
  /// fragment.
  invalid,

  /// Not `https`, in a build that needs it.
  notHttps,
}

/// The server URL [text] gives for [flavor], or the [ServerUrlProblem] with it.
({Uri? url, ServerUrlProblem? problem}) checkServerUrl(
  String text,
  Flavor flavor,
) {
  final String trimmed = text.trim();
  if (trimmed.isEmpty) return (url: null, problem: ServerUrlProblem.empty);
  final Uri? url = Uri.tryParse(trimmed);
  if (url == null ||
      trimmed.contains(RegExp(r'\s')) ||
      !(url.scheme == 'http' || url.scheme == 'https') ||
      url.host.isEmpty ||
      url.userInfo.isNotEmpty ||
      url.hasQuery ||
      url.hasFragment) {
    return (url: null, problem: ServerUrlProblem.invalid);
  }
  if (flavor == Flavor.prod && url.scheme != 'https') {
    return (url: null, problem: ServerUrlProblem.notHttps);
  }
  return (url: url, problem: null);
}
