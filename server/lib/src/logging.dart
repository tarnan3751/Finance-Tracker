/// Structured logging on `package:logging` (`docs/reference/server.md`, **Logging**).
///
/// Code logs a [LogEvent]: an event name and a map of fields. The formatter writes one JSON
/// object per line (`LOG_FORMAT=json`) or a `key=value` line for a terminal. Fields are ids,
/// counts, codes and durations: never a request body, a token, a password, an email or an
/// amount. A logged error is never written through its `toString()`, which can carry SQL
/// and its parameters: [errorFields] writes its type and, for a [SqliteException], only
/// its result codes and SQLite's message.
library;

import 'dart:async';
import 'dart:convert';

import 'package:finance_tracker_server/src/config.dart';
import 'package:logging/logging.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

/// One structured log entry: [event] names what happened, [fields] describe it.
final class LogEvent {
  /// An entry.
  const LogEvent(this.event, [this.fields = const {}]);

  /// What happened, in snake_case (`request`, `refresh_token_reuse`).
  final String event;

  /// Ids, counts and codes; never secrets, emails or amounts.
  final Map<String, Object?> fields;

  @override
  String toString() => event;
}

/// Sends every record of the root logger at [Level.INFO] and above to [sink] in [format].
/// The caller keeps the subscription for the server's lifetime.
StreamSubscription<LogRecord> configureLogging(
  LogFormat format,
  StringSink sink,
) {
  Logger.root.level = Level.INFO;
  return Logger.root.onRecord.listen(
    (r) => sink.writeln(formatRecord(r, format)),
  );
}

/// One record as a line in [format].
String formatRecord(LogRecord record, LogFormat format) {
  final object = record.object;
  final event = object is LogEvent ? object.event : record.message;
  final fields = <String, Object?>{
    if (object is LogEvent) ...object.fields,
    if (record.error case final error?) ...errorFields(error),
    if (record.stackTrace != null) 'stack': record.stackTrace.toString(),
  };
  final time = record.time.toUtc().toIso8601String();
  switch (format) {
    case LogFormat.json:
      return jsonEncode({
        'time': time,
        'level': record.level.name,
        'logger': record.loggerName,
        'event': event,
        ...fields,
      });
    case LogFormat.text:
      final rest = [
        for (final MapEntry(:key, :value) in fields.entries)
          if (key != 'stack') '$key=$value',
      ].join(' ');
      final stack = fields['stack'];
      return '$time ${record.level.name} ${record.loggerName} $event'
          '${rest.isEmpty ? '' : ' $rest'}${stack == null ? '' : '\n$stack'}';
  }
}

/// What a log line may say about [error]: its type, and for a [SqliteException] its
/// result codes and SQLite's message, never the statement, its parameters or the
/// operation.
Map<String, Object?> errorFields(Object error) => {
  'error_type': error.runtimeType.toString(),
  if (error is SqliteException) ...{
    'sqlite_result_code': error.resultCode,
    'sqlite_extended_result_code': error.extendedResultCode,
    'sqlite_message': error.message,
  },
};
