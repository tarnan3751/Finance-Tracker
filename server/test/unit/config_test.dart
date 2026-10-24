import 'dart:convert';

import 'package:finance_tracker_server/server.dart';
import 'package:test/test.dart';

final _key32 = base64.encode(List.filled(32, 1));

Map<String, String> _valid([Map<String, String> more = const {}]) => {
  'JWT_SECRET': _key32,
  'TOKEN_ENCRYPTION_KEY': _key32,
  ...more,
};

Matcher _error(String key) => throwsA(
  isA<ConfigException>().having((e) => e.message, 'message', contains(key)),
);

void main() {
  test('defaults', () {
    final c = ServerConfig.fromValues(_valid());
    expect(c.port, 8080);
    expect(c.host, '127.0.0.1');
    expect(c.databasePath, 'data/finance_tracker.db');
    expect(c.plaidMode, PlaidMode.fake);
    expect(c.plaidEnv, 'sandbox');
    expect(c.argon2.memoryKib, 19456);
    expect(c.argon2.iterations, 2);
    expect(c.argon2.parallelism, 1);
    expect(c.logFormat, LogFormat.json);
    expect(c.seedUserEmail, isNull);
    expect(c.jwtSecretPrevious, isNull);
  });

  test('reads every key', () {
    final c = ServerConfig.fromValues(
      _valid({
        'PORT': '9090',
        'HOST': '0.0.0.0',
        'DATABASE_PATH': '/tmp/x.db',
        'JWT_SECRET_PREVIOUS': base64.encode(List.filled(40, 2)),
        'SEED_USER_EMAIL': 'dev@example.test',
        'SEED_USER_PASSWORD': 'a long password',
        'ARGON2_MEMORY_KIB': '64',
        'ARGON2_ITERATIONS': '1',
        'ARGON2_PARALLELISM': '2',
        'LOG_FORMAT': 'text',
      }),
    );
    expect(c.port, 9090);
    expect(c.host, '0.0.0.0');
    expect(c.databasePath, '/tmp/x.db');
    expect(c.jwtSecretPrevious, hasLength(40));
    expect(c.seedUserEmail, 'dev@example.test');
    expect(c.argon2.parallelism, 2);
    expect(c.logFormat, LogFormat.text);
  });

  test('a missing secret is an error naming it, never a default', () {
    expect(
      () => ServerConfig.fromValues({'TOKEN_ENCRYPTION_KEY': _key32}),
      _error('JWT_SECRET'),
    );
    expect(
      () => ServerConfig.fromValues({
        'JWT_SECRET': _key32,
        'TOKEN_ENCRYPTION_KEY': '',
      }),
      _error('TOKEN_ENCRYPTION_KEY'),
    );
  });

  test('bad base64 and wrong key lengths are errors without the value', () {
    expect(
      () => ServerConfig.fromValues(_valid({'JWT_SECRET': 'not base64!!'})),
      throwsA(
        isA<ConfigException>()
            .having((e) => e.message, 'message', contains('JWT_SECRET'))
            .having(
              (e) => e.message,
              'message',
              isNot(contains('not base64!!')),
            ),
      ),
    );
    expect(
      () => ServerConfig.fromValues(
        _valid({'JWT_SECRET': base64.encode(List.filled(31, 1))}),
      ),
      _error('JWT_SECRET'),
    );
    for (final n in [31, 33]) {
      expect(
        () => ServerConfig.fromValues(
          _valid({'TOKEN_ENCRYPTION_KEY': base64.encode(List.filled(n, 1))}),
        ),
        _error('TOKEN_ENCRYPTION_KEY'),
      );
    }
  });

  test('PLAID_MODE=sandbox needs both keys and never echoes them', () {
    expect(
      () => ServerConfig.fromValues(
        _valid({'PLAID_MODE': 'sandbox', 'PLAID_SECRET': 'secret-value'}),
      ),
      throwsA(
        isA<ConfigException>()
            .having((e) => e.message, 'message', contains('PLAID_CLIENT_ID'))
            .having(
              (e) => e.message,
              'message',
              isNot(contains('secret-value')),
            ),
      ),
    );
    expect(
      () => ServerConfig.fromValues(
        _valid({'PLAID_MODE': 'sandbox', 'PLAID_CLIENT_ID': 'client-value'}),
      ),
      throwsA(
        isA<ConfigException>()
            .having((e) => e.message, 'message', contains('PLAID_SECRET'))
            .having(
              (e) => e.message,
              'message',
              isNot(contains('client-value')),
            ),
      ),
    );
    final c = ServerConfig.fromValues(
      _valid({
        'PLAID_MODE': 'sandbox',
        'PLAID_CLIENT_ID': 'client-value',
        'PLAID_SECRET': 'secret-value',
        'PLAID_WEBHOOK_URL': 'https://tunnel.example/v1/webhooks/plaid',
      }),
    );
    expect(c.plaidMode, PlaidMode.sandbox);
    expect(c.plaidClientId, 'client-value');
    expect(c.plaidSecret, 'secret-value');
    expect(c.plaidWebhookUrl, 'https://tunnel.example/v1/webhooks/plaid');
  });

  test('PLAID_ENV and PLAID_WEBHOOK_URL are checked', () {
    for (final env in ['sandbox', 'development', 'production']) {
      expect(ServerConfig.fromValues(_valid({'PLAID_ENV': env})).plaidEnv, env);
    }
    expect(
      () => ServerConfig.fromValues(_valid({'PLAID_ENV': 'sandbx'})),
      _error('PLAID_ENV'),
    );
    for (final url in [
      'http://tunnel.example/hook',
      'tunnel.example/hook',
      'https://',
    ]) {
      expect(
        () => ServerConfig.fromValues(_valid({'PLAID_WEBHOOK_URL': url})),
        _error('PLAID_WEBHOOK_URL'),
        reason: url,
      );
    }
    expect(ServerConfig.fromValues(_valid()).plaidWebhookUrl, isNull);
  });

  test('PLAID_MODE is fake or sandbox', () {
    expect(
      () => ServerConfig.fromValues(_valid({'PLAID_MODE': 'live'})),
      _error('PLAID_MODE'),
    );
  });

  test('the seed keys come together', () {
    expect(
      () => ServerConfig.fromValues(_valid({'SEED_USER_EMAIL': 'a@b.test'})),
      _error('SEED_USER'),
    );
    expect(
      () =>
          ServerConfig.fromValues(_valid({'SEED_USER_PASSWORD': 'longenough'})),
      _error('SEED_USER'),
    );
  });

  test('a seed email that is not an email address names the key', () {
    expect(
      () => ServerConfig.fromValues(
        _valid({'SEED_USER_EMAIL': 'dev', 'SEED_USER_PASSWORD': 'longenough'}),
      ),
      _error('SEED_USER_EMAIL'),
    );
  });

  test('malformed numbers, hosts and formats name their key', () {
    for (final (key, value) in [
      ('PORT', '0'),
      ('PORT', 'eighty'),
      ('HOST', 'localhost'),
      ('ARGON2_ITERATIONS', '0'),
      ('ARGON2_MEMORY_KIB', '4'),
      ('LOG_FORMAT', 'xml'),
    ]) {
      expect(() => ServerConfig.fromValues(_valid({key: value})), _error(key));
    }
  });

  group('the .env reader', () {
    test('reads KEY=VALUE, skips comments and blanks', () {
      expect(
        parseEnvFile(
          '# comment\n\nPORT=9000\n  HOST = 0.0.0.0  \nEMPTY=\nX=a=b\n',
        ),
        {'PORT': '9000', 'HOST': '0.0.0.0', 'EMPTY': '', 'X': 'a=b'},
      );
    });

    test('a malformed line names its number, not its content', () {
      expect(
        () => parseEnvFile('PORT=1\nsecret-value\n'),
        throwsA(
          isA<ConfigException>()
              .having((e) => e.message, 'message', contains('line 2'))
              .having((e) => e.message, 'message', isNot(contains('secret'))),
        ),
      );
    });

    test('the environment overrides the file', () {
      final c = ServerConfig.fromValues({
        ...parseEnvFile(
          'PORT=1000\nJWT_SECRET=$_key32\nTOKEN_ENCRYPTION_KEY=$_key32',
        ),
        ...{'PORT': '2000'},
      });
      expect(c.port, 2000);
    });
  });
}
