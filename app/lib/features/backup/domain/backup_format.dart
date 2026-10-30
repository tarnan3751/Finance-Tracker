/// The `FTBK` backup file's header and the failures a backup reports
/// (`docs/reference/backup.md`, **The format**; `PLAN.md` §12, "Backup archive").
///
/// A backup file is a 62-byte header followed by frames. The header, big-endian:
///
/// | Offset | Size | Field |
/// |---|---|---|
/// | 0 | 4 | magic `FTBK` |
/// | 4 | 1 | format version, 1 |
/// | 5 | 1 | KDF id, 1 (Argon2id version 1.3) |
/// | 6 | 4 | Argon2id memory, KiB |
/// | 10 | 4 | Argon2id iterations |
/// | 14 | 4 | Argon2id parallelism |
/// | 18 | 16 | salt |
/// | 34 | 24 | base nonce |
/// | 58 | 4 | frame size, 65536 |
///
/// The whole header is part of every frame's associated data (`backup_cipher.dart`). A
/// file read back is held to caps, so a hostile header cannot make the import allocate or
/// work without bound. Pure Dart, no Flutter import.
library;

import 'dart:typed_data';

/// The magic, `FTBK`.
const List<int> backupMagic = [0x46, 0x54, 0x42, 0x4b];

/// The format version this build writes and the only one it reads.
const int backupFormatVersion = 1;

/// The KDF id of Argon2id, version 1.3.
const int argon2idKdfId = 1;

/// The plaintext bytes of every frame but the last.
const int backupFrameSize = 65536;

/// The bytes of the Poly1305 tag that ends every frame.
const int backupTagLength = 16;

/// The header's length.
const int backupHeaderLength = 62;

/// The salt's length.
const int backupSaltLength = 16;

/// The base nonce's length (XChaCha20's).
const int backupNonceLength = 24;

/// The largest Argon2id memory an import accepts, KiB (128 MiB). The caps are twice the
/// standard cost in every dimension: a hostile header costs the KDF's time and memory
/// before anything authenticates, with no way to cancel it yet.
const int maxKdfMemoryKiB = 128 * 1024;

/// The most Argon2id iterations an import accepts.
const int maxKdfIterations = 6;

/// The most Argon2id lanes an import accepts.
const int maxKdfParallelism = 8;

/// The largest backup file a restore reads, bytes (512 MiB).
const int maxBackupBytes = 512 * 1024 * 1024;

/// Argon2id's cost: memory in KiB, iterations, parallelism.
final class KdfParameters {
  /// The parameters.
  const KdfParameters({
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
  });

  /// What an export uses: 64 MiB, 3 iterations, 4 lanes (RFC 9106's second
  /// recommendation), measured on the harness AVD (`backup.md`, **The format**).
  static const KdfParameters standard = KdfParameters(
    memoryKiB: 64 * 1024,
    iterations: 3,
    parallelism: 4,
  );

  /// Memory, KiB.
  final int memoryKiB;

  /// Iterations (Argon2's t).
  final int iterations;

  /// Lanes (Argon2's p).
  final int parallelism;

  @override
  bool operator ==(Object other) =>
      other is KdfParameters &&
      other.memoryKiB == memoryKiB &&
      other.iterations == iterations &&
      other.parallelism == parallelism;

  @override
  int get hashCode => Object.hash(memoryKiB, iterations, parallelism);

  @override
  String toString() =>
      'KdfParameters(m: $memoryKiB KiB, t: $iterations, p: $parallelism)';
}

/// A backup file's header.
final class BackupHeader {
  /// A header of [kdf], [salt] (16 bytes) and [baseNonce] (24 bytes).
  BackupHeader({
    required this.kdf,
    required Uint8List salt,
    required Uint8List baseNonce,
  }) : salt = Uint8List.fromList(salt),
       baseNonce = Uint8List.fromList(baseNonce) {
    if (salt.length != backupSaltLength) {
      throw ArgumentError.value(salt.length, 'salt', 'must be 16 bytes');
    }
    if (baseNonce.length != backupNonceLength) {
      throw ArgumentError.value(
        baseNonce.length,
        'baseNonce',
        'must be 24 bytes',
      );
    }
  }

  /// Reads the header at the start of [file]. Throws [NotABackupException] when [file]
  /// is too short or does not start with the magic, [BackupTooNewException] for a later
  /// format version, and [UnsafeBackupException] for another KDF, a parameter over its
  /// cap (or under Argon2's own minimum) or another frame size.
  factory BackupHeader.read(Uint8List file) {
    if (file.length < backupHeaderLength) throw const NotABackupException();
    for (int i = 0; i < backupMagic.length; i++) {
      if (file[i] != backupMagic[i]) throw const NotABackupException();
    }
    final ByteData data = ByteData.sublistView(file, 0, backupHeaderLength);
    if (data.getUint8(4) != backupFormatVersion) {
      throw const BackupTooNewException();
    }
    if (data.getUint8(5) != argon2idKdfId) throw const UnsafeBackupException();
    final KdfParameters kdf = KdfParameters(
      memoryKiB: data.getUint32(6),
      iterations: data.getUint32(10),
      parallelism: data.getUint32(14),
    );
    if (kdf.memoryKiB > maxKdfMemoryKiB ||
        kdf.iterations < 1 ||
        kdf.iterations > maxKdfIterations ||
        kdf.parallelism < 1 ||
        kdf.parallelism > maxKdfParallelism ||
        kdf.memoryKiB < 8 * kdf.parallelism ||
        data.getUint32(58) != backupFrameSize) {
      throw const UnsafeBackupException();
    }
    return BackupHeader(
      kdf: kdf,
      salt: Uint8List.sublistView(file, 18, 34),
      baseNonce: Uint8List.sublistView(file, 34, 58),
    );
  }

  /// Argon2id's parameters.
  final KdfParameters kdf;

  /// The Argon2id salt, also HKDF's.
  final Uint8List salt;

  /// The nonce every frame's nonce derives from.
  final Uint8List baseNonce;

  /// The header's 62 bytes.
  Uint8List toBytes() {
    final Uint8List bytes = Uint8List(backupHeaderLength);
    final ByteData data = ByteData.sublistView(bytes);
    bytes.setAll(0, backupMagic);
    data
      ..setUint8(4, backupFormatVersion)
      ..setUint8(5, argon2idKdfId)
      ..setUint32(6, kdf.memoryKiB)
      ..setUint32(10, kdf.iterations)
      ..setUint32(14, kdf.parallelism)
      ..setUint32(58, backupFrameSize);
    bytes
      ..setAll(18, salt)
      ..setAll(34, baseNonce);
    return bytes;
  }
}

/// Why a backup could not be made or restored, each with its own message on the screen.
sealed class BackupException implements Exception {
  const BackupException();

  @override
  String toString() => runtimeType.toString();
}

/// The file is not a backup: too short, or no `FTBK` magic.
final class NotABackupException extends BackupException {
  const NotABackupException();
}

/// The backup was made by a newer version of the app: a later format version, or a
/// schema version above this build's.
final class BackupTooNewException extends BackupException {
  const BackupTooNewException();
}

/// The header asks for another KDF, a cost over the caps or another frame size.
final class UnsafeBackupException extends BackupException {
  const UnsafeBackupException();
}

/// The first frame does not authenticate: the passphrase is wrong, or the file is
/// damaged at its start (the two cannot be told apart).
final class WrongPassphraseException extends BackupException {
  const WrongPassphraseException();
}

/// The file is damaged or incomplete: a later frame does not authenticate, frames are
/// missing, or the content inside does not read back as a backup.
final class BackupDamagedException extends BackupException {
  const BackupDamagedException();
}

/// The file is over [maxBackupBytes]: it is not read.
final class BackupTooLargeException extends BackupException {
  const BackupTooLargeException();
}

/// The backup belongs to another account than this install's.
final class BackupOtherAccountException extends BackupException {
  const BackupOtherAccountException();
}

/// The install already has data, and a restore never merges into it.
final class InstallHasDataException extends BackupException {
  const InstallHasDataException();
}

/// The backup's content cannot be stored in this database (a constraint or a foreign
/// key fails); nothing was imported.
final class BackupImportFailedException extends BackupException {
  const BackupImportFailedException();
}
