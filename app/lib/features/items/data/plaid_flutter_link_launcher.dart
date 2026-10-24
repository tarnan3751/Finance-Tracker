/// The [LinkLauncher] of the dev and prod flavors: Plaid Link through `plaid_flutter`
/// 5.2.1 (`PlaidLink.create` with the link token, then `PlaidLink.open`; the outcome
/// arrives on the plugin's static `onSuccess` and `onExit` streams).
library;

import 'dart:async';

import 'package:finance_tracker/features/items/domain/link_launcher.dart';
import 'package:flutter/services.dart';
import 'package:plaid_flutter/plaid_flutter.dart' as plaid;

/// Plaid Link. One session at a time; each open listens to the plugin's streams from
/// before Link is created until its outcome, then stops.
final class PlaidFlutterLinkLauncher implements LinkLauncher {
  bool _open = false;

  @override
  Future<LinkResult> open(String linkToken) async {
    if (_open) throw StateError('Plaid Link is already open');
    _open = true;
    final Completer<LinkResult> outcome = Completer<LinkResult>();
    void complete(LinkResult result) {
      if (!outcome.isCompleted) outcome.complete(result);
    }

    final List<StreamSubscription<Object>> subscriptions = [
      plaid.PlaidLink.onSuccess.listen((plaid.LinkSuccess success) {
        final plaid.LinkInstitution? institution = success.metadata.institution;
        complete(
          LinkSucceeded(
            success.publicToken,
            institution: institution == null
                ? null
                : (id: institution.id, name: institution.name),
          ),
        );
      }),
      plaid.PlaidLink.onExit.listen((plaid.LinkExit exit) {
        final plaid.LinkError? error = exit.error;
        complete(
          LinkExited(
            error == null
                ? null
                : LinkExitError(
                    code: error.code,
                    type: error.type,
                    displayMessage: error.displayMessage,
                  ),
          ),
        );
      }),
    ];
    try {
      await plaid.PlaidLink.create(
        configuration: plaid.LinkTokenConfiguration(token: linkToken),
      );
      await plaid.PlaidLink.open();
      return await outcome.future;
    } on PlatformException {
      // Link could not open (no activity attached, the native SDK refused the token).
      return const LinkExited(
        LinkExitError(code: 'platform_error', type: 'platform'),
      );
    } finally {
      for (final StreamSubscription<Object> s in subscriptions) {
        await s.cancel();
      }
      _open = false;
    }
  }
}
