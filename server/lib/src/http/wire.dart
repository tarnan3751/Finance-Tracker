/// Request reading and response writing shared by the routes: JSON bodies under a size
/// limit, closed-object field readers that collect [FieldError]s, query integers, and the
/// wire forms of instants.
library;

import 'dart:convert';

import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shelf/shelf.dart';

/// The body limit of every route but `pushChanges`.
const int defaultBodyLimit = 1024 * 1024;

/// The body limit of `pushChanges`.
const int pushBodyLimit = 4 * 1024 * 1024;

/// A 200 (or [status]) JSON response.
Response jsonResponse(Object? body, {int status = 200}) => Response(
  status,
  body: jsonEncode(body),
  headers: const {'content-type': 'application/json'},
);

/// A 204.
Response noContent() => Response(204);

/// An instant in milliseconds UTC, written as the contract's instant.
String instantJson(int millis) => const UtcInstantConverter().toJson(
  DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true),
);

/// [instantJson] of a nullable value.
String? optionalInstantJson(int? millis) =>
    millis == null ? null : instantJson(millis);

/// [request]'s body bytes exactly as received, at most [limit] of them; more is a
/// [ValidationException] on the body as a whole.
Future<List<int>> readBodyBytes(
  Request request, {
  int limit = defaultBodyLimit,
}) async {
  final declared = request.contentLength;
  if (declared != null && declared > limit) {
    throw ValidationException.single('', 'the body exceeds $limit bytes');
  }
  final bytes = <int>[];
  await for (final chunk in request.read()) {
    bytes.addAll(chunk);
    if (bytes.length > limit) {
      throw ValidationException.single('', 'the body exceeds $limit bytes');
    }
  }
  return bytes;
}

/// Reads [request]'s body as a JSON object of at most [limit] bytes; anything else is a
/// [ValidationException] on the body as a whole (`field` is the empty string).
Future<Map<String, Object?>> readJsonObject(
  Request request, {
  int limit = defaultBodyLimit,
}) async {
  if (request.mimeType != 'application/json') {
    throw ValidationException.single('', 'the body must be application/json');
  }
  final bytes = await readBodyBytes(request, limit: limit);
  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes));
  } on FormatException {
    throw ValidationException.single('', 'the body is not JSON');
  }
  if (decoded is! Map<String, Object?>) {
    throw ValidationException.single('', 'the body must be a JSON object');
  }
  return decoded;
}

final _email = RegExp(r'^[^@\s]+@[^@\s.]+(\.[^@\s.]+)+$');

/// Reads a closed JSON object field by field, collecting every problem in [errors]. A key
/// the reader was not told about ([known]) is an error. Field paths are `prefix.key`.
final class ObjectReader {
  /// A reader of [json] whose fields are reported under [prefix].
  ObjectReader(
    this.json,
    Set<String> known, {
    this.prefix = '',
    List<FieldError>? errors,
  }) : errors = errors ?? [] {
    for (final key in json.keys) {
      if (!known.contains(key)) {
        this.errors.add(FieldError(_path(key), 'is not a known field'));
      }
    }
  }

  /// The object.
  final Map<String, Object?> json;

  /// The path of the object itself (`entries[2]`), or empty.
  final String prefix;

  /// Every problem found, shared with child readers.
  final List<FieldError> errors;

  String _path(String key) => prefix.isEmpty ? key : '$prefix.$key';

  /// A string; null (with an error recorded) when [required] and absent, or when invalid.
  /// An explicit JSON `null` is an error: no request field is nullable in the contract.
  String? string(
    String key, {
    bool required = true,
    int? minLength,
    int? maxLength,
    RegExp? pattern,
    bool email = false,
  }) {
    if (!json.containsKey(key)) {
      if (required) errors.add(FieldError(_path(key), 'is required'));
      return null;
    }
    final value = json[key];
    if (value is! String) {
      errors.add(FieldError(_path(key), 'must be a string'));
      return null;
    }
    final length = value.runes.length;
    if (minLength != null && length < minLength) {
      errors.add(
        FieldError(_path(key), 'must be at least $minLength characters'),
      );
      return null;
    }
    if (maxLength != null && length > maxLength) {
      errors.add(
        FieldError(_path(key), 'must be at most $maxLength characters'),
      );
      return null;
    }
    if (pattern != null && !pattern.hasMatch(value)) {
      errors.add(FieldError(_path(key), 'does not match ${pattern.pattern}'));
      return null;
    }
    if (email && !_email.hasMatch(value)) {
      errors.add(FieldError(_path(key), 'must be an email address'));
      return null;
    }
    return value;
  }

  /// An integer from [min] to [max]; [fallback] when absent and not [required].
  int? integer(
    String key, {
    bool required = true,
    int? fallback,
    int? min,
    int? max,
  }) {
    if (!json.containsKey(key)) {
      if (required) errors.add(FieldError(_path(key), 'is required'));
      return fallback;
    }
    final value = json[key];
    if (value is! int ||
        (min != null && value < min) ||
        (max != null && value > max)) {
      errors.add(
        FieldError(
          _path(key),
          'must be an integer${min == null ? '' : ' from $min'}'
          '${max == null ? '' : ' to $max'}',
        ),
      );
      return null;
    }
    return value;
  }

  /// An ISO calendar date (`2026-10-24`).
  LocalDate? date(String key) {
    final text = string(key);
    if (text == null) return null;
    try {
      if (RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$').hasMatch(text)) {
        return LocalDate.parse(text);
      }
    } on FormatException {
      // reported below
    }
    errors.add(FieldError(_path(key), 'must be a calendar date'));
    return null;
  }

  /// A `Money` object: `minor_units` an integer, `currency` an ISO 4217 code.
  Money? money(String key) {
    final raw = object(key);
    if (raw == null) return null;
    final m = ObjectReader(
      raw,
      const {'minor_units', 'currency'},
      prefix: _path(key),
      errors: errors,
    );
    final units = m.integer('minor_units', min: -0x7FFFFFFFFFFFFFFF);
    final currency = m.string('currency', pattern: RegExp(r'^[A-Z]{3}$'));
    if (units == null || currency == null) return null;
    return Money(units, currency);
  }

  /// One of [values] by its wire name.
  T? oneOf<T>(String key, Map<String, T> values) {
    final name = string(key);
    if (name == null) return null;
    final value = values[name];
    if (value == null) {
      errors.add(
        FieldError(_path(key), 'must be one of ${values.keys.join(', ')}'),
      );
    }
    return value;
  }

  /// A JSON object (open: its own keys are not checked).
  Map<String, Object?>? object(String key) {
    final value = json[key];
    if (value is Map<String, Object?>) return value;
    errors.add(
      FieldError(
        _path(key),
        json.containsKey(key) ? 'must be an object' : 'is required',
      ),
    );
    return null;
  }

  /// A JSON array.
  List<Object?>? list(String key) {
    final value = json[key];
    if (value is List<Object?>) return value;
    errors.add(
      FieldError(
        _path(key),
        json.containsKey(key) ? 'must be an array' : 'is required',
      ),
    );
    return null;
  }

  /// Throws a [ValidationException] when any problem was recorded.
  void check() {
    if (errors.isNotEmpty) throw ValidationException(errors);
  }
}

/// The integer query parameter [name] of [request]: [fallback] when absent, an error in
/// [errors] (and null) when not an integer from [min] to [max].
int? queryInt(
  Request request,
  String name, {
  required int fallback,
  required int min,
  int? max,
  required List<FieldError> errors,
}) {
  final text = request.url.queryParameters[name];
  if (text == null) return fallback;
  final value = int.tryParse(text);
  if (value == null || value < min || (max != null && value > max)) {
    errors.add(
      FieldError(
        name,
        'must be an integer from $min${max == null ? '' : ' to $max'}',
      ),
    );
    return null;
  }
  return value;
}
