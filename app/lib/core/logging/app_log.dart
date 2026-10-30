/// Logging for the whole app, on `package:logging`'s root logger.
///
/// Each area logs through its own `Logger('<area>')`. In dev and demo every record is
/// printed to the console; in prod a sanitised copy of the last [recentLogCapacity]
/// records is kept in memory only, for the local crash log Phase 7 exports at the user's
/// request (there is no third-party crash reporting, `PLAN.md` §12).
///
/// The rule (`PLAN.md` §6.6): **never log an amount, a merchant, an account or
/// transaction description, or a token**, in any flavor. Log identifiers, counts and
/// states instead. The prod sink is the second line of defence ([sanitizedRecord]): it
/// scrubs what a pattern can find from the message (tokens, emails, key material), keeps
/// an error's type but not its text (an exception's `toString` can carry an amount or a
/// merchant), and keeps a logged object's type in place of its text; the stack trace
/// stays.
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
  _recent.addLast(sanitizedRecord(record));
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

/// What the prod sink keeps of [record]: its level, logger, zone and stack trace; its
/// message with every match of [_secretPatterns] replaced by `[redacted]`, or, when the
/// message was an object's `toString` (a logged non-string), that object's runtime type;
/// its error as the error's runtime type only; no object. The copy has a time and sequence number of its
/// own, taken at once (the root logger's stream is synchronous).
LogRecord sanitizedRecord(LogRecord record) => LogRecord(
  record.level,
  record.object == null
      ? scrubLogText(record.message)
      : '${record.object.runtimeType}',
  record.loggerName,
  record.error == null ? null : _ErrorType(record.error.runtimeType),
  record.stackTrace,
  record.zone,
);

/// [text] with every bearer token, JWT, Plaid access, public and link token, email
/// address (Unicode letters included), SQL hex key literal (`x'` and 8 or more hex
/// digits), run of 32 or more hex digits and run of 40 or more base64url or base64
/// characters holding an uppercase letter, a lowercase letter and a digit (the server's
/// refresh tokens, base64 keys; not a path or a snake_case name) replaced by
/// `[redacted]`.
String scrubLogText(String text) => _mixedRuns.fold(
  _secretPatterns.fold(
    text,
    (String scrubbed, RegExp pattern) =>
        scrubbed.replaceAll(pattern, '[redacted]'),
  ),
  (String scrubbed, RegExp pattern) => scrubbed.replaceAllMapped(
    pattern,
    (m) => _isMixed(m[0]!) ? '[redacted]' : m[0]!,
  ),
);

// Whether [run] holds an uppercase letter, a lowercase letter and a digit, as random
// base64 does and a file path, a URL path or a snake_case name does not.
bool _isMixed(String run) =>
    run.contains(RegExp('[A-Z]')) &&
    run.contains(RegExp('[a-z]')) &&
    run.contains(RegExp('[0-9]'));

final List<RegExp> _secretPatterns = [
  RegExp(r'Bearer\s+\S+', caseSensitive: false),
  RegExp(r'eyJ[A-Za-z0-9_=-]*\.[A-Za-z0-9_.=-]*'),
  RegExp(r'access-[a-z]+-[A-Za-z0-9-]{8,}'),
  RegExp(r'(public|link)-[a-z]+-[0-9a-f-]{36}'),
  RegExp(r'[\p{L}\p{N}._%+-]+@[\p{L}\p{N}.-]+\.\p{L}{2,}', unicode: true),
  RegExp(r"x'[0-9A-Fa-f]{8,}'?"),
  RegExp(r'[0-9A-Fa-f]{32,}'),
];

// Runs of 40 or more base64url or base64 characters, redacted only when mixed
// ([_isMixed]): the server's refresh tokens, base64 keys.
final List<RegExp> _mixedRuns = [
  RegExp(r'[A-Za-z0-9_-]{40,}'),
  RegExp(r'[A-Za-z0-9+/]{40,}={0,2}'),
];

/// An error reduced to its type: what the prod sink keeps in place of the error itself.
final class _ErrorType {
  const _ErrorType(this.type);

  final Type type;

  @override
  String toString() => '$type';
}
