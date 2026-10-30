/// The `FTBK` file's encryption (`docs/reference/backup.md`, **The format**): the key
/// from the passphrase, and the plaintext sealed in frames.
///
/// - **The key.** Argon2id (`DartArgon2id`, pure Dart; it runs its lanes in isolates of
///   its own) over the passphrase's UTF-8 bytes, exactly as typed, with the header's
///   salt and parameters, gives a 32-byte master key; HKDF-SHA256 of it, salted with the
///   header's salt, with the info `FTBK v1 frames`, gives the frame key.
/// - **The frames.** The plaintext is cut into [backupFrameSize] chunks; every frame but
///   the last is full, and the last holds the rest, 0 to 65535 bytes (an empty one when
///   the plaintext fills its frames exactly), so a file always ends in a short frame.
///   Each is sealed with XChaCha20-Poly1305 under the frame key: its nonce is the base
///   nonce with the frame index (big-endian, 8 bytes) XORed into its last 8 bytes; its
///   associated data is the header, the index (8 bytes) and a last-frame flag (1 byte).
///   On disk a frame is its ciphertext then its 16-byte tag.
///
/// A changed byte anywhere, frames swapped or a frame dropped fail to authenticate; a
/// file cut at a frame boundary has no short last frame. A failure on the first frame
/// is [WrongPassphraseException] (the two causes look the same); any later one
/// [BackupDamagedException]. Pure Dart, no Flutter import.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:finance_tracker/features/backup/domain/backup_format.dart';

const DartXchacha20 _cipher = DartXchacha20.poly1305Aead();

/// The HKDF info of the frame key.
const String frameKeyInfo = 'FTBK v1 frames';

/// The frame key for [passphrase] under [header]: Argon2id, then HKDF-SHA256.
Future<Uint8List> deriveFrameKey(String passphrase, BackupHeader header) async {
  final DartArgon2id argon2id = DartArgon2id(
    memory: header.kdf.memoryKiB,
    iterations: header.kdf.iterations,
    parallelism: header.kdf.parallelism,
    hashLength: 32,
  );
  final SecretKey master = await argon2id.deriveKey(
    secretKey: SecretKey(utf8.encode(passphrase)),
    nonce: header.salt,
  );
  final SecretKeyData frameKey =
      await const DartHkdf(
        hmac: DartHmac(DartSha256()),
        outputLength: 32,
      ).deriveKey(
        secretKey: master,
        nonce: header.salt,
        info: utf8.encode(frameKeyInfo),
      );
  return Uint8List.fromList(frameKey.bytes);
}

/// How many frames a plaintext of [length] bytes takes.
int frameCount(int length) => length ~/ backupFrameSize + 1;

/// The file: [header] then [plaintext] sealed in frames under [frameKey]. [onFrame] is
/// told after each frame, with the number done and the total.
Uint8List sealFrames(
  Uint8List plaintext,
  Uint8List frameKey,
  BackupHeader header, {
  void Function(int done, int total)? onFrame,
}) {
  final Uint8List headerBytes = header.toBytes();
  final int frames = frameCount(plaintext.length);
  final Uint8List file = Uint8List(
    backupHeaderLength + plaintext.length + frames * backupTagLength,
  )..setAll(0, headerBytes);
  final SecretKeyData key = SecretKeyData(frameKey);
  int at = backupHeaderLength;
  for (int i = 0; i < frames; i++) {
    final bool last = i == frames - 1;
    final int start = i * backupFrameSize;
    final int end = last ? plaintext.length : start + backupFrameSize;
    final SecretBox box = _cipher.encryptSync(
      Uint8List.sublistView(plaintext, start, end),
      secretKey: key,
      nonce: _frameNonce(header.baseNonce, i),
      aad: _frameAad(headerBytes, i, last: last),
    );
    file
      ..setAll(at, box.cipherText)
      ..setAll(at + box.cipherText.length, box.mac.bytes);
    at += box.cipherText.length + backupTagLength;
    onFrame?.call(i + 1, frames);
  }
  return file;
}

/// The plaintext of [file] (its header is [header]) under [frameKey], every frame
/// authenticated. Throws [WrongPassphraseException] when the first frame does not
/// authenticate and [BackupDamagedException] when a later one does not or the frames are
/// incomplete. [onFrame] is told after each frame.
Uint8List openFrames(
  Uint8List file,
  Uint8List frameKey,
  BackupHeader header, {
  void Function(int done, int total)? onFrame,
}) {
  const int full = backupFrameSize + backupTagLength;
  final int body = file.length - backupHeaderLength;
  final int fullFrames = body ~/ full;
  final int lastLength = body % full;
  // Every file ends in a short frame of at least its tag: none means it was cut.
  if (lastLength < backupTagLength) throw const BackupDamagedException();
  final int frames = fullFrames + 1;
  final Uint8List headerBytes = Uint8List.sublistView(
    file,
    0,
    backupHeaderLength,
  );
  final SecretKeyData key = SecretKeyData(frameKey);
  final BytesBuilder plaintext = BytesBuilder(copy: false);
  for (int i = 0; i < frames; i++) {
    final bool last = i == frames - 1;
    final int start = backupHeaderLength + i * full;
    final int length = last ? lastLength : full;
    final int tagAt = start + length - backupTagLength;
    try {
      plaintext.add(
        _cipher.decryptSync(
          SecretBox(
            Uint8List.sublistView(file, start, tagAt),
            nonce: _frameNonce(header.baseNonce, i),
            mac: Mac(Uint8List.sublistView(file, tagAt, start + length)),
          ),
          secretKey: key,
          aad: _frameAad(headerBytes, i, last: last),
        ),
      );
    } on SecretBoxAuthenticationError {
      if (i == 0) throw const WrongPassphraseException();
      throw const BackupDamagedException();
    }
    onFrame?.call(i + 1, frames);
  }
  return plaintext.takeBytes();
}

Uint8List _frameNonce(Uint8List baseNonce, int index) {
  final Uint8List nonce = Uint8List.fromList(baseNonce);
  final ByteData counter = ByteData(8)..setUint64(0, index);
  for (int i = 0; i < 8; i++) {
    nonce[backupNonceLength - 8 + i] ^= counter.getUint8(i);
  }
  return nonce;
}

Uint8List _frameAad(Uint8List header, int index, {required bool last}) {
  final Uint8List aad = Uint8List(header.length + 9)..setAll(0, header);
  ByteData.sublistView(aad)
    ..setUint64(header.length, index)
    ..setUint8(header.length + 8, last ? 1 : 0);
  return aad;
}
