/// Starts the development server (`docs/reference/server.md`, **Running it**).
///
/// Run from `server/` (`tools/run_server.sh` does): reads `.env` and the environment,
/// opens and migrates the database at `DATABASE_PATH`, seeds the seed user when one is
/// configured, and serves `/v1` on `HOST:PORT`. Prints one line with the base URL and the
/// Plaid mode; in fake mode, a warning that Plaid data is synthetic and carries
/// `source: demo`. A bad configuration exits with status 78 and the key it names. Stop it
/// with Ctrl-C.
library;

import 'dart:async';
import 'dart:io';

import 'package:finance_tracker_server/server.dart';
import 'package:finance_tracker_server/src/auth/password_hasher.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final ServerConfig config;
  try {
    config = ServerConfig.fromValues(
      loadEnvironmentValues(
        envFile: File('.env'),
        environment: Platform.environment,
      ),
    );
  } on ConfigException catch (e) {
    stderr.writeln('Configuration error: ${e.message}');
    exitCode = 78;
    return;
  }
  final logs = configureLogging(config.logFormat, stdout);
  final db = AppDatabase.open(config.databasePath);
  final plaid = await FakePlaidClient.load(now: DateTime.now);
  final app = ServerApp(config: config, db: db, plaid: plaid);

  final seedEmail = config.seedUserEmail;
  if (seedEmail != null) {
    final created = await seedUser(
      db,
      PasswordHasher(config.argon2),
      email: seedEmail,
      password: config.seedUserPassword!,
      now: DateTime.now,
    );
    stdout.writeln(
      created
          ? 'Seeded the seed user (SEED_USER_EMAIL and SEED_USER_PASSWORD in .env)'
          : 'The seed user already exists; left unchanged',
    );
  }

  final server = await shelf_io.serve(app.handler, config.host, config.port);
  stdout.writeln(
    'Serving http://${server.address.host}:${server.port}/v1 '
    '(Plaid: ${config.plaidMode.name})',
  );
  stdout.writeln(
    'WARNING: fake Plaid mode. Plaid data is synthetic and carries source: demo.',
  );

  late final StreamSubscription<ProcessSignal> stop;
  stop = ProcessSignal.sigint.watch().listen((_) async {
    await stop.cancel();
    await server.close();
    await db.close();
    await logs.cancel();
  });
}
