/// The Finance Tracker development server (`docs/reference/server.md`).
///
/// [ServerApp] assembles the services and the route table behind `api/openapi.yaml`;
/// `bin/server.dart` reads the configuration, opens the database and serves its handler.
/// Tests build a [ServerApp] over an in-memory database and call its handler without
/// opening a socket.
library;

export 'src/app.dart' show ServerApp;
export 'src/config.dart';
export 'src/contract_version.dart';
export 'src/db/database.dart' show AppDatabase;
export 'src/logging.dart' show LogEvent, configureLogging, formatRecord;
export 'src/seed.dart';
