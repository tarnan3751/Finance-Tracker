// The command line: arguments, files written, errors.
import 'dart:io';

import 'package:test/test.dart';

import '../bin/persona_engine.dart' as cli;

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('persona_cli'));
  tearDown(() => dir.delete(recursive: true));

  Future<(int, String, String)> run(List<String> args) async {
    final out = File('${dir.path}/out.txt').openWrite();
    final err = File('${dir.path}/err.txt').openWrite();
    final code = await cli.run(args, out, err);
    await out.close();
    await err.close();
    return (
      code,
      File('${dir.path}/out.txt').readAsStringSync(),
      File('${dir.path}/err.txt').readAsStringSync(),
    );
  }

  test('--format all writes every output for the persona', () async {
    final (code, out, _) = await run([
      '--persona',
      'small_business',
      '--seed',
      '1',
      '--output',
      dir.path,
      '--days',
      '30',
    ]);
    expect(code, 0);
    final names = Directory(
      '${dir.path}/small_business',
    ).listSync().map((f) => f.uri.pathSegments.last).toList()..sort();
    expect(names, [
      'demo_seed.json',
      'sandbox_manifest.json',
      'sandbox_user_gingham.json',
      'sandbox_user_platypus.json',
    ]);
    expect(out, contains('demo_seed.json'));
  });

  test('one format, the as-of date and the interest switch', () async {
    final (code, _, _) = await run([
      '--persona',
      'renter',
      '--seed',
      '3',
      '--output',
      dir.path,
      '--format',
      'sandbox-user',
      '--as-of',
      '2026-01-31',
      '--no-interest-legs',
    ]);
    expect(code, 0);
    final names = Directory(
      '${dir.path}/renter',
    ).listSync().map((f) => f.uri.pathSegments.last).toList()..sort();
    expect(names, ['sandbox_manifest.json', 'sandbox_user_platypus.json']);
    final manifest = File('${dir.path}/renter/sandbox_manifest.json')
        .readAsStringSync();
    expect(manifest, contains('"as_of": "2026-01-31"'));
    expect(manifest, contains('"include_interest_legs": false'));
  });

  test('bad arguments exit 64 with the usage', () async {
    for (final args in [
      ['--persona', 'pirate', '--seed', '1', '--output', dir.path],
      ['--persona', 'renter', '--seed', 'x', '--output', dir.path],
      [
        '--persona',
        'renter',
        '--seed',
        '1',
        '--output',
        dir.path,
        '--days',
        '731',
      ],
      [
        '--persona',
        'renter',
        '--seed',
        '1',
        '--output',
        dir.path,
        '--as-of',
        '2026-13-01',
      ],
      ['--persona', 'renter', '--seed', '1'],
    ]) {
      final (code, _, err) = await run(args);
      expect(code, 64, reason: '$args');
      expect(err, contains('--persona'), reason: '$args');
    }
  });
}
