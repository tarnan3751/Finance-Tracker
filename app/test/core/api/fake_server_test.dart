// The in-app fake server through the real client stack: the dev server's auth rules
// (rotation, reuse detection, the live-family bearer check, devices, account deletion),
// the sync relay's rules, the Plaid proxy and the data pages over the dataset, the
// failure hooks, and the boundary conversions of HttpFinanceApi on the way back.
import 'dart:typed_data';

import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import 'support/fake_api.dart';

ChangeLogEntry _entry(
  String deviceId,
  int wall, {
  String id = 'cat-1',
  Map<String, dynamic>? payload,
  ChangeOperation operation = ChangeOperation.create,
  String? node,
}) => ChangeLogEntry(
  entityType: EntityType.category,
  entityId: id,
  operation: operation,
  payload: payload ?? {'name': 'Coffee', 'sort': 3},
  hlc: Hlc(wall, 0, node ?? deviceId),
  deviceId: deviceId,
  synced: false,
);

void main() {
  late FakeServer server;
  setUp(() => server = newFakeServer());

  group('auth', () {
    test('register, then log in on a second device, then /me', () async {
      final FakeClient client = FakeClient(server);
      final AuthResult registered = await client.api.register(
        email: 'Ada@Example.com',
        password: 'correct horse',
        deviceName: 'Pixel 6',
      );
      expect(registered.accessExpiresIn, const Duration(minutes: 15));
      expect(registered.device.name, 'Pixel 6');

      final AuthResult second = await client.api.login(
        email: 'ada@example.com',
        password: 'correct horse',
        deviceName: 'Tablet',
      );
      expect(second.device.id, isNot(registered.device.id));
      final User me = await client.api.getMe(accessToken: second.accessToken);
      expect(me.email, 'ada@example.com');
      expect(me.displayName, 'ada');
      expect(me.id, second.device.userId);
    });

    test('the documented errors', () async {
      final FakeClient client = FakeClient.signedIn(server);
      await expectLater(
        client.api.register(
          email: 'ada@example.com',
          password: 'another pass',
          deviceName: 'x',
        ),
        throwsA(isA<EmailTaken>()),
      );
      await expectLater(
        client.api.login(
          email: 'ada@example.com',
          password: 'wrong password',
          deviceName: 'x',
        ),
        throwsA(isA<InvalidCredentials>()),
      );
      await expectLater(
        client.api.register(
          email: 'not-an-email',
          password: 'short',
          deviceName: 'x',
        ),
        throwsA(
          isA<ValidationFailed>().having(
            (e) => e.errors.map((f) => f.field),
            'fields',
            ['email', 'password'],
          ),
        ),
      );
    });

    test(
      'refresh rotates; reusing a rotated token revokes the family',
      () async {
        final FakeClient client = FakeClient.signedIn(server);
        final String first = client.session.refreshToken;
        final AuthResult rotated = await client.api.refreshTokens(first);
        expect(rotated.refreshToken, isNot(first));

        await expectLater(
          client.api.refreshTokens(first),
          throwsA(isA<TokenRevoked>()),
        );
        // The whole family went, the newest token included.
        await expectLater(
          client.api.refreshTokens(rotated.refreshToken),
          throwsA(isA<TokenRevoked>()),
        );
      },
    );

    test('an expired access token is refreshed once, transparently', () async {
      final FakeClient client = FakeClient.signedIn(server);
      final String access = client.session.accessToken;
      server.advanceClock(const Duration(minutes: 16));
      final List<User> users = await Future.wait([
        for (int i = 0; i < 5; i++) client.api.getMe(),
      ]);
      expect(users.map((u) => u.email).toSet(), {'ada@example.com'});
      expect(server.calls.where((c) => c == 'refreshTokens'), hasLength(1));
      expect(client.session.accessToken, isNot(access));
    });

    test('a reused refresh token signs the device out', () async {
      final FakeClient client = FakeClient.signedIn(server);
      int ended = 0;
      client.api.sessionEnded.listen((_) => ended++);
      // A refresh whose answer was lost: the server rotated, the client kept the old.
      await client.api.refreshTokens(client.session.refreshToken);
      server.advanceClock(const Duration(minutes: 16));

      await expectLater(client.api.getMe(), throwsA(isA<TokenRevoked>()));
      expect(client.store.session, isNull);
      expect(ended, 1);
    });

    test('logout and device removal end access tokens at once', () async {
      final FakeClient client = FakeClient.signedIn(server);
      final FakeClient other = FakeClient.signedIn(
        server,
        deviceName: 'Tablet',
      );
      expect(await client.api.listDevices(), hasLength(2));

      await other.api.logout(other.session.refreshToken);
      await expectLater(other.api.getMe(), throwsA(isA<TokenRevoked>()));
      expect((await client.api.listDevices()).map((d) => d.name), ['Pixel 6']);

      final FakeClient stranger = FakeClient.signedIn(
        server,
        email: 'bob@example.com',
      );
      await expectLater(
        stranger.api.deleteDevice(client.session.deviceId),
        throwsA(isA<NotFound>()),
      );
      await client.api.deleteDevice(client.session.deviceId);
      await expectLater(client.api.getMe(), throwsA(isA<TokenRevoked>()));
    });

    test('logout refuses another device token', () async {
      final FakeClient client = FakeClient.signedIn(server);
      final FakeClient other = FakeClient.signedIn(
        server,
        deviceName: 'Tablet',
      );
      await expectLater(
        client.api.logout(other.session.refreshToken),
        throwsA(isA<TokenRevoked>()),
      );
    });

    test('a missing or unknown token is invalid_credentials', () async {
      final FakeClient anonymous = FakeClient(server);
      await expectLater(
        anonymous.api.getMe(),
        throwsA(isA<InvalidCredentials>()),
      );
      await expectLater(
        anonymous.api.getMe(accessToken: 'made-up'),
        throwsA(isA<InvalidCredentials>()),
      );
    });

    test('DELETE /me removes the user and every session', () async {
      final FakeClient client = FakeClient.signedIn(server);
      await client.api.deleteMe();
      await expectLater(client.api.getMe(), throwsA(isA<TokenRevoked>()));
      await expectLater(
        client.api.login(
          email: 'ada@example.com',
          password: 'correct horse',
          deviceName: 'x',
        ),
        throwsA(isA<InvalidCredentials>()),
      );
    });
  });

  group('sync relay', () {
    final int wall = fakeNow.millisecondsSinceEpoch;

    test('entries reach the user other devices, never their own', () async {
      final FakeClient a = FakeClient.signedIn(server);
      final FakeClient b = FakeClient.signedIn(server, deviceName: 'Tablet');
      final ChangeLogEntry entry = _entry(a.session.deviceId, wall);

      final PushResult pushed = await a.api.pushChanges([entry]);
      expect(pushed.accepted, [entry.hlc]);
      expect(pushed.rejected, isEmpty);

      final PullPage own = await a.api.pullChanges(since: 0, limit: 500);
      expect(own.entries, isEmpty);
      expect(own.nextSince, 1);

      final PullPage pulled = await b.api.pullChanges(since: 0, limit: 500);
      expect(pulled.entries, [entry.copyWith(synced: true)]);
      expect(pulled.entries.single.payload['sort'], isA<int>());
      expect(pulled.nextSince, 1);
      expect(pulled.hasMore, isFalse);

      final FakeClient stranger = FakeClient.signedIn(
        server,
        email: 'bob@example.com',
      );
      expect(
        (await stranger.api.pullChanges(since: 0, limit: 500)).entries,
        isEmpty,
      );
    });

    test('each rejection code', () async {
      final FakeClient a = FakeClient.signedIn(server);
      final String device = a.session.deviceId;
      final ChangeLogEntry stored = _entry(device, wall);
      await a.api.pushChanges([stored]);

      final PushResult result = await a.api.pushChanges([
        _entry('someone-else', wall + 1),
        _entry(device, wall + 2, payload: {'source': 'plaid', 'name': 'x'}),
        _entry(device, wall + 3, node: 'another-node'),
        _entry(device, wall + const Duration(hours: 2).inMilliseconds),
        _entry(device, wall, payload: {'name': 'Tea'}),
        stored,
      ]);
      expect(result.accepted, [stored.hlc]);
      expect(result.rejected.map((r) => r.reason), [
        PushRejectionReason.invalid,
        PushRejectionReason.invalid,
        PushRejectionReason.invalid,
        PushRejectionReason.clockDrift,
        PushRejectionReason.conflictingDuplicate,
      ]);
    });

    test('a cursor past the end is sync_cursor_invalid', () async {
      final FakeClient a = FakeClient.signedIn(server);
      await expectLater(
        a.api.pullChanges(since: 9, limit: 500),
        throwsA(isA<SyncCursorInvalid>().having((e) => e.since, 'since', 9)),
      );
    });
  });

  group('plaid and data', () {
    test('link, not_ready, completed, then the data as demo', () async {
      final FakeClient client = FakeClient.signedIn(server);
      final LinkToken link = await client.api.createLinkToken(
        androidPackageName: 'dev.tarnan.financetracker',
      );
      expect(link.expiration, fakeNow.add(const Duration(hours: 4)));

      final LinkedItem linked = await client.api.exchangePublicToken(
        'public-sandbox-anything',
      );
      expect(linked.item.id, 'sample-item-1');
      expect(linked.institution.name, 'First Platypus Bank');
      expect(await client.api.listAccounts(), isEmpty);

      expect(
        (await client.api.syncItem(linked.item.id)).status,
        SyncRunStatus.notReady,
      );
      final SyncRun run = await client.api.syncItem(linked.item.id);
      expect(run.status, SyncRunStatus.completed);
      expect(run.added, 12);

      final FakeItemData data = server.dataset.items.single;
      expect(await client.api.listAccounts(), data.accounts);
      final VersionPage<Transaction> page = await client.api.listTransactions();
      expect(page.items, [
        for (int i = 0; i < data.transactions.length; i++)
          data.transactions[i].copyWith(syncVersion: i + 1),
      ]);
      expect(page.items.map((t) => t.source).toSet(), {DataSource.demo});
      final RecurringStream stream =
          (await client.api.listRecurringStreams()).single;
      expect(stream, data.recurringStreams.single);
      expect(stream.source, RecurringSource.demo);
      expect(stream.transactionIds, ['sample-txn-12', 'sample-txn-01']);
      final Liabilities liabilities = await client.api.getLiabilities();
      expect(liabilities.toJson(), data.liabilities.toJson());
      expect(liabilities.credit.single.aprs.single.aprPercentage, '24.99');
      expect(liabilities.credit.single.source, DataSource.demo);
      expect((await client.api.listHoldings()).holdings, isEmpty);
      expect(
        (await client.api.listItems()).single.item.lastSuccessfulSyncAt,
        fakeNow,
      );
    });

    test('pages by version, with the 409 past the end', () async {
      final FakeClient client = FakeClient.signedIn(server);
      server.seedLinkedItems('ada@example.com');
      final VersionPage<Transaction> first = await client.api.listTransactions(
        limit: 5,
      );
      expect(first.items.map((t) => t.syncVersion), [1, 2, 3, 4, 5]);
      expect(first.nextSince, 5);
      expect(first.hasMore, isTrue);
      final VersionPage<Transaction> rest = await client.api.listTransactions(
        since: 5,
      );
      expect(rest.items, hasLength(7));
      expect(rest.hasMore, isFalse);
      await expectLater(
        client.api.listTransactions(since: 13),
        throwsA(isA<SyncCursorInvalid>()),
      );
      await expectLater(
        client.api.listInvestmentTransactions(since: 13),
        throwsA(isA<SyncCursorInvalid>()),
      );
    });

    test(
      'deleting an Item tombstones its transactions under new versions',
      () async {
        final FakeClient client = FakeClient.signedIn(server);
        server.seedLinkedItems('ada@example.com');
        await client.api.deleteItem('sample-item-1');
        final VersionPage<Transaction> after = await client.api
            .listTransactions(since: 12);
        expect(after.items, hasLength(12));
        expect(after.items.every((t) => t.deletedAt == fakeNow), isTrue);
        expect(await client.api.listItems(), isEmpty);
        expect(await client.api.listAccounts(), isEmpty);
        await expectLater(
          client.api.deleteItem('sample-item-1'),
          throwsA(isA<NotFound>()),
        );
        await expectLater(
          client.api.createUpdateLinkToken(
            'sample-item-1',
            androidPackageName: 'dev.tarnan.financetracker',
          ),
          throwsA(isA<NotFound>()),
        );
      },
    );

    test(
      'a refresh starts a run whose next sync re-applies the rows as modified',
      () async {
        final FakeClient client = FakeClient.signedIn(server);
        server.seedLinkedItems('ada@example.com');
        final SyncRun started = await client.api.refreshItem('sample-item-1');
        expect(started.status, SyncRunStatus.started);
        expect(started.nextCursorSaved, isFalse);
        final SyncRun run = await client.api.syncItem('sample-item-1');
        expect(
          (run.status, run.added, run.modified),
          (SyncRunStatus.completed, 0, 12),
        );
        final VersionPage<Transaction> after = await client.api
            .listTransactions(since: 12);
        expect(after.items, hasLength(12));
        final SyncRun quiet = await client.api.syncItem('sample-item-1');
        expect((quiet.added, quiet.modified), (0, 0));
      },
    );

    test('the balance refresh answers the Item\'s accounts', () async {
      final FakeClient client = FakeClient.signedIn(server);
      server.seedLinkedItems('ada@example.com');
      expect(
        await client.api.refreshBalances('sample-item-1'),
        server.dataset.items.single.accounts,
      );
      await expectLater(
        client.api.refreshBalances('nope'),
        throwsA(isA<NotFound>()),
      );
    });

    test(
      'unlinking with history kept keeps the data and refuses Plaid calls',
      () async {
        final FakeClient client = FakeClient.signedIn(server);
        server.seedLinkedItems('ada@example.com');
        final List<Account> accounts = await client.api.listAccounts();
        await client.api.deleteItem(
          'sample-item-1',
          history: UnlinkHistory.keep,
        );
        final LinkedItem item = (await client.api.listItems()).single;
        expect(item.item.status, ItemStatus.removed);
        expect(item.item.errorCode, isNull);
        expect(await client.api.listAccounts(), accounts);
        expect(
          (await client.api.listTransactions()).items.every(
            (t) => t.deletedAt == null,
          ),
          isTrue,
        );
        for (final Future<Object?> Function() call in [
          () => client.api.syncItem('sample-item-1'),
          () => client.api.refreshItem('sample-item-1'),
          () => client.api.refreshBalances('sample-item-1'),
        ]) {
          await expectLater(call(), throwsA(isA<Conflict>()));
        }
        await client.api.deleteItem('sample-item-1');
        expect(await client.api.listItems(), isEmpty);
        expect(await client.api.listAccounts(), isEmpty);
      },
    );

    test('the logo route serves a dataset logo, else NotFound', () async {
      final FakeItemData sample = FakeDataset.sample(LocalDate(2026, 10, 24))
          .items
          .single;
      final Uint8List png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 7]);
      final FakeServer withLogo = newFakeServer(
        dataset: FakeDataset(
          items: [
            FakeItemData(
              id: sample.id,
              institution: sample.institution,
              accounts: sample.accounts,
              institutionLogo: png,
            ),
          ],
        ),
      );
      final FakeClient client = FakeClient.signedIn(withLogo);
      final LinkedItem linked = await client.api.exchangePublicToken('any');
      expect(
        linked.institution.logoUrl,
        Uri.parse(
          'https://fake.financetracker.test/v1/institutions/ins_109508/logo',
        ),
      );
      expect(await client.api.getInstitutionLogo('ins_109508'), png);
      await expectLater(
        client.api.getInstitutionLogo('ins_1'),
        throwsA(isA<NotFound>()),
      );

      final FakeClient plain = FakeClient.signedIn(server);
      final LinkedItem none = await plain.api.exchangePublicToken('any');
      expect(none.institution.logoUrl, isNull);
      await expectLater(
        plain.api.getInstitutionLogo('ins_109508'),
        throwsA(isA<NotFound>()),
      );
    });

    test('health reports the contract version', () async {
      expect((await FakeClient(server).api.getHealth()).version, '0.5.0');
    });
  });

  group('sandbox', () {
    test('reset-login needs update mode, then the update token, to repair', () async {
      final FakeClient client = FakeClient.signedIn(server);
      server.seedLinkedItems('ada@example.com');
      await client.api.sandboxResetLogin('sample-item-1');
      final LinkedItem broken = (await client.api.listItems()).single;
      expect(broken.item.status, ItemStatus.loginRequired);
      expect(broken.item.errorCode, 'ITEM_LOGIN_REQUIRED');
      for (final Future<Object?> Function() call in [
        () => client.api.syncItem('sample-item-1'),
        () => client.api.refreshItem('sample-item-1'),
        () => client.api.refreshBalances('sample-item-1'),
      ]) {
        await expectLater(call(), throwsA(isA<ItemLoginRequired>()));
      }
      // Exchanging the update token before an update-mode Link changes nothing.
      expect(
        (await client.api.exchangePublicToken(
          'public-demo-update-sample-item-1',
        )).item.status,
        ItemStatus.loginRequired,
      );
      await client.api.createUpdateLinkToken(
        'sample-item-1',
        androidPackageName: 'dev.tarnan.financetracker',
      );
      final LinkedItem repaired = await client.api.exchangePublicToken(
        'public-demo-update-sample-item-1',
      );
      expect(repaired.item.id, 'sample-item-1');
      expect(repaired.item.status, ItemStatus.healthy);
      expect(repaired.item.errorCode, isNull);
      expect(
        (await client.api.syncItem('sample-item-1')).status,
        SyncRunStatus.completed,
      );
      await expectLater(
        client.api.exchangePublicToken('public-demo-update-nope'),
        throwsA(isA<PlaidError>()),
      );
    });

    test('fire-webhook is a no-op for every code', () async {
      final FakeClient client = FakeClient.signedIn(server);
      server.seedLinkedItems('ada@example.com');
      for (final SandboxWebhookCode code in SandboxWebhookCode.values) {
        await client.api.sandboxFireWebhook('sample-item-1', code);
      }
      await expectLater(
        client.api.sandboxFireWebhook('nope', SandboxWebhookCode.defaultUpdate),
        throwsA(isA<NotFound>()),
      );
    });

    test('created transactions are demo rows, in our sign, at the next versions', () async {
      final FakeClient client = FakeClient.signedIn(server);
      server.seedLinkedItems('ada@example.com');
      final LocalDate day = LocalDate(2026, 10, 24);
      await client.api.sandboxCreateTransactions('sample-item-1', [
        SandboxTransaction(
          dateTransacted: day.addDays(-1),
          datePosted: day,
          amount: Money(-1599, 'USD'),
          description: 'SPOTIFY USA',
        ),
        SandboxTransaction(
          dateTransacted: day,
          datePosted: day,
          amount: Money(2500, 'USD'),
          description: 'REFUND',
          accountId: 'sample-savings',
        ),
      ]);
      final VersionPage<Transaction> page = await client.api.listTransactions(
        since: 12,
      );
      expect(page.items.map((t) => t.syncVersion), [13, 14]);
      final [Transaction spotify, Transaction refund] = page.items;
      expect(spotify.amount, Money(-1599, 'USD'));
      expect(spotify.accountId, 'sample-checking');
      expect(spotify.date, day);
      expect(spotify.authorizedDate, day.addDays(-1));
      expect(spotify.source, DataSource.demo);
      expect(refund.amount, Money(2500, 'USD'));
      expect(refund.accountId, 'sample-savings');

      Future<void> refused(SandboxTransaction t) => expectLater(
        client.api.sandboxCreateTransactions('sample-item-1', [t]),
        throwsA(isA<ValidationFailed>()),
      );
      await refused(
        SandboxTransaction(
          dateTransacted: day.addDays(1),
          datePosted: day.addDays(1),
          amount: Money(1, 'USD'),
          description: 'FUTURE',
        ),
      );
      // An amount in another currency than its account's, named or the default.
      for (final String? account in [null, 'sample-savings']) {
        await expectLater(
          client.api.sandboxCreateTransactions('sample-item-1', [
            SandboxTransaction(
              dateTransacted: day,
              datePosted: day,
              amount: Money(-500, 'EUR'),
              description: 'EURO',
              accountId: account,
            ),
          ]),
          throwsA(
            isA<ValidationFailed>().having(
              (e) => e.errors.map((f) => f.field),
              'fields',
              ['transactions[0].amount'],
            ),
          ),
        );
      }
      await refused(
        SandboxTransaction(
          dateTransacted: day,
          datePosted: day,
          amount: Money(1, 'USD'),
          description: 'X',
          accountId: 'nope',
        ),
      );
      await client.api.sandboxResetLogin('sample-item-1');
      await expectLater(
        client.api.sandboxCreateTransactions('sample-item-1', [
          SandboxTransaction(
            dateTransacted: day,
            datePosted: day,
            amount: Money(1, 'USD'),
            description: 'X',
          ),
        ]),
        throwsA(isA<ItemLoginRequired>()),
      );
    });

    test(
      "created transactions reach back to the UTC date minus 729, as Plaid's",
      () async {
        // fakeNow is 2026-10-24 15:00 UTC: Plaid takes dates from 2024-10-25, the UTC date
        // minus 729, and refuses 730 back (`PLAN.md` §4, 2026-10-25).
        final FakeClient client = FakeClient.signedIn(server);
        server.seedLinkedItems('ada@example.com');
        SandboxTransaction on(LocalDate day) => SandboxTransaction(
          dateTransacted: day,
          datePosted: day,
          amount: Money(-100, 'USD'),
          description: 'OLD',
        );
        await expectLater(
          client.api.sandboxCreateTransactions('sample-item-1', [
            on(LocalDate(2024, 10, 24)),
          ]),
          throwsA(
            isA<ValidationFailed>().having(
              (e) => e.errors.map((f) => f.field),
              'fields',
              [
                'transactions[0].date_transacted',
                'transactions[0].date_posted',
              ],
            ),
          ),
        );
        await client.api.sandboxCreateTransactions('sample-item-1', [
          on(LocalDate(2024, 10, 25)),
        ]);
      },
    );

    test(
      'a provisioning job completes on the next tick with the persona linked',
      () async {
        final FakeClient client = FakeClient.signedIn(server);
        final ProvisionJob queued = await client.api.provisionPersona(
          ProvisionPersona.renter,
          days: 30,
        );
        expect(queued.status, ProvisionJobStatus.queued);
        expect(queued.persona, ProvisionPersona.renter);
        expect(queued.seed, 1);
        expect(queued.createdAt, fakeNow);
        expect(queued.itemIds, isEmpty);
        await expectLater(
          client.api.provisionPersona(ProvisionPersona.family),
          throwsA(isA<Conflict>()),
        );
        expect(
          (await client.api.getProvisionJob(queued.id)).status,
          ProvisionJobStatus.queued,
        );

        server.advanceClock(const Duration(seconds: 1));
        final ProvisionJob done = await client.api.getProvisionJob(queued.id);
        expect(done.status, ProvisionJobStatus.completed);
        expect(done.finishedAt, fakeNow.add(const Duration(seconds: 1)));
        expect(done.itemIds, ['demo-item-renter-platypus']);
        expect(done.progress, (
          itemsTotal: 1,
          itemsLinked: 1,
          batchesTotal: 0,
          batchesSent: 0,
          skipped: 0,
        ));
        expect(done.error, isNull);
        expect([
          for (final LinkedItem i in await client.api.listItems()) i.item.id,
        ], contains('demo-item-renter-platypus'));
        final VersionPage<Transaction> page = await client.api
            .listTransactions();
        expect(page.items, isNotEmpty);
        expect(page.items.map((t) => t.source).toSet(), {DataSource.demo});

        // A finished job does not block the next.
        final ProvisionJob next = await client.api.provisionPersona(
          ProvisionPersona.student,
          seed: 2,
          days: 60,
        );
        expect(next.seed, 2);
        final FakeClient eve = FakeClient.signedIn(
          server,
          email: 'eve@example.com',
        );
        await expectLater(
          eve.api.getProvisionJob(next.id),
          throwsA(isA<NotFound>()),
        );
        await expectLater(
          client.api.provisionPersona(ProvisionPersona.renter),
          throwsA(isA<Conflict>()),
        );
        await expectLater(
          eve.api.provisionPersona(ProvisionPersona.renter, days: 29),
          throwsA(isA<ValidationFailed>()),
        );
      },
    );

    test('a provisioned persona ends on the device\'s date, not UTC\'s', () async {
      // 15:00 UTC is already the 25th east of UTC+9, and still the 24th here; a
      // device west of UTC in the evening is the mirror case.
      final FakeServer east = FakeServer(
        now: () => fakeNow,
        localDate: (_) => LocalDate(2026, 10, 25),
      );
      final FakeClient client = FakeClient.signedIn(east);
      final ProvisionJob job = await client.api.provisionPersona(
        ProvisionPersona.renter,
        days: 30,
      );
      east.advanceClock(const Duration(seconds: 1));
      await client.api.getProvisionJob(job.id);
      final List<Transaction> rows = (await client.api.listTransactions(
        limit: 500,
      )).items;
      final LocalDate newest = rows
          .map((t) => t.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      expect(newest.isAfter(LocalDate(2026, 10, 25)), isFalse);
      expect(rows.any((t) => t.date == LocalDate(2026, 10, 25)), isTrue);
    });

    test('a removed Item refuses the sandbox controls', () async {
      final FakeClient client = FakeClient.signedIn(server);
      server.seedLinkedItems('ada@example.com');
      await client.api.deleteItem('sample-item-1', history: UnlinkHistory.keep);
      await expectLater(
        client.api.sandboxResetLogin('sample-item-1'),
        throwsA(isA<Conflict>()),
      );
      await expectLater(
        client.api.sandboxFireWebhook(
          'sample-item-1',
          SandboxWebhookCode.error,
        ),
        throwsA(isA<Conflict>()),
      );
    });
  });

  group('hooks and the dataset', () {
    test('failNext answers once with the status and its code', () async {
      final FakeClient client = FakeClient.signedIn(server);
      server.failNext('getMe', 429);
      await expectLater(
        client.api.getMe(),
        throwsA(
          isA<RateLimited>().having(
            (e) => e.retryAfter,
            'retryAfter',
            const Duration(seconds: 1),
          ),
        ),
      );
      server.failNext('listItems', 500);
      await expectLater(client.api.listItems(), throwsA(isA<ServerError>()));
      expect(await client.api.getMe(), isA<User>());
    });

    test('failNextNetwork drops the connection once', () async {
      final FakeClient client = FakeClient.signedIn(server);
      server.failNextNetwork('exchangePublicToken');
      await expectLater(
        client.api.exchangePublicToken('public-demo-sample-item-1'),
        throwsA(isA<NetworkError>()),
      );
      expect(server.calls.where((c) => c == 'exchangePublicToken'), isEmpty);
      await client.api.exchangePublicToken('public-demo-sample-item-1');
    });

    test('a dataset refuses anything that is not demo', () {
      final FakeItemData sample = FakeDataset.sample(LocalDate(2026, 10, 24))
          .items
          .single;
      expect(
        () => FakeItemData(
          id: 'x',
          institution: sample.institution,
          accounts: sample.accounts,
          transactions: [
            sample.transactions.first.copyWith(source: DataSource.plaid),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => FakeItemData(
          id: 'x',
          institution: sample.institution,
          accounts: const [],
          transactions: sample.transactions,
        ),
        throwsArgumentError,
      );
      final CreditLiability card = sample.liabilities.credit.single;
      expect(
        () => FakeItemData(
          id: 'x',
          institution: sample.institution,
          accounts: sample.accounts,
          liabilities: Liabilities(
            credit: [
              CreditLiability(
                accountId: card.accountId,
                source: DataSource.plaid,
              ),
            ],
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
