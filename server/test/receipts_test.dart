// The receipt routes: the cap (by Content-Length and by what arrives), an empty body,
// a row whose file went missing repaired by a store, the hash check,
// the content types, idempotent stores, ownership (another user's hash is a 404 until
// they store it themselves, sharing the one file), the path check, and the bearer.
// Every response is validated against the contract by TestServer.call.
import 'dart:io';

import 'package:cryptography/dart.dart' show DartSha256;
import 'package:finance_tracker_server/src/receipts/receipt_routes.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

String _sha(List<int> bytes) => [
  for (final b in const DartSha256().hashSync(bytes).bytes)
    b.toRadixString(16).padLeft(2, '0'),
].join();

final List<int> _jpeg = [0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 4];
final List<int> _png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 5, 6];

void main() {
  late TestServer server;
  late Session ada;
  setUp(() async {
    server = await TestServer.start();
    ada = await server.register();
  });

  Future<TestResponse> put(
    String hash,
    List<int> bytes, {
    Session? as,
    String type = 'image/jpeg',
  }) => server.call(
    'put',
    '/receipts/$hash',
    bytes: bytes,
    token: (as ?? ada).access,
    contentType: type,
  );

  Future<TestResponse> get(String hash, {Session? as}) =>
      server.call('get', '/receipts/$hash', token: (as ?? ada).access);

  File fileOf(String hash) => server.app.receipts.fileOf(hash);

  test('a stored JPEG and PNG come back with their types', () async {
    final stored = await put(_sha(_jpeg), _jpeg);
    expect(stored.status, 200);
    expect(stored.json, {'sha256': _sha(_jpeg), 'size': _jpeg.length});
    final back = await get(_sha(_jpeg));
    expect(back.status, 200);
    expect(back.body, _jpeg);
    expect(back.headers['content-type'], 'image/jpeg');
    expect((await put(_sha(_png), _png, type: 'image/png')).status, 200);
    final png = await get(_sha(_png));
    expect(png.body, _png);
    expect(png.headers['content-type'], 'image/png');
    // The type comes from the bytes, not from what the upload said.
    final mislabelled = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 7];
    expect((await put(_sha(mislabelled), mislabelled)).status, 200);
    expect((await get(_sha(mislabelled))).headers['content-type'], 'image/png');
  });

  test('storing the same bytes again answers 200 and writes nothing', () async {
    final hash = _sha(_jpeg);
    expect((await put(hash, _jpeg)).status, 200);
    final written = fileOf(hash).lastModifiedSync();
    fileOf(hash).setLastModifiedSync(DateTime.utc(2020));
    final again = await put(hash, _jpeg);
    expect(again.status, 200);
    expect(again.json['size'], _jpeg.length);
    expect(fileOf(hash).lastModifiedSync(), DateTime.utc(2020).toLocal());
    expect(written.isAfter(DateTime.utc(2020)), isTrue);
    final rows = await server.app.db.read(
      (tx) =>
          tx.select('SELECT user_id FROM receipts WHERE sha256 = ?', [hash]),
    );
    expect(rows, hasLength(1));
  });

  test(
    'bytes that do not hash to the path are a 400 and leave nothing',
    () async {
      final hash = _sha(_png);
      final r = await put(hash, _jpeg);
      expect(r.status, 400);
      expect(r.code, 'validation_failed');
      expect(fileOf(hash).existsSync(), isFalse);
      expect((await get(hash)).status, 404);
    },
  );

  test(
    'more than 5 MiB is a 413, by the declared length or by the bytes',
    () async {
      final large = List<int>.filled(receiptCap + 1, 1);
      final byBytes = await put(_sha(large), large);
      expect(byBytes.status, 413);
      expect(byBytes.code, 'payload_too_large');
      // A declared length over the cap is refused before a byte is read.
      final declared = await server.app.handler(
        Request(
          'PUT',
          Uri.parse('http://localhost/v1/receipts/${_sha(_jpeg)}'),
          body: Stream.value(_jpeg),
          headers: {
            'content-type': 'image/jpeg',
            'content-length': '${receiptCap + 1}',
            'authorization': 'Bearer ${ada.access}',
          },
        ),
      );
      expect(declared.statusCode, 413);
      final exactly = List<int>.filled(receiptCap, 2);
      expect((await put(_sha(exactly), exactly)).status, 200);
    },
  );

  test('an empty body is a 400', () async {
    final empty = <int>[];
    final r = await put(_sha(empty), empty);
    expect(r.status, 400);
    expect(r.code, 'validation_failed');
  });

  test('a row whose file went missing is repaired by the next store', () async {
    final hash = _sha(_jpeg);
    expect((await put(hash, _jpeg)).status, 200);
    // As a deletion racing another user's store leaves it: the row, no file.
    fileOf(hash).deleteSync();
    expect((await get(hash)).status, 404);
    expect((await put(hash, _jpeg)).status, 200);
    expect(fileOf(hash).readAsBytesSync(), _jpeg);
    expect((await get(hash)).body, _jpeg);
    final rows = await server.app.db.read(
      (tx) =>
          tx.select('SELECT user_id FROM receipts WHERE sha256 = ?', [hash]),
    );
    expect(rows, hasLength(1));
  });

  test('another content type is a 415', () async {
    final r = await put(_sha(_jpeg), _jpeg, type: 'application/octet-stream');
    expect(r.status, 415);
    expect(r.code, 'unsupported_media_type');
  });

  test('a path that is not a sha256 is a 400, and builds no path', () async {
    for (final bad in [
      'ABC',
      '../../etc/passwd'.replaceAll('/', '%2F'),
      'g' * 64,
    ]) {
      expect((await put(bad, _jpeg)).status, 400, reason: bad);
      expect((await get(bad)).status, 400, reason: bad);
    }
    expect(() => fileOf('../x'), throwsArgumentError);
  });

  test(
    "another user's hash is a 404 until they store it, sharing the file",
    () async {
      final bob = await server.register('bob@example.com');
      final hash = _sha(_jpeg);
      expect((await put(hash, _jpeg)).status, 200);
      expect((await get(hash, as: bob)).status, 404);
      expect((await get('a' * 64)).status, 404);
      expect((await put(hash, _jpeg, as: bob)).status, 200);
      expect((await get(hash, as: bob)).body, _jpeg);
      expect(
        server.app.receipts.directory.listSync().whereType<File>(),
        hasLength(1),
      );
    },
  );

  test('another device of the same user reads it', () async {
    expect((await put(_sha(_jpeg), _jpeg)).status, 200);
    final tablet = await server.login();
    expect((await get(_sha(_jpeg), as: tablet)).body, _jpeg);
  });

  test('both routes need a bearer token', () async {
    final hash = _sha(_jpeg);
    expect(
      (await server.call(
        'put',
        '/receipts/$hash',
        bytes: _jpeg,
        contentType: 'image/jpeg',
      )).status,
      401,
    );
    expect((await server.call('get', '/receipts/$hash')).status, 401);
  });
}
