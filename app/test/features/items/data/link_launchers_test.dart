// The two Link launchers. The plaid_flutter one over a scripted platform: success with
// the institution, an exit with and without an error, Link failing to open, the
// subscriptions gone after each open, and one session at a time. The fake one over the
// in-app fake server: the next Item the user has not linked, the update-mode token, an
// unknown token, a scripted exit and a held session.
import 'dart:async';

import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/features/items/data/fake_link_launcher.dart';
import 'package:finance_tracker/features/items/data/plaid_flutter_link_launcher.dart';
import 'package:finance_tracker/features/items/domain/link_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaid_flutter/plaid_flutter.dart' as plaid;
import 'package:shared_models/shared_models.dart';

import '../../../core/api/support/fake_api.dart';

/// A platform that answers each open with the next scripted outcome.
final class _Platform extends plaid.PlaidPlatformInterface {
  final StreamController<plaid.LinkObject> events =
      StreamController<plaid.LinkObject>.broadcast();
  final List<plaid.LinkObject Function()> outcomes = [];
  final List<String> created = [];
  bool failOpen = false;
  Completer<void>? hold;

  @override
  Stream<plaid.LinkObject> get onObject => events.stream;

  @override
  Future<void> create({
    required plaid.LinkTokenConfiguration configuration,
  }) async => created.add(configuration.token);

  @override
  Future<void> open() async {
    if (failOpen) throw PlatformException(code: 'PlaidFlutter');
    final plaid.LinkObject outcome = outcomes.removeAt(0)();
    unawaited(
      (hold?.future ?? Future<void>.value()).then((_) => events.add(outcome)),
    );
  }
}

plaid.LinkSuccess _success() => plaid.LinkSuccess(
  publicToken: 'public-sandbox-1',
  metadata: plaid.LinkSuccessMetadata(
    linkSessionId: 's1',
    institution: plaid.LinkInstitution(
      id: 'ins_109508',
      name: 'First Platypus Bank',
    ),
    accounts: const [],
  ),
);

plaid.LinkExit _exit([plaid.LinkError? error]) => plaid.LinkExit(
  error: error,
  metadata: plaid.LinkExitMetadata(
    status: 'requires_credentials',
    requestId: null,
    linkSessionId: 's1',
    institution: null,
  ),
);

FakeItemData _item(String id, String institution) => FakeItemData(
  id: id,
  institution: Institution(id: 'ins-$id', name: institution),
  accounts: [
    Account(
      id: '$id-checking',
      itemId: id,
      type: AccountType.depository,
      name: 'Checking',
      currencyCode: 'USD',
      isHidden: false,
      displayOrder: 0,
    ),
  ],
);

void main() {
  group('PlaidFlutterLinkLauncher', () {
    late _Platform platform;
    late PlaidFlutterLinkLauncher launcher;

    setUp(() {
      platform = _Platform();
      plaid.PlaidPlatformInterface.instance = platform;
      launcher = PlaidFlutterLinkLauncher();
    });

    test('a success carries the public token and the institution', () async {
      platform.outcomes.add(_success);
      final LinkResult result = await launcher.open('link-1');
      expect(platform.created, ['link-1']);
      expect(result, isA<LinkSucceeded>());
      final LinkSucceeded success = result as LinkSucceeded;
      expect(success.publicToken, 'public-sandbox-1');
      expect(success.institution, (
        id: 'ins_109508',
        name: 'First Platypus Bank',
      ));
      expect(success.toString(), isNot(contains('public-sandbox-1')));
      expect(platform.events.hasListener, isFalse);
    });

    test('an exit, on the user\'s own or with an error', () async {
      platform.outcomes
        ..add(_exit)
        ..add(
          () => _exit(
            plaid.LinkError(
              code: 'INVALID_CREDENTIALS',
              type: 'ITEM_ERROR',
              message: 'the credentials were not correct',
              displayMessage: 'The credentials were not correct.',
            ),
          ),
        );
      expect(((await launcher.open('link-1')) as LinkExited).error, isNull);
      expect(
        ((await launcher.open('link-2')) as LinkExited).error,
        const LinkExitError(
          code: 'INVALID_CREDENTIALS',
          type: 'ITEM_ERROR',
          displayMessage: 'The credentials were not correct.',
        ),
      );
      expect(platform.events.hasListener, isFalse);
    });

    test('Link that cannot open is an exit with a platform error', () async {
      platform.failOpen = true;
      final LinkResult result = await launcher.open('link-1');
      expect((result as LinkExited).error!.code, 'platform_error');
      expect(platform.events.hasListener, isFalse);
    });

    test('one session at a time', () async {
      platform
        ..hold = Completer<void>()
        ..outcomes.add(_success);
      final Future<LinkResult> first = launcher.open('link-1');
      await pumpEventQueue();
      await expectLater(launcher.open('link-2'), throwsStateError);
      platform.hold!.complete();
      expect(await first, isA<LinkSucceeded>());
      platform.outcomes.add(_exit);
      expect(await launcher.open('link-3'), isA<LinkExited>());
    });
  });

  group('FakeLinkLauncher', () {
    late FakeServer server;
    late FakeClient client;
    late FakeLinkLauncher launcher;

    setUp(() {
      server = newFakeServer(
        dataset: FakeDataset(
          items: [_item('item-a', 'Bank A'), _item('item-b', 'Bank B')],
        ),
      );
      client = FakeClient.signedIn(server);
      launcher = FakeLinkLauncher(server);
    });

    Future<String> token({String? update}) async => update == null
        ? (await client.api.createLinkToken(
            androidPackageName: 'dev.tarnan.financetracker',
          )).linkToken
        : (await client.api.createUpdateLinkToken(
            update,
            androidPackageName: 'dev.tarnan.financetracker',
          )).linkToken;

    test('links the next Item the user has not linked', () async {
      final LinkSucceeded first =
          (await launcher.open(await token())) as LinkSucceeded;
      expect(first.publicToken, 'public-demo-item-a');
      expect(first.institution, (id: 'ins-item-a', name: 'Bank A'));
      await client.api.exchangePublicToken(first.publicToken);
      final LinkSucceeded second =
          (await launcher.open(await token())) as LinkSucceeded;
      expect(second.publicToken, 'public-demo-item-b');
      await client.api.exchangePublicToken(second.publicToken);
      final LinkSucceeded again =
          (await launcher.open(await token())) as LinkSucceeded;
      expect(again.publicToken, 'public-demo-item-a', reason: 'all linked');
    });

    test('an update-mode token gives the update token of its Item', () async {
      await client.api.exchangePublicToken('public-demo-item-b');
      final LinkSucceeded result =
          (await launcher.open(await token(update: 'item-b'))) as LinkSucceeded;
      expect(result.publicToken, 'public-demo-update-item-b');
      expect(launcher.opened, 1);
    });

    test('a link token the server did not hand out is an error', () async {
      await expectLater(launcher.open('link-unknown'), throwsArgumentError);
    });

    test('a scripted exit, and one session at a time', () async {
      launcher.exitNext();
      expect(
        await launcher.open(await token()),
        const TypeMatcher<LinkExited>(),
      );
      launcher.hold = Completer<void>();
      final String t = await token();
      final Future<LinkResult> held = launcher.open(t);
      await expectLater(launcher.open(t), throwsStateError);
      launcher.hold!.complete();
      expect(await held, isA<LinkSucceeded>());
    });
  });
}
