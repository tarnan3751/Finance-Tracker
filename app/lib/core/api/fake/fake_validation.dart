/// The fake server's request checks, mirroring the dev server's hand-written validation
/// (`docs/reference/server.md`, **Request pipeline**): objects are closed, an explicit
/// `null` is an error (no request field is nullable), lengths count characters, and every
/// problem is collected before the 400 answer.
library;

/// One field's problem: `field` is the key, a path (`entries[3].hlc`), a query
/// parameter's name, or empty for the body as a whole.
typedef FakeFieldError = ({String field, String message});

/// A failed validation, answered as 400 `validation_failed`.
final class FakeValidationException implements Exception {
  FakeValidationException(this.errors);

  FakeValidationException.single(String field, String message)
    : errors = [(field: field, message: message)];

  final List<FakeFieldError> errors;
}

/// The email shape the dev server accepts.
final RegExp emailShape = RegExp(r'^[^@\s]+@[^@\s.]+(\.[^@\s.]+)+$');

/// The contract's `Hlc` pattern.
final RegExp hlcShape = RegExp(r'^[0-9]{15}-[0-9]{5}-[A-Za-z0-9_.:-]+$');

/// The contract's Android package-name pattern.
final RegExp packageNameShape = RegExp(
  r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$',
);

/// The request body as a JSON object, or a 400.
Map<String, Object?> bodyObject(Object? body) {
  if (body is Map<String, Object?>) return body;
  throw FakeValidationException.single('', 'the body must be a JSON object');
}

/// Reads a closed JSON object field by field, collecting every problem.
final class FakeReader {
  FakeReader(
    this.json,
    Set<String> known, {
    this.prefix = '',
    List<FakeFieldError>? errors,
  }) : errors = errors ?? [] {
    for (final String key in json.keys) {
      if (!known.contains(key)) {
        this.errors.add((field: _path(key), message: 'is not a known field'));
      }
    }
  }

  final Map<String, Object?> json;
  final String prefix;
  final List<FakeFieldError> errors;

  String _path(String key) => prefix.isEmpty ? key : '$prefix.$key';

  void _error(String key, String message) =>
      errors.add((field: _path(key), message: message));

  /// A string, or null with an error recorded when it is absent ([required]) or invalid.
  String? string(
    String key, {
    bool required = true,
    int? minLength,
    int? maxLength,
    RegExp? pattern,
    bool email = false,
  }) {
    if (!json.containsKey(key)) {
      if (required) _error(key, 'is required');
      return null;
    }
    final Object? value = json[key];
    if (value is! String) {
      _error(key, 'must be a string');
      return null;
    }
    final int length = value.runes.length;
    if (minLength != null && length < minLength) {
      _error(key, 'must be at least $minLength characters');
      return null;
    }
    if (maxLength != null && length > maxLength) {
      _error(key, 'must be at most $maxLength characters');
      return null;
    }
    if (pattern != null && !pattern.hasMatch(value)) {
      _error(key, 'does not match ${pattern.pattern}');
      return null;
    }
    if (email && !emailShape.hasMatch(value)) {
      _error(key, 'must be an email address');
      return null;
    }
    return value;
  }

  /// One of [values], or null with an error recorded.
  String? oneOf(String key, Set<String> values) {
    final String? value = string(key);
    if (value != null && !values.contains(value)) {
      _error(key, 'must be one of ${values.join(', ')}');
      return null;
    }
    return value;
  }

  /// A JSON object, or null with an error recorded.
  Map<String, Object?>? object(String key) {
    final Object? value = json[key];
    if (!json.containsKey(key)) {
      _error(key, 'is required');
    } else if (value is! Map<String, Object?>) {
      _error(key, 'must be an object');
    } else {
      return value;
    }
    return null;
  }

  /// A JSON array, or null with an error recorded.
  List<Object?>? list(String key) {
    final Object? value = json[key];
    if (!json.containsKey(key)) {
      _error(key, 'is required');
    } else if (value is! List<Object?>) {
      _error(key, 'must be an array');
    } else {
      return value;
    }
    return null;
  }

  /// Throws the collected problems, if any.
  void done() {
    if (errors.isNotEmpty) throw FakeValidationException(errors);
  }
}

/// The integer query parameter [name] in [min]..[max], [fallback] when absent.
int queryInt(
  Map<String, String> query,
  String name, {
  required int fallback,
  required int min,
  int? max,
}) {
  final String? text = query[name];
  if (text == null) return fallback;
  final int? value = int.tryParse(text);
  if (value == null || value < min || (max != null && value > max)) {
    throw FakeValidationException.single(
      name,
      max == null
          ? 'must be an integer of at least $min'
          : 'must be an integer from $min to $max',
    );
  }
  return value;
}
