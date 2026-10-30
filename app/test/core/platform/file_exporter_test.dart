// The file exporter: the platform one writes the bytes to a temporary file of the
// file's name in a directory of the call's own, hands its path to flutter_file_dialog's
// "Save as" (null back is a cancel) or to share_plus's share sheet, deletes it whatever
// happens (two calls at once for one name keep their own files), and turns a platform
// error into ExportFailedException; the fake records every call.
import 'dart:async';
import 'dart:io';

import 'package:finance_tracker/core/platform/fake_file_exporter.dart';
import 'package:finance_tracker/core/platform/file_exporter.dart';
import 'package:finance_tracker/core/platform/platform_file_exporter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _dialog = MethodChannel('flutter_file_dialog');
const MethodChannel _share = MethodChannel('dev.fluttercommunity.plus/share');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late PlatformFileExporter exporter;
  final Uint8List bytes = Uint8List.fromList('a,b\r\n1,2\r\n'.codeUnits);
  // What the platform side saw: the method, its arguments, and the file's bytes then.
  final List<(String, Map<Object?, Object?>, List<int>?)> seen = [];

  void answer(MethodChannel channel, Object? Function(MethodCall) reply) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final Map<Object?, Object?> args =
                call.arguments as Map<Object?, Object?>;
            final Object? path =
                args['sourceFilePath'] ?? (args['paths'] as List?)?.single;
            seen.add((
              call.method,
              args,
              path is String && File(path).existsSync()
                  ? File(path).readAsBytesSync()
                  : null,
            ));
            return reply(call);
          });

  setUp(() {
    temp = Directory.systemTemp.createTempSync('exporter');
    exporter = PlatformFileExporter(() async => temp);
    seen.clear();
  });
  tearDown(() {
    for (final MethodChannel c in [_dialog, _share]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(c, null);
    }
    temp.deleteSync(recursive: true);
  });

  bool leftovers() => Directory('${temp.path}/export').listSync().isNotEmpty;

  test('save as hands the dialog the file and deletes it after', () async {
    answer(_dialog, (_) => 'content://saved/report.csv');

    final SaveOutcome outcome = await exporter.saveAs(
      bytes,
      'transactions.csv',
      'text/csv',
    );

    expect(outcome, SaveOutcome.saved);
    final (String method, Map<Object?, Object?> args, List<int>? content) =
        seen.single;
    expect(method, 'saveFile');
    expect(
      args['sourceFilePath'],
      matches(
        RegExp('^${RegExp.escape(temp.path)}/export/[^/]+/transactions.csv\$'),
      ),
    );
    expect(args['mimeTypesFilter'], ['text/csv']);
    expect(content, bytes);
    expect(leftovers(), isFalse);
  });

  test('a dialog closed without saving is a cancel', () async {
    answer(_dialog, (_) => null);

    expect(
      await exporter.saveAs(bytes, 'transactions.csv', 'text/csv'),
      SaveOutcome.cancelled,
    );
    expect(leftovers(), isFalse);
  });

  test(
    'share hands the sheet the file under its name and deletes it',
    () async {
      answer(_share, (_) => 'com.example.mail');

      await exporter.share(bytes, 'report-2026-10.pdf', 'application/pdf');

      final (String method, Map<Object?, Object?> args, List<int>? content) =
          seen.single;
      expect(method, 'share');
      expect(
        (args['paths']! as List<Object?>).single,
        matches(
          RegExp(
            '^${RegExp.escape(temp.path)}/export/[^/]+/report-2026-10.pdf\$',
          ),
        ),
      );
      expect(args['mimeTypes'], ['application/pdf']);
      expect(content, bytes);
      expect(leftovers(), isFalse);
    },
  );

  test(
    'a platform error is an ExportFailedException, the file deleted',
    () async {
      answer(_dialog, (_) => throw PlatformException(code: 'boom'));
      answer(_share, (_) => throw PlatformException(code: 'boom'));

      await expectLater(
        exporter.saveAs(bytes, 'a.csv', 'text/csv'),
        throwsA(isA<ExportFailedException>()),
      );
      await expectLater(
        exporter.share(bytes, 'a.csv', 'text/csv'),
        throwsA(isA<ExportFailedException>()),
      );
      expect(leftovers(), isFalse);
    },
  );

  test('two calls at once for one name keep their own files', () async {
    final Completer<void> release = Completer<void>();
    int asked = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_dialog, (call) async {
          final String path =
              (call.arguments as Map<Object?, Object?>)['sourceFilePath']!
                  as String;
          // The first call waits until the second has finished.
          if (++asked == 1) await release.future;
          seen.add((
            call.method,
            const {},
            File(path).existsSync() ? File(path).readAsBytesSync() : null,
          ));
          return 'content://saved';
        });

    final Future<SaveOutcome> first = exporter.saveAs(
      bytes,
      'report-2026-10.pdf',
      'application/pdf',
    );
    while (asked == 0) {
      await Future<void>.delayed(Duration.zero);
    }
    await exporter.saveAs(bytes, 'report-2026-10.pdf', 'application/pdf');
    release.complete();
    await first;

    expect([for (final (_, _, content) in seen) content], [bytes, bytes]);
    expect(leftovers(), isFalse);
  });

  test('the fake records each call and answers as set', () async {
    final FakeFileExporter fake = FakeFileExporter(
      outcome: SaveOutcome.cancelled,
    );

    expect(
      await fake.saveAs(bytes, 'a.csv', 'text/csv'),
      SaveOutcome.cancelled,
    );
    await fake.share(bytes, 'b.pdf', 'application/pdf');
    fake.failure = const ExportFailedException();
    await expectLater(
      fake.share(bytes, 'c.pdf', 'application/pdf'),
      throwsA(isA<ExportFailedException>()),
    );

    expect(
      [for (final ExportCall c in fake.calls) (c.kind, c.fileName, c.mimeType)],
      [
        (ExportKind.saveAs, 'a.csv', 'text/csv'),
        (ExportKind.share, 'b.pdf', 'application/pdf'),
        (ExportKind.share, 'c.pdf', 'application/pdf'),
      ],
    );
    expect(fake.calls.first.bytes, bytes);
  });
}
