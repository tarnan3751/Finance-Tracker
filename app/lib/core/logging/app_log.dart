/// Logging for the whole app, on `package:logging`'s root logger.
///
/// Each area logs through its own `Logger('<area>')`. In dev and demo every record is
/// printed to the console; in prod the last [recentLogCapacity] records are kept in memory
/// only, for the local crash log Phase 7 exports at the user's request (there is no
/// third-party crash reporting, `PLAN.md` §12).
///
/// The rule (`PLAN.md` §6.6): **never log an amount, a merchant, an account or
/// transaction description, or a token**, in any flavor. Log identifiers, counts and
/// states instead.
library;

import 'dart:async';
import 'dart:collection';

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// How many records prod keeps in memory.
const int recentLogCapacity = 500;

final Queue<LogRecord> _recent = Queue<LogRecord>();
StreamSubscription<LogRecord>? _subscription;

/// The records kept in memory, oldest first (prod only; empty in dev and demo).
List<LogRecord> recentLogRecords() => List<LogRecord>.unmodifiable(_recent);

/// Routes the root logger's records for [flavor]: printed in dev and demo, kept in
/// memory in prod. Calling it again replaces the previous routing.
void setUpLogging(Flavor flavor) {
  unawaited(_subscription?.cancel());
  _recent.clear();
  Logger.root.level = Level.ALL;
  _subscription = Logger.root.onRecord.listen(
    flavor == Flavor.prod ? _keep : _print,
  );
}

/// Forwards uncaught Flutter framework errors and uncaught asynchronous errors to the
/// `app` logger, after the framework's own reporting.
void forwardUncaughtErrors() {
  final Logger log = Logger('app');
  final FlutterExceptionHandler? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    log.severe('Uncaught Flutter error', details.exception, details.stack);
    previous?.call(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    log.severe('Uncaught error', error, stack);
    return true;
  };
}

void _keep(LogRecord record) {
  _recent.addLast(record);
  while (_recent.length > recentLogCapacity) {
    _recent.removeFirst();
  }
}

void _print(LogRecord record) {
  debugPrint(
    '${record.level.name} ${record.loggerName}: ${record.message}'
    '${record.error == null ? '' : ' ${record.error}'}',
  );
  if (record.stackTrace != null) debugPrint('${record.stackTrace}');
}
