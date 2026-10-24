/// Validates JSON values against the document's OAS 3.0 schemas by translating them to
/// JSON Schema draft 7 for `package:json_schema` (`docs/reference/api.md`, **Contract
/// tests**).
///
/// The translation, applied to the target schema and to every component schema:
/// - `$ref: #/components/schemas/X` becomes `#/definitions/X`; any other reference throws.
/// - `nullable: true` becomes `type: [<type>, "null"]` (with `null` added to an `enum`),
///   or `anyOf: [<schema>, {type: "null"}]` for a schema without a `type` (the
///   `allOf: [$ref]` form a nullable reference takes in OAS 3.0).
/// - OAS 3.0's boolean `exclusiveMinimum`/`exclusiveMaximum` become draft 7's numbers.
/// - `discriminator`, `example`, `xml`, `externalDocs`, `deprecated` and `x-*` are dropped.
/// - By [ValidationMode]: a request drops `readOnly` properties (from `properties` and
///   `required`, so a closed body rejects them); a response drops `writeOnly` ones.
/// - [JsonValidator.strict] closes every object schema that lists `properties` and says
///   nothing about `additionalProperties`, so an undeclared field fails; free-form objects
///   (`additionalProperties: true`) stay open.
/// - `format` stays: `email` and `uri` are json_schema's own checks; `date` and
///   `date-time` are replaced by stricter ones (below); others such as `int64` are
///   ignored.
///
/// Two checks go beyond draft 7, so that a value passes only when `shared_models` and the
/// generated client would both read it:
/// - `type: integer` takes only a Dart `int`. Draft 7 accepts any whole number, so `1.0`,
///   `1e3`, and an integer outside the 64-bit range (which `jsonDecode` returns as a
///   double) would otherwise pass. A walk over the instance and the translated schema
///   reports every double where only an integer is allowed.
/// - `format: date` is `yyyy-MM-dd` and a real calendar date, as `LocalDate.parse` reads
///   it; `format: date-time` is the RFC 3339 extended form with a real date, hours 0 to
///   23, minutes and seconds 0 to 59 and a `Z` or `±hh:mm` offset. The document's own
///   instant pattern (millisecond UTC) still applies on top.
library;

import 'dart:convert';

import 'package:contract_test/src/openapi_document.dart';
import 'package:json_schema/json_schema.dart';
import 'package:shared_models/shared_models.dart' show LocalDate;

/// Which direction a body travels, which decides how `readOnly` and `writeOnly` apply.
enum ValidationMode { request, response }

const _dropped = {
  'nullable',
  'discriminator',
  'example',
  'xml',
  'externalDocs',
  'deprecated',
  'readOnly',
  'writeOnly',
};

const _componentPrefix = '#/components/schemas/';

final _missing = RegExp(r'^required prop missing: (\S+) from ');

final _dateShape = RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$');

final _dateTimeShape = RegExp(
  r'^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})(\.[0-9]+)?'
  r'(Z|[+-]([0-9]{2}):([0-9]{2}))$',
);

/// Whether [text] is a `yyyy-MM-dd` real calendar date.
bool _isCalendarDate(String text) {
  if (!_dateShape.hasMatch(text)) return false;
  try {
    LocalDate.parse(text);
    return true;
  } on FormatException {
    return false;
  } on ArgumentError {
    return false;
  }
}

/// Whether [text] is an RFC 3339 instant with a real date and time of day.
bool _isInstant(String text) {
  final match = _dateTimeShape.firstMatch(text);
  if (match == null) return false;
  int part(int group) => int.parse(match[group]!);
  if (!_isCalendarDate(text.substring(0, 10))) return false;
  if (part(4) > 23 || part(5) > 59 || part(6) > 59) return false;
  if (match[9] != null && (part(9) > 23 || part(10) > 59)) return false;
  return true;
}

ValidationContext _checkDate(ValidationContext context, String value) {
  if (!_isCalendarDate(value)) {
    context.addError('"$value" is not a calendar date');
  }
  return context;
}

ValidationContext _checkInstant(ValidationContext context, String value) {
  if (!_isInstant(value)) context.addError('"$value" is not an instant');
  return context;
}

/// Validates values against [document]'s schemas.
final class JsonValidator {
  /// A validator; [strict] closes object schemas (see the library comment).
  JsonValidator(this.document, {this.strict = true});

  /// The document whose schemas are used.
  final OpenApiDocument document;

  /// Whether undeclared properties fail.
  final bool strict;

  final Map<String, (JsonSchema, Map<String, Object?>)> _compiled = {};

  /// The errors of [instance] (decoded JSON) against the OAS [schema], one readable line
  /// each (`/path/in/instance: message`); empty when it conforms.
  List<String> validate(
    Map<String, Object?> schema,
    Object? instance, {
    required ValidationMode mode,
  }) {
    final key = '${mode.name} ${jsonEncode(schema)}';
    final (compiled, translated) = _compiled[key] ??= () {
      final translated = toJsonSchema(schema, mode: mode);
      return (
        JsonSchema.create(
          translated,
          customFormats: const {'date': _checkDate, 'date-time': _checkInstant},
        ),
        translated,
      );
    }();
    final errors = <String>{};
    for (final error in compiled.validate(instance).errors) {
      final path = error.instancePath.isEmpty ? '/' : error.instancePath;
      final missing = _missing.firstMatch(error.message);
      if (missing == null) {
        errors.add('$path: ${error.message}');
      } else if (!path.endsWith('/${missing[1]}')) {
        // json_schema reports a missing property at the object and again at the
        // property's own path; keep the first, without the dump of the instance.
        errors.add('$path: missing required property ${missing[1]}');
      }
    }
    _integers(
      translated,
      instance,
      '',
      translated['definitions']! as Map<String, Object?>,
      errors,
    );
    return errors.toList();
  }

  /// Adds an error for every double in [instance] where [schema] allows only an integer.
  /// Combinators: `allOf` applies every part; an `anyOf` or `oneOf` reports only when
  /// every branch but a bare `{type: null}` would (for the translation's nullable
  /// `anyOf`, that is its one other branch).
  void _integers(
    Object? schema,
    Object? instance,
    String path,
    Map<String, Object?> definitions,
    Set<String> errors,
  ) {
    if (schema is! Map<String, Object?> || instance == null) return;
    final ref = schema[r'$ref'];
    if (ref is String) {
      final name = ref.substring('#/definitions/'.length);
      _integers(definitions[name], instance, path, definitions, errors);
    }
    final type = schema['type'];
    final types = type is List<Object?> ? type : [type];
    if (instance is double &&
        types.contains('integer') &&
        !types.contains('number')) {
      errors.add(
        '${path.isEmpty ? '/' : path}: wanted an integer, got the double $instance',
      );
    }
    for (final part in _list(schema['allOf'])) {
      _integers(part, instance, path, definitions, errors);
    }
    for (final key in const ['anyOf', 'oneOf']) {
      final branches = [
        for (final branch in _list(schema[key]))
          if (!(branch is Map<String, Object?> &&
              branch.length == 1 &&
              branch['type'] == 'null'))
            branch,
      ];
      if (branches.isEmpty) continue;
      final found = <Set<String>>[];
      for (final branch in branches) {
        final set = <String>{};
        _integers(branch, instance, path, definitions, set);
        found.add(set);
      }
      if (found.every((set) => set.isNotEmpty)) errors.addAll(found.first);
    }
    if (instance is Map<String, Object?>) {
      final properties = _properties(schema['properties']);
      final additional = schema['additionalProperties'];
      for (final MapEntry(:key, :value) in instance.entries) {
        final property = properties[key] ?? additional;
        _integers(property, value, '$path/$key', definitions, errors);
      }
    }
    if (instance is List<Object?>) {
      for (var i = 0; i < instance.length; i++) {
        _integers(
          schema['items'],
          instance[i],
          '$path/$i',
          definitions,
          errors,
        );
      }
    }
  }

  /// The errors of [instance] against the component schema [name].
  List<String> validateSchema(
    String name,
    Object? instance, {
    required ValidationMode mode,
  }) {
    document.schema(name);
    return validate({r'$ref': '$_componentPrefix$name'}, instance, mode: mode);
  }

  /// The draft 7 schema [schema] translates to, with every component schema under
  /// `definitions`. A bare reference to a component is replaced by the component itself,
  /// because draft 7 ignores the siblings of a `$ref` and errors under a wrapping `allOf`
  /// would be reported only as "allOf violated".
  Map<String, Object?> toJsonSchema(
    Map<String, Object?> schema, {
    required ValidationMode mode,
  }) {
    var target = schema;
    while (target.length == 1 && target[r'$ref'] is String) {
      final ref = target[r'$ref']! as String;
      _reference(ref);
      target = document.schema(ref.substring(_componentPrefix.length));
    }
    final translated = _translate(target, mode)! as Map<String, Object?>;
    return {
      ...translated,
      r'$schema': 'http://json-schema.org/draft-07/schema#',
      'definitions': {
        for (final MapEntry(:key, :value) in document.schemas.entries)
          key: _translate(value, mode),
      },
    };
  }

  Object? _translate(Object? node, ValidationMode mode) {
    if (node is! Map<String, Object?>) return node;
    final skipped = <String>{
      for (final MapEntry(:key, :value) in _properties(
        node['properties'],
      ).entries)
        if (value is Map<String, Object?> &&
            value[mode == ValidationMode.request ? 'readOnly' : 'writeOnly'] ==
                true)
          key,
    };
    final out = <String, Object?>{};
    for (final MapEntry(:key, :value) in node.entries) {
      if (_dropped.contains(key) || key.startsWith('x-')) continue;
      switch (key) {
        case r'$ref':
          out[key] = _reference(value! as String);
        case 'properties':
          out[key] = {
            for (final MapEntry(key: name, value: property) in _properties(
              value,
            ).entries)
              if (!skipped.contains(name)) name: _translate(property, mode),
          };
        case 'required':
          out[key] = [
            for (final name in value! as List<Object?>)
              if (!skipped.contains(name)) name,
          ];
        case 'items' || 'not' || 'additionalProperties':
          out[key] = _translate(value, mode);
        case 'allOf' || 'anyOf' || 'oneOf':
          out[key] = [
            for (final part in value! as List<Object?>) _translate(part, mode),
          ];
        case 'exclusiveMinimum' || 'exclusiveMaximum':
          break; // below, once `minimum` and `maximum` are copied
        default:
          out[key] = value;
      }
    }
    if (node['exclusiveMinimum'] == true) {
      out['exclusiveMinimum'] = out.remove('minimum');
    }
    if (node['exclusiveMaximum'] == true) {
      out['exclusiveMaximum'] = out.remove('maximum');
    }
    if (strict &&
        node.containsKey('properties') &&
        !node.containsKey('additionalProperties')) {
      out['additionalProperties'] = false;
    }
    if (node['nullable'] != true) return out;
    final type = out['type'];
    if (type is String) {
      out['type'] = [type, 'null'];
      final values = out['enum'];
      if (values is List<Object?>) out['enum'] = [...values, null];
      return out;
    }
    return {
      'anyOf': [
        out,
        {'type': 'null'},
      ],
    };
  }

  String _reference(String ref) {
    if (!ref.startsWith(_componentPrefix)) {
      throw ArgumentError.value(
        ref,
        'ref',
        'schemas may reference only #/components/schemas/',
      );
    }
    return '#/definitions/${ref.substring(_componentPrefix.length)}';
  }
}

Map<String, Object?> _properties(Object? node) =>
    node is Map<String, Object?> ? node : const {};

List<Object?> _list(Object? node) => node is List<Object?> ? node : const [];
