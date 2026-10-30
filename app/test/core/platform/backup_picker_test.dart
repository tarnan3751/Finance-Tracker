// The backup picker: the platform one asks flutter_file_dialog for a file with no MIME
// filter, hands back the plugin's copy with its length, reads the ranges asked for and
// deletes the copy's directory on close, answers null when nothing was chosen, and turns
// a platform error or an unreadable copy into BackupPickFailedException; the fake answers
// its file, records the ranges read and counts the calls.
import 'dart:io';

import 'package:finance_tracker/core/platform/backup_picker.dart';
import 'package:finance_tracker/core/platform/fake_backup_picker.dart';
import 'package:finance_tracker/core/platform/platform_backup_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _dialog = MethodChannel('flutter_file_dialog');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  final List<MethodCall> seen = [];

  void answer(Object? Function(MethodCall) reply) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_dialog, (call) async {
            seen.add(call);
            return reply(call);
          });

  setUp(() {
    temp = Directory.systemTemp.createTempSync('picker');
    seen.clear();
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_dialog, null);
    temp.deleteSync(recursive: true);
  });

  test('reads the ranges asked for, then deletes the copy on close', () async {
    final Directory copy = Directory('${temp.path}/file_dialog-1234')
      ..createSync();
    final File file = File('${copy.path}/finance-tracker-2026-10-30.ftbk')
      ..writeAsBytesSync([0x46, 0x54, 0x42, 0x4b, 1, 2, 3]);
    answer((_) => file.path);
    final PickedFile picked = (await const PlatformBackupPicker().pick())!;
    expect(seen.single.method, 'pickFile');
    final Map<Object?, Object?> args =
        seen.single.arguments as Map<Object?, Object?>;
    expect(args['mimeTypesFilter'], isNull);
    expect(args['copyFileToCacheDir'], isTrue);
    expect(picked.length, 7);
    expect(await picked.read(0, 4), [0x46, 0x54, 0x42, 0x4b]);
    expect(await picked.read(4), [1, 2, 3]);
    expect(await picked.read(), [0x46, 0x54, 0x42, 0x4b, 1, 2, 3]);
    await picked.close();
    expect(copy.existsSync(), isFalse);
    expect(temp.existsSync(), isTrue);
  });

  test('a copy outside its own directory is deleted alone', () async {
    final File file = File('${temp.path}/loose.ftbk')..writeAsBytesSync([1]);
    answer((_) => file.path);
    final PickedFile picked = (await const PlatformBackupPicker().pick())!;
    await picked.close();
    expect(file.existsSync(), isFalse);
    expect(temp.existsSync(), isTrue);
  });

  test('nothing chosen is null', () async {
    answer((_) => null);
    expect(await const PlatformBackupPicker().pick(), isNull);
  });

  test('a platform error, or a copy that cannot be read, fails', () async {
    answer((_) => throw PlatformException(code: 'file_copy_failed'));
    await expectLater(
      const PlatformBackupPicker().pick(),
      throwsA(isA<BackupPickFailedException>()),
    );
    answer((_) => '${temp.path}/file_dialog-gone/missing.ftbk');
    await expectLater(
      const PlatformBackupPicker().pick(),
      throwsA(isA<BackupPickFailedException>()),
    );
  });

  test('the fake answers its file, records the reads and counts', () async {
    final FakeBackupPicker fake = FakeBackupPicker();
    expect(await fake.pick(), isNull);
    fake.file = Uint8List.fromList([7, 8, 9]);
    final PickedFile picked = (await fake.pick())!;
    expect(await picked.read(0, 2), [7, 8]);
    expect(await picked.read(), [7, 8, 9]);
    await picked.close();
    expect(fake.reads, [(0, 2), (0, 3)]);
    expect(fake.closed, 1);
    fake.length = 1 << 30;
    expect((await fake.pick())!.length, 1 << 30);
    fake.failure = const BackupPickFailedException();
    await expectLater(fake.pick(), throwsA(isA<BackupPickFailedException>()));
    expect(fake.calls, 4);
  });
}
