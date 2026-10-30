// The FTBK v1 header and frames: the header round-trips and its caps hold; frames of
// every boundary size round-trip; a flipped byte in any frame, a dropped, swapped or
// truncated frame, appended bytes and a wrong passphrase all fail with their typed
// error; the key is Argon2id then HKDF and depends on the passphrase as typed.
import 'dart:typed_data';

import 'package:finance_tracker/features/backup/domain/backup_cipher.dart';
import 'package:finance_tracker/features/backup/domain/backup_format.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tests' Argon2id cost: 8 MiB, one pass, one lane.
const KdfParameters testKdf = KdfParameters(
  memoryKiB: 8 * 1024,
  iterations: 1,
  parallelism: 1,
);

BackupHeader header() => BackupHeader(
  kdf: testKdf,
  salt: Uint8List.fromList(List<int>.generate(16, (i) => i)),
  baseNonce: Uint8List.fromList(List<int>.generate(24, (i) => 100 + i)),
);

Uint8List bytes(int length) =>
    Uint8List.fromList(List<int>.generate(length, (i) => (i * 31 + 7) % 256));

final Uint8List key = Uint8List.fromList(List<int>.generate(32, (i) => i * 3));

Uint8List withHeader(Uint8List file, void Function(ByteData data) change) {
  final Uint8List copy = Uint8List.fromList(file);
  change(ByteData.sublistView(copy));
  return copy;
}

void main() {
  group('header', () {
    test('round-trips', () {
      final BackupHeader read = BackupHeader.read(header().toBytes());
      expect(read.kdf, testKdf);
      expect(read.salt, header().salt);
      expect(read.baseNonce, header().baseNonce);
    });

    test('lays out the fields as the format table says', () {
      final Uint8List b = header().toBytes();
      final ByteData d = ByteData.sublistView(b);
      expect(b.length, backupHeaderLength);
      expect(b.sublist(0, 4), 'FTBK'.codeUnits);
      expect(d.getUint8(4), 1);
      expect(d.getUint8(5), 1);
      expect(d.getUint32(6), 8192);
      expect(d.getUint32(10), 1);
      expect(d.getUint32(14), 1);
      expect(b.sublist(18, 34), header().salt);
      expect(b.sublist(34, 58), header().baseNonce);
      expect(d.getUint32(58), 65536);
    });

    test('a short file or another magic is not a backup', () {
      final Uint8List b = header().toBytes();
      expect(
        () => BackupHeader.read(b.sublist(0, 61)),
        throwsA(isA<NotABackupException>()),
      );
      expect(
        () => BackupHeader.read(withHeader(b, (d) => d.setUint8(0, 0x47))),
        throwsA(isA<NotABackupException>()),
      );
    });

    test('a later format version is too new', () {
      expect(
        () => BackupHeader.read(
          withHeader(header().toBytes(), (d) => d.setUint8(4, 2)),
        ),
        throwsA(isA<BackupTooNewException>()),
      );
    });

    test('the KDF, its caps and the frame size are held', () {
      final Uint8List b = header().toBytes();
      for (final void Function(ByteData) change in <void Function(ByteData)>[
        (d) => d.setUint8(5, 2),
        (d) => d.setUint32(6, maxKdfMemoryKiB + 1),
        (d) => d.setUint32(10, 0),
        (d) => d.setUint32(10, maxKdfIterations + 1),
        (d) => d.setUint32(14, 0),
        (d) => d.setUint32(14, maxKdfParallelism + 1),
        (d) => d.setUint32(6, 7),
        (d) => d.setUint32(58, 4096),
      ]) {
        expect(
          () => BackupHeader.read(withHeader(b, change)),
          throwsA(isA<UnsafeBackupException>()),
        );
      }
      // The caps themselves are accepted.
      final BackupHeader capped = BackupHeader.read(
        withHeader(b, (d) {
          d
            ..setUint32(6, maxKdfMemoryKiB)
            ..setUint32(10, maxKdfIterations)
            ..setUint32(14, maxKdfParallelism);
        }),
      );
      expect(capped.kdf.memoryKiB, maxKdfMemoryKiB);
    });
  });

  group('frames', () {
    for (final int length in [0, 1, 65535, 65536, 65537, 3 * 65536 + 5]) {
      test('$length bytes round-trip in ${frameCount(length)} frames', () {
        final Uint8List plain = bytes(length);
        final List<(int, int)> sealed = [];
        final Uint8List file = sealFrames(
          plain,
          key,
          header(),
          onFrame: (done, total) => sealed.add((done, total)),
        );
        expect(
          file.length,
          backupHeaderLength + length + frameCount(length) * backupTagLength,
        );
        expect(sealed.last, (frameCount(length), frameCount(length)));
        expect(openFrames(file, key, BackupHeader.read(file)), plain);
      });
    }

    // Three frames: two full and a short last one.
    final Uint8List plain = bytes(2 * 65536 + 100);
    const int full = backupFrameSize + backupTagLength;
    late Uint8List file;
    setUp(() => file = sealFrames(plain, key, header()));

    Object? failure(Uint8List changed) {
      try {
        openFrames(changed, key, header());
        return null;
      } on BackupException catch (e) {
        return e;
      }
    }

    test('a flipped byte in the first frame reads as a wrong passphrase', () {
      final Uint8List changed = Uint8List.fromList(file);
      changed[backupHeaderLength + 10] ^= 1;
      expect(failure(changed), isA<WrongPassphraseException>());
    });

    test('a flipped byte in a later frame, or in a tag, is damage', () {
      for (final int at in [
        backupHeaderLength + full + 5,
        backupHeaderLength + 2 * full + 50,
        file.length - 1,
        backupHeaderLength + 2 * full - 1,
      ]) {
        final Uint8List changed = Uint8List.fromList(file);
        changed[at] ^= 0x80;
        expect(failure(changed), isA<BackupDamagedException>(), reason: '$at');
      }
    });

    test('a changed header fails the first frame (it is in every AAD)', () {
      final Uint8List changed = Uint8List.fromList(file);
      changed[40] ^= 1; // the base nonce
      expect(failure(changed), isA<WrongPassphraseException>());
    });

    test('a dropped last frame is damage', () {
      expect(
        failure(Uint8List.sublistView(file, 0, backupHeaderLength + 2 * full)),
        isA<BackupDamagedException>(),
      );
    });

    test('a file cut inside a frame is damage', () {
      expect(
        failure(Uint8List.sublistView(file, 0, file.length - 30)),
        isA<BackupDamagedException>(),
      );
      expect(
        failure(
          Uint8List.sublistView(file, 0, backupHeaderLength + full + 200),
        ),
        isA<BackupDamagedException>(),
      );
    });

    test(
      'a full last frame dropped leaves a file whose new last frame fails',
      () {
        // Two frames of an exactly full plaintext: a full frame and an empty last one.
        final Uint8List exact = sealFrames(bytes(65536), key, header());
        expect(
          failure(
            Uint8List.sublistView(exact, 0, exact.length - backupTagLength),
          ),
          isA<BackupDamagedException>(),
        );
      },
    );

    test('swapped frames are damage', () {
      final Uint8List swapped = Uint8List.fromList(file)
        ..setAll(
          backupHeaderLength,
          file.sublist(
            backupHeaderLength + full,
            backupHeaderLength + 2 * full,
          ),
        )
        ..setAll(
          backupHeaderLength + full,
          file.sublist(backupHeaderLength, backupHeaderLength + full),
        );
      expect(failure(swapped), isNotNull);
    });

    test('bytes appended are damage', () {
      final Uint8List longer = Uint8List(file.length + 40)..setAll(0, file);
      expect(failure(longer), isA<BackupDamagedException>());
    });

    test('another key fails the first frame', () {
      final Uint8List other = Uint8List.fromList(key)..[0] ^= 1;
      expect(
        () => openFrames(file, other, header()),
        throwsA(isA<WrongPassphraseException>()),
      );
    });
  });

  group('the key', () {
    test('a wrong passphrase reads as one', () async {
      final Uint8List right = await deriveFrameKey(
        'correct horse battery',
        header(),
      );
      final Uint8List sealed = sealFrames(bytes(1000), right, header());
      final Uint8List wrong = await deriveFrameKey(
        'correct horse batterY',
        header(),
      );
      expect(
        () => openFrames(sealed, wrong, header()),
        throwsA(isA<WrongPassphraseException>()),
      );
      expect(
        openFrames(
          sealed,
          await deriveFrameKey('correct horse battery', header()),
          header(),
        ),
        bytes(1000),
      );
    });

    test('is used as typed: no trimming, no normalization', () async {
      final Uint8List plain = await deriveFrameKey('passphrase é12', header());
      expect(await deriveFrameKey(' passphrase é12', header()), isNot(plain));
      // U+00E9 against e followed by U+0301: the same text, other bytes.
      expect(await deriveFrameKey('passphrase é12', header()), isNot(plain));
    });

    test('depends on the salt', () async {
      final BackupHeader other = BackupHeader(
        kdf: testKdf,
        salt: Uint8List(16),
        baseNonce: header().baseNonce,
      );
      expect(
        await deriveFrameKey('correct horse battery', other),
        isNot(await deriveFrameKey('correct horse battery', header())),
      );
    });
  });
}
