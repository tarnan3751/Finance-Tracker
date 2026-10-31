// The widgets' refresh runner: nothing until listened, then the snapshot of what the
// screens show written through the writer after the debounce; written again with the new
// numbers after a transaction change, a whole Plaid pull and a sync session; the
// signed-out snapshot while nobody is signed in; the locked snapshot while the app lock is
// on, written again when it goes off; the background cycle's one write; and a
// failed write logged, never stopping the next.
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/features/lock/application/lock_controller.dart';
import 'package:finance_tracker/features/widgets/application/widget_providers.dart';
import 'package:finance_tracker/features/widgets/data/fake_widget_writer.dart';
import 'package:finance_tracker/features/widgets/domain/widget_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

final class _FinishingSync extends SyncController {
  @override
  SyncStatus build() => SyncStatus.signedOut;

  /// A session finished [at].
  void finish(DateTime at) =>
      state = SyncStatus(phase: SyncPhase.idle, lastSyncAt: at);
}

/// The stored session, read only after [delay]: a fresh container's session is unknown
/// for that long.
final class _SlowTokenStore implements TokenStore {
  _SlowTokenStore(this.inner, this.delay);

  final TokenStore inner;
  final Duration delay;

  @override
  Future<Session?> read() async {
    await Future<void>.delayed(delay);
    return inner.read();
  }

  @override
  Future<Session?> reload() => read();

  @override
  Future<void> write(Session session) => inner.write(session);

  @override
  Future<void> clear() => inner.clear();

  @override
  Future<void> update(Session? Function(Session? current) change) =>
      inner.update(change);

  @override
  Future<String?> readInstallUserId() => inner.readInstallUserId();

  @override
  Future<void> writeInstallUserId(String userId) =>
      inner.writeInstallUserId(userId);

  @override
  Future<void> clearInstallUserId() => inner.clearInstallUserId();
}

// Long enough for the streams behind the snapshot to settle and the debounce to pass.
Future<void> _settle() async {
  await pumpEventQueue();
  await Future<void>.delayed(const Duration(milliseconds: 50));
  await pumpEventQueue();
}

// Waits (up to five seconds, for a loaded machine) until [writer] holds [count] writes,
// then settles, so a write too many would show.
Future<void> _written(FakeWidgetWriter writer, int count) async {
  final Stopwatch waited = Stopwatch()..start();
  while (writer.writes.length < count &&
      waited.elapsed < const Duration(seconds: 5)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  await _settle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeWidgetWriter writer;

  ProviderContainer container({
    AppConfig? config,
    bool signedIn = true,
    List<Override> overrides = const [],
  }) {
    // The test's own overrides replace testOverrides' of the same provider (the token
    // store's), which a container refuses twice.
    final Set<Object> replaced = {for (final Override o in overrides) o.origin};
    final ProviderContainer c = ProviderContainer(
      overrides: [
        for (final Override o in testOverrides(
          config: config,
          signedIn: signedIn,
          overrides: [
            storeOverride(seededStore()),
            widgetWriterProvider.overrideWithValue(writer),
            widgetDebounceProvider.overrideWithValue(
              const Duration(milliseconds: 10),
            ),
          ],
        ))
          if (!replaced.contains(o.origin)) o,
        ...overrides,
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  WidgetAccount checking(WidgetData data) =>
      data.accounts.singleWhere((a) => a.id == checkingId);

  setUp(() => writer = FakeWidgetWriter());

  test(
    'writes nothing until listened to, then the screens\' numbers',
    () async {
      final ProviderContainer c = container();
      await _settle();
      expect(writer.writes, isEmpty);
      c.listen(widgetRefreshRunnerProvider, (_, _) {});
      await _settle();
      final WidgetData data = writer.writes.single;
      expect(data.signedIn, isTrue);
      final Map<String, Money?> derived = await c
          .read(accountRepositoryProvider)
          .watchDerivedBalances()
          .first;
      expect(checking(data).balance, derived[checkingId]);
      expect(checking(data).text, derived[checkingId]!.format());
      expect(data.updatedAt, testClock.nowUtc());
      expect(c.read(widgetRefreshRunnerProvider), testClock.nowUtc());
    },
  );

  test('a transaction change is written once, with the new balance', () async {
    final ProviderContainer c = container();
    c.listen(widgetRefreshRunnerProvider, (_, _) {});
    await _written(writer, 1);
    final Money before = checking(writer.last!).balance;
    await c
        .read(transactionRepositoryProvider)
        .upsert(testTransaction('coffee', cents: -1000));
    await _written(writer, 2);
    expect(writer.writes, hasLength(2));
    expect(checking(writer.last!).balance, before - Money(1000, 'USD'));
  });

  test('a whole Plaid pull and a sync session each write again', () async {
    final _FinishingSync sync = _FinishingSync();
    final ProviderContainer c = container(
      overrides: [syncControllerProvider.overrideWith(() => sync)],
    );
    c.listen(widgetRefreshRunnerProvider, (_, _) {});
    await _written(writer, 1);
    expect(writer.writes, hasLength(1));
    await c.read(plaidPullProvider).run();
    await _written(writer, 2);
    final int afterPull = writer.writes.length;
    expect(afterPull, greaterThan(1));
    expect(
      writer.last!.accounts.map((a) => a.id),
      contains(startsWith('sample-')),
      reason: 'the pull brought the fake server\'s linked accounts',
    );
    sync.finish(DateTime.utc(2026, 10, 24, 15));
    await _written(writer, afterPull + 1);
    expect(writer.writes, hasLength(afterPull + 1));
  });

  test('signed out in dev and prod, the signed-out snapshot', () async {
    final ProviderContainer c = container(signedIn: false);
    c.listen(widgetRefreshRunnerProvider, (_, _) {});
    await _written(writer, 1);
    final WidgetData data = writer.writes.single;
    expect(data.signedIn, isFalse);
    expect(data.accounts, isEmpty);
    expect(data.toJson()['signed_in'], isFalse);
  });

  test('the demo flavor is always signed in', () async {
    final ProviderContainer c = container(
      config: AppConfig.demo(),
      signedIn: false,
    );
    c.listen(widgetRefreshRunnerProvider, (_, _) {});
    await _written(writer, 1);
    expect(writer.writes.single.signedIn, isTrue);
  });

  test(
    'locked from app_meta, and written again when the lock goes off',
    () async {
      final InMemoryAppMetaStore meta = InMemoryAppMetaStore();
      await meta.write(AppMetaKeys.lockEnabled, 'true');
      final ProviderContainer c = container(
        overrides: [appMetaStoreProvider.overrideWithValue(meta)],
      );
      c.listen(widgetRefreshRunnerProvider, (_, _) {});
      await _written(writer, 1);
      expect(writer.last!.locked, isTrue);
      await c.read(lockControllerProvider.notifier).restored();
      await c.read(lockControllerProvider.notifier).disable();
      await _written(writer, 2);
      expect(writer.last!.locked, isFalse);
    },
  );

  test('a session still being read is waited for, never written as signed out '
      '(the background cycle\'s fresh container)', () async {
    final ProviderContainer c = container(
      overrides: [
        tokenStoreProvider.overrideWith((ref) {
          final Session session = ref
              .watch(fakeServerProvider)
              .seedSession(
                email: demoEmail,
                password: demoPassword,
                deviceName: 'Demo device',
              );
          return _SlowTokenStore(
            InMemoryTokenStore(session: session, installUserId: session.userId),
            const Duration(milliseconds: 200),
          );
        }),
      ],
    );
    expect(c.read(sessionControllerProvider), isA<SessionUnknown>());
    await writeWidgetsNow(c);
    expect(writer.writes, hasLength(1));
    expect(writer.last!.signedIn, isTrue);
    expect(writer.last!.accounts, isNotEmpty);
  });

  test(
    'the runner listened to before the session is read writes only after it',
    () async {
      final ProviderContainer c = container(
        overrides: [
          tokenStoreProvider.overrideWith((ref) {
            final Session session = ref
                .watch(fakeServerProvider)
                .seedSession(
                  email: demoEmail,
                  password: demoPassword,
                  deviceName: 'Demo device',
                );
            return _SlowTokenStore(
              InMemoryTokenStore(
                session: session,
                installUserId: session.userId,
              ),
              const Duration(milliseconds: 200),
            );
          }),
        ],
      );
      c.listen(widgetRefreshRunnerProvider, (_, _) {});
      await _settle();
      expect(writer.writes, isEmpty);
      await _written(writer, 1);
      expect(writer.writes.single.signedIn, isTrue);
    },
  );

  test(
    'writeWidgetsNow writes once on a container nothing listens to',
    () async {
      final ProviderContainer c = container();
      await writeWidgetsNow(c);
      expect(writer.writes, hasLength(1));
      expect(writer.last!.signedIn, isTrue);
      await _settle();
      expect(writer.writes, hasLength(1), reason: 'the runner was released');
    },
  );

  test('a failed write is logged, and the next one runs', () async {
    final ProviderContainer c = container();
    writer.failure = StateError('no widgets');
    c.listen(widgetRefreshRunnerProvider, (_, _) {});
    await _written(writer, 1);
    expect(writer.writes, hasLength(1));
    expect(c.read(widgetRefreshRunnerProvider), isNull);
    writer.failure = null;
    await c.read(widgetRefreshRunnerProvider.notifier).refresh();
    expect(writer.writes, hasLength(2));
    expect(c.read(widgetRefreshRunnerProvider), testClock.nowUtc());
  });
}
