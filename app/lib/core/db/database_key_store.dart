/// Where the database key is kept: Android Keystore-backed secure storage in the app, memory
/// in tests (`PLAN.md` §6.6, §12).
///
/// The key is 32 random bytes, hex-encoded (64 lowercase hex digits), applied to SQLite3
/// Multiple Ciphers as a raw key. `open_database.dart` decides what a missing key means:
/// created on the first launch, a [DatabaseKeyLostException] when a database file already
/// exists.
library;

import 'dart:math';

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Reads and creates the database key.
abstract interface class DatabaseKeyStore {
  /// The stored key, or null when there is none. Throws [DatabaseKeyLostException] when a
  /// key is stored but cannot be read.
  Future<String?> read();

  /// Creates a new key, stores it and returns it.
  Future<String> create();
}

/// A new key: 32 bytes from [Random.secure], as 64 lowercase hex digits.
String newDatabaseKey() {
  final Random random = Random.secure();
  return List<String>.generate(
    32,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// The key in `flutter_secure_storage` under `db_key_v1`.
///
/// `resetOnError` is off: its default would delete every stored value when one fails to
/// decrypt, losing the key and with it the database. A read failure is reported as a
/// [DatabaseKeyLostException] instead (`PLAN.md` §12).
final class SecureDatabaseKeyStore implements DatabaseKeyStore {
  /// The store over [storage], by default the app's secure storage.
  SecureDatabaseKeyStore([FlutterSecureStorage? storage])
    : _storage =
          storage ?? const FlutterSecureStorage(aOptions: androidOptions);

  /// The Android options the key is stored with.
  static const AndroidOptions androidOptions = AndroidOptions(
    resetOnError: false,
    storageNamespace: 'finance_tracker',
  );

  /// The name the key is stored under.
  static const String keyName = 'db_key_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: keyName);
    } on PlatformException catch (e) {
      throw DatabaseKeyLostException(e);
    }
  }

  @override
  Future<String> create() async {
    final String key = newDatabaseKey();
    await _storage.write(key: keyName, value: key);
    return key;
  }
}

/// A key held in memory, for tests.
final class InMemoryDatabaseKeyStore implements DatabaseKeyStore {
  /// A store holding [key], or none.
  InMemoryDatabaseKeyStore([this.key]);

  /// The stored key.
  String? key;

  @override
  Future<String?> read() async => key;

  @override
  Future<String> create() async => key = newDatabaseKey();
}
