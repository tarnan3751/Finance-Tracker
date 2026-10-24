/// The [LinkLauncher] of the tests, the demo flavor and `FT_FAKE_SERVER`: no Link UI. It
/// completes at once with the public token the in-app fake server hands out for the link
/// token (`FakeServer.completeLink`): the next dataset Item the user has not linked, or,
/// for an update-mode token, the repaired Item, standing in for Plaid's side of Link.
library;

import 'dart:async';

import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/features/items/domain/link_launcher.dart';

/// A launcher over [server]. Tests script it with [exitNext] and [hold].
final class FakeLinkLauncher implements LinkLauncher {
  /// A launcher over [server].
  FakeLinkLauncher(this.server);

  final FakeServer server;
  final List<LinkExited> _exits = [];
  bool _open = false;

  /// When set, each open waits for it before completing (a Link session the user has not
  /// finished).
  Completer<void>? hold;

  /// How many times Link was opened.
  int opened = 0;

  /// The next open exits, on the user's own when [error] is null.
  void exitNext([LinkExitError? error]) => _exits.add(LinkExited(error));

  @override
  Future<LinkResult> open(String linkToken) async {
    if (_open) throw StateError('Plaid Link is already open');
    _open = true;
    opened++;
    try {
      await hold?.future;
      if (_exits.isNotEmpty) return _exits.removeAt(0);
      final FakeLink link = server.completeLink(linkToken);
      return LinkSucceeded(
        link.publicToken,
        institution: (id: link.institution.id, name: link.institution.name),
      );
    } finally {
      _open = false;
    }
  }
}
