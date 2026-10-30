// The local wipe on real files: an encrypted database with its side files, the plain
// debug database, receipts, the home screen widgets' snapshot, the legacy keys and the
// three secure-storage values, all gone, the reminders and notifications cleared, the pending record set from the first
// step to the last, a second run harmless, a cut at each step leaving exactly the later
// steps' data and the wipe pending, a run after the cut finishing it, and the next open a
// fresh database under a new key. The in-memory wipe clears the same stores.
import 'dart:io';
import 'dart:typed_data';

import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/platform/fake_reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler.dart';
import 'package:finance_tracker/features/widgets/data/fake_widget_writer.dart';
import 'package:finance_tracker/features/widgets/domain/widget_data.dart';
import 'package:finance_tracker/features/widgets/domain/widget_writer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const FileSystemException _cut = FileSystemException('cut');

/// The preferences, refusing to remove the legacy keys.
final class _LegacyCut extends Fake implements SharedPreferences {
  _LegacyCut(this.inner);

  final SharedPreferences inner;

  @override
  String? getString(String key) => inner.getString(key);

  @override
  Future<bool> setString(String key, String value) =>
      inner.setString(key, value);

  @override
  Future<bool> remove(String key) =>
      key == DriftLocalWipe.pendingKey ? inner.remove(key) : throw _cut;
}

final class _ReceiptsCut extends Fake implements ReceiptStore {
  @override
  Future<void> deleteAll() async => throw _cut;
}

final class _WidgetsCut extends Fake implements WidgetWriter {
  @override
  Future<void> clear() async => throw _cut;
}

final class _KeyCut extends Fake implements DatabaseKeyStore {
  @override
  Future<void> delete() async => throw _cut;
}

/// The session store, refusing at [step] (`session` or `marker`).
final class _TokensCut extends Fake implements TokenStore {
  _TokensCut(this.step);

  final String step;
  final SecureTokenStore inner = SecureTokenStore();

  @override
  Future<void> clear() => step == 'session' ? throw _cut : inner.clear();

  @override
  Future<void> clearInstallUserId() =>
      step == 'marker' ? throw _cut : inner.clearInstallUserId();
}

final class _RemindersCut extends Fake implements ReminderScheduler {
  @override
  Future<void> clearAll() async => throw _cut;
}

/// The steps in their order, as what each leaves on the install.
const List<String> _steps = [
  'legacy',
  'files',
  'receipts',
  'widgets',
  'key',
  'session',
  'marker',
  'reminders',
];

void main() {
  late Directory directory;
  late Map<String, String> secure;
  late FakeReminderScheduler reminders;
  late FakeWidgetWriter widgets;

  setUpAll(tzdata.initializeTimeZones);

  setUp(() {
    directory = Directory.systemTemp.createTempSync('ft-wipe-');
    secure = {};
    FlutterSecureStorage.setMockInitialValues(secure);
    SharedPreferences.setMockInitialValues({
      'transactions': '[]',
      'incomes': '[]',
      'totalBalance': '0',
      'unrelated': 'kept',
    });
    reminders = FakeReminderScheduler();
    widgets = FakeWidgetWriter();
  });
  tearDown(() => directory.deleteSync(recursive: true));

  File file(String name) => File('${directory.path}/$name');

  /// The wipe, its store at [cut] refusing.
  DriftLocalWipe wipeOf({String? cut}) => DriftLocalWipe(
    directory: cut == 'files' ? () async => throw _cut : () async => directory,
    receipts: cut == 'receipts'
        ? _ReceiptsCut()
        : FileReceiptStore(() async => directory),
    widgets: cut == 'widgets' ? _WidgetsCut() : widgets,
    preferences: cut == 'legacy'
        ? () async => _LegacyCut(await SharedPreferences.getInstance())
        : SharedPreferences.getInstance,
    keys: cut == 'key' ? _KeyCut() : SecureDatabaseKeyStore(),
    tokens: cut == 'session' || cut == 'marker'
        ? _TokensCut(cut!)
        : SecureTokenStore(),
    reminders: cut == 'reminders' ? _RemindersCut() : reminders,
  );

  Future<AppDatabase> open() async => AppDatabase(
    await openDatabaseExecutor(
      file(databaseFileName),
      keyStore: SecureDatabaseKeyStore(),
    ),
  );

  Future<void> install() async {
    final AppDatabase database = await open();
    await DriftAppMetaStore(database).write('k', 'v');
    await database.close();
    for (final String suffix in ['-wal', '-shm', '-journal']) {
      file('$databaseFileName$suffix').writeAsStringSync('x');
    }
    file(plainDatabaseFileName).writeAsStringSync('x');
    file('$plainDatabaseFileName-wal').writeAsStringSync('x');
    final ReceiptStore receipts = FileReceiptStore(() async => directory);
    await receipts.commit(await receipts.stage('t1', Uint8List(4)));
    await receipts.stage('t2', Uint8List(4));
    file('other.bin').writeAsStringSync('kept');
    await widgets.write(
      WidgetData.signedOut(updatedAt: DateTime.utc(2026), updatedText: ''),
    );
    await SecureTokenStore().writeInstallUserId('user-1');
    secure[SecureTokenStore.sessionKey] = '{}';
    await reminders.replaceAll([
      ScheduledReminder(
        id: 1,
        billId: 'b1',
        dueDate: LocalDate(2026, 11, 2),
        at: tz.TZDateTime.utc(2026, 11, 1, 9),
        title: 'Rent',
        body: 'Due tomorrow',
      ),
    ]);
  }

  /// Which of the steps' data is still on the install.
  Future<Set<String>> left() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return {
      if (preferences.containsKey('transactions')) 'legacy',
      if (file(databaseFileName).existsSync() ||
          file(plainDatabaseFileName).existsSync())
        'files',
      if (Directory('${directory.path}/$receiptFolder').existsSync())
        'receipts',
      if (widgets.holdsSnapshot) 'widgets',
      if (secure.containsKey(SecureDatabaseKeyStore.keyName)) 'key',
      if (secure.containsKey(SecureTokenStore.sessionKey)) 'session',
      if (secure.containsKey(SecureTokenStore.installUserKey)) 'marker',
      if ((await reminders.pending()).isNotEmpty) 'reminders',
    };
  }

  test('erases the database files, receipts, legacy keys, secrets and '
      'reminders, and leaves the rest', () async {
    await install();
    expect(await left(), _steps.toSet());

    final DriftLocalWipe wipe = wipeOf();
    await wipe.wipe(WipeReason.accountDeleted);

    expect(await left(), isEmpty);
    final Set<String> files = {
      for (final FileSystemEntity e in directory.listSync())
        e.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
    };
    expect(files, {'other.bin'});
    expect(secure, isEmpty);
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    expect(preferences.getKeys(), {'unrelated'});
    expect(reminders.cleared, 1);
    expect(await wipe.pending(), isNull);
  });

  test('running it again is harmless', () async {
    await install();
    await wipeOf().wipe(WipeReason.deviceErased);
    await wipeOf().wipe(WipeReason.deviceErased);
    expect(await left(), isEmpty);
    expect(reminders.cleared, 2);
  });

  for (final (int index, String cut) in _steps.indexed) {
    test('a cut at the $cut step leaves the later steps and the wipe pending; '
        'the next run finishes it', () async {
      await install();
      await expectLater(
        wipeOf(cut: cut).wipe(WipeReason.accountDeleted),
        throwsA(same(_cut)),
      );

      expect(await left(), _steps.skip(index).toSet());
      if (index <= _steps.indexOf('marker')) {
        expect(secure[SecureTokenStore.installUserKey], 'user-1');
      }
      final DriftLocalWipe next = wipeOf();
      expect(await next.pending(), WipeReason.accountDeleted);

      await next.wipe((await next.pending())!);
      expect(await left(), isEmpty);
      expect(await next.pending(), isNull);
    });
  }

  test('a pending record this build does not know still finishes', () async {
    SharedPreferences.setMockInitialValues({
      DriftLocalWipe.pendingKey: 'somethingNew',
    });
    expect(await wipeOf().pending(), WipeReason.deviceErased);
  });

  test('the next open is a fresh database under a new key', () async {
    await install();
    final String? before = secure[SecureDatabaseKeyStore.keyName];
    expect(before, matches(RegExp(r'^[0-9a-f]{64}$')));

    await wipeOf().wipe(WipeReason.deviceErased);
    final AppDatabase fresh = await open();
    addTearDown(fresh.close);
    expect(await DriftAppMetaStore(fresh).read('k'), isNull);

    final String? after = secure[SecureDatabaseKeyStore.keyName];
    expect(after, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(after, isNot(before));
    expect(await SecureTokenStore().readInstallUserId(), isNull);
  });

  test('the in-memory wipe clears the same stores', () async {
    final MemoryReceiptStore receipts = MemoryReceiptStore();
    await receipts.commit(await receipts.stage('t1', Uint8List(4)));
    await receipts.stage('t2', Uint8List(4));
    final InMemoryDatabaseKeyStore keys = InMemoryDatabaseKeyStore(
      newDatabaseKey(),
    );
    final InMemoryTokenStore tokens = InMemoryTokenStore(
      installUserId: 'user-1',
    );
    await widgets.write(
      WidgetData.signedOut(updatedAt: DateTime.utc(2026), updatedText: ''),
    );
    final InMemoryLocalWipe wipe = InMemoryLocalWipe(
      receipts: receipts,
      widgets: widgets,
      keys: keys,
      tokens: tokens,
      reminders: reminders,
    );

    await wipe.wipe(WipeReason.deviceErased);

    expect(receipts.paths, isEmpty);
    expect(receipts.stagedCount, 0);
    expect(widgets.holdsSnapshot, isFalse);
    expect(keys.key, isNull);
    expect(await tokens.read(), isNull);
    expect(tokens.installUserId, isNull);
    expect(reminders.cleared, 1);
    expect(wipe.wipes, 1);
    expect(await wipe.pending(), isNull);
  });
}
