/// The server's configuration (`docs/reference/server.md`, **Configuration**).
///
/// Read from `server/.env` when it exists, with `Platform.environment` overriding it key by
/// key. The `.env` reader is hand-written: `KEY=VALUE` lines, `#` comments and blank lines,
/// no quoting and no interpolation. An empty value counts as unset. A missing or malformed
/// required key is a [ConfigException] naming the key; no secret ever has a default, and no
/// error message ever carries a value.
library;

import 'dart:convert';
import 'dart:io';

/// A configuration the server refuses to start with.
final class ConfigException implements Exception {
  /// An error described by [message], which names the key but never its value.
  const ConfigException(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'ConfigException: $message';
}

/// Which `PlaidClient` the server uses. Phase 2 knows only [fake]; `sandbox` arrives with
/// the real client in Phase 3 and is refused until then.
enum PlaidMode { fake }

/// How log records are written: one JSON object per line, or a line for a terminal.
enum LogFormat { json, text }

/// The Argon2id cost parameters for new password hashes.
final class Argon2Parameters {
  /// [memoryKib] KiB of memory, [iterations] passes and [parallelism] lanes; [memoryKib]
  /// must be at least eight times [parallelism].
  const Argon2Parameters({
    required this.memoryKib,
    required this.iterations,
    required this.parallelism,
  });

  /// The OWASP baseline: 19 MiB, two iterations, one lane.
  static const owaspBaseline = Argon2Parameters(
    memoryKib: 19456,
    iterations: 2,
    parallelism: 1,
  );

  /// Memory in KiB (`m`).
  final int memoryKib;

  /// Passes over memory (`t`).
  final int iterations;

  /// Lanes (`p`).
  final int parallelism;
}

/// Everything the server reads at startup.
final class ServerConfig {
  /// A configuration; tests build one directly.
  const ServerConfig({
    this.port = 8080,
    this.host = '127.0.0.1',
    this.databasePath = 'data/finance_tracker.db',
    required this.jwtSecret,
    this.jwtSecretPrevious,
    required this.tokenEncryptionKey,
    this.plaidClientId,
    this.plaidSecret,
    this.plaidEnv = 'sandbox',
    this.plaidMode = PlaidMode.fake,
    this.seedUserEmail,
    this.seedUserPassword,
    this.argon2 = Argon2Parameters.owaspBaseline,
    this.logFormat = LogFormat.json,
  });

  /// Reads [values] (the `.env` file merged with the environment, see
  /// [loadEnvironmentValues]).
  factory ServerConfig.fromValues(Map<String, String> values) {
    String? value(String key) {
      final v = values[key]?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    int integer(String key, int fallback, {required int min, int? max}) {
      final text = value(key);
      if (text == null) return fallback;
      final parsed = int.tryParse(text);
      if (parsed == null || parsed < min || (max != null && parsed > max)) {
        throw ConfigException(
          '$key must be an integer from $min${max == null ? ' up' : ' to $max'}',
        );
      }
      return parsed;
    }

    List<int> key(
      String name, {
      int? exactly,
      int? atLeast,
      bool required = true,
    }) {
      final text = value(name);
      if (text == null) {
        if (!required) return const [];
        throw ConfigException('$name is required');
      }
      final List<int> bytes;
      try {
        bytes = base64.decode(text);
      } on FormatException {
        throw ConfigException('$name is not valid base64');
      }
      if (exactly != null && bytes.length != exactly) {
        throw ConfigException('$name must decode to exactly $exactly bytes');
      }
      if (atLeast != null && bytes.length < atLeast) {
        throw ConfigException('$name must decode to at least $atLeast bytes');
      }
      return bytes;
    }

    final host = value('HOST') ?? '127.0.0.1';
    if (InternetAddress.tryParse(host) == null) {
      throw const ConfigException('HOST must be an IP address');
    }

    final mode = value('PLAID_MODE') ?? 'fake';
    if (mode == 'sandbox') {
      throw const ConfigException(
        'PLAID_MODE=sandbox needs the real Plaid client, which arrives in Phase 3; '
        'use PLAID_MODE=fake',
      );
    }
    if (mode != 'fake') throw const ConfigException('PLAID_MODE must be fake');

    final seedEmail = value('SEED_USER_EMAIL');
    final seedPassword = value('SEED_USER_PASSWORD');
    if ((seedEmail == null) != (seedPassword == null)) {
      throw const ConfigException(
        'SEED_USER_EMAIL and SEED_USER_PASSWORD are set together or not at all',
      );
    }
    if (seedEmail != null &&
        !RegExp(r'^[^@\s]+@[^@\s.]+(\.[^@\s.]+)+$').hasMatch(seedEmail)) {
      throw const ConfigException('SEED_USER_EMAIL must be an email address');
    }
    if (seedPassword != null && seedPassword.runes.length < 8) {
      throw const ConfigException(
        'SEED_USER_PASSWORD must be at least 8 characters',
      );
    }

    final parallelism = integer('ARGON2_PARALLELISM', 1, min: 1, max: 16);
    final memory = integer('ARGON2_MEMORY_KIB', 19456, min: 8);
    if (memory < 8 * parallelism) {
      throw const ConfigException(
        'ARGON2_MEMORY_KIB must be at least 8 times ARGON2_PARALLELISM',
      );
    }

    final format = value('LOG_FORMAT') ?? 'json';
    final logFormat = switch (format) {
      'json' => LogFormat.json,
      'text' => LogFormat.text,
      _ => throw const ConfigException('LOG_FORMAT must be json or text'),
    };

    final previous = key('JWT_SECRET_PREVIOUS', atLeast: 32, required: false);
    return ServerConfig(
      port: integer('PORT', 8080, min: 1, max: 65535),
      host: host,
      databasePath: value('DATABASE_PATH') ?? 'data/finance_tracker.db',
      jwtSecret: key('JWT_SECRET', atLeast: 32),
      jwtSecretPrevious: previous.isEmpty ? null : previous,
      tokenEncryptionKey: key('TOKEN_ENCRYPTION_KEY', exactly: 32),
      plaidClientId: value('PLAID_CLIENT_ID'),
      plaidSecret: value('PLAID_SECRET'),
      plaidEnv: value('PLAID_ENV') ?? 'sandbox',
      plaidMode: PlaidMode.fake,
      seedUserEmail: seedEmail,
      seedUserPassword: seedPassword,
      argon2: Argon2Parameters(
        memoryKib: memory,
        iterations: integer('ARGON2_ITERATIONS', 2, min: 1),
        parallelism: parallelism,
      ),
      logFormat: logFormat,
    );
  }

  /// The port to listen on (`PORT`).
  final int port;

  /// The address to bind (`HOST`): loopback unless a physical device must reach the server.
  final String host;

  /// The SQLite file (`DATABASE_PATH`), relative to the working directory (`server/`).
  final String databasePath;

  /// The key access tokens are signed with (`JWT_SECRET`).
  final List<int> jwtSecret;

  /// A previous signing key still accepted for verification (`JWT_SECRET_PREVIOUS`).
  final List<int>? jwtSecretPrevious;

  /// The AES-256-GCM key for Plaid access tokens at rest (`TOKEN_ENCRYPTION_KEY`).
  final List<int> tokenEncryptionKey;

  /// Plaid's client id (`PLAID_CLIENT_ID`); unused in fake mode.
  final String? plaidClientId;

  /// Plaid's secret (`PLAID_SECRET`); unused in fake mode.
  final String? plaidSecret;

  /// Plaid's environment (`PLAID_ENV`).
  final String plaidEnv;

  /// Which Plaid client to use (`PLAID_MODE`).
  final PlaidMode plaidMode;

  /// The user seeded at startup (`SEED_USER_EMAIL`), or null.
  final String? seedUserEmail;

  /// The seeded user's password (`SEED_USER_PASSWORD`), or null.
  final String? seedUserPassword;

  /// The Argon2id parameters for new hashes (`ARGON2_*`).
  final Argon2Parameters argon2;

  /// The log line format (`LOG_FORMAT`).
  final LogFormat logFormat;
}

/// Parses `.env` text into a map. A line that is neither blank, a `#` comment nor
/// `KEY=VALUE` with an upper-case key is a [ConfigException] naming its line number; a
/// later line for the same key wins.
Map<String, String> parseEnvFile(String text) {
  final values = <String, String>{};
  final keyPattern = RegExp(r'^[A-Z][A-Z0-9_]*$');
  final lines = const LineSplitter().convert(text);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eq = line.indexOf('=');
    final key = eq < 0 ? '' : line.substring(0, eq).trim();
    if (!keyPattern.hasMatch(key)) {
      throw ConfigException('.env line ${i + 1} is not KEY=VALUE');
    }
    values[key] = line.substring(eq + 1).trim();
  }
  return values;
}

/// The `.env` file at [envFile] (when it exists) overlaid with [environment].
Map<String, String> loadEnvironmentValues({
  required File envFile,
  required Map<String, String> environment,
}) => {
  if (envFile.existsSync()) ...parseEnvFile(envFile.readAsStringSync()),
  ...environment,
};
