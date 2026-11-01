/// The server the API talks to (`docs/reference/onboarding.md`, **The server URL**): the
/// one compiled into the build (`AppConfig.serverBaseUrl`, `FT_SERVER_URL`), or else the
/// one entered on the sign-in or registration screen, which the device keeps
/// (`server_url`, `core/config/app_mode_store.dart`) and `startApp` reads back
/// (`AppConfig.enteredServerUrl`). The network client reads [ServerAddress.current] for
/// every request (`api_config.dart`), so an address entered while the app runs needs no
/// new client. A compiled URL wins and cannot be changed; over the in-app fake server the
/// address is the fake's, fixed the same way.
library;

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
