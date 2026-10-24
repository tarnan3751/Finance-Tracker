/// The OpenAPI document as plain Dart maps, with lookups for schemas, request bodies and
/// responses (`docs/reference/api.md`, **Contract tests**).
library;

import 'dart:io';

import 'package:contract_test/src/json_validator.dart';
import 'package:yaml/yaml.dart';

/// The HTTP methods an OpenAPI path item can hold an operation under.
const List<String> httpMethods = [
  'get',
  'put',
  'post',
  'delete',
  'options',
  'head',
  'patch',
  'trace',
];

/// One operation of the document: its path template, lower-case method and object.
typedef Operation = ({
  String path,
  String method,
  Map<String, Object?> operation,
});

/// An OpenAPI 3.0 document, parsed from YAML into plain maps and lists.
final class OpenApiDocument {
  /// Wraps an already parsed document.
  OpenApiDocument(this.root);

  /// Parses YAML (or JSON) text. A [YamlException] propagates.
  factory OpenApiDocument.parse(String text) {
    final parsed = plainJson(loadYaml(text));
    if (parsed is! Map<String, Object?>) {
      throw const FormatException('An OpenAPI document is a mapping');
    }
    return OpenApiDocument(parsed);
  }

  /// Reads and parses [file].
  factory OpenApiDocument.load(File file) =>
      OpenApiDocument.parse(file.readAsStringSync());

  /// The whole document.
  final Map<String, Object?> root;

  /// A strict validator over this document, built on first use.
  late final JsonValidator validator = JsonValidator(this);

  /// `components.schemas`, empty when absent.
  Map<String, Object?> get schemas => _map(_map(root['components'])['schemas']);

  /// Every operation, in document order.
  Iterable<Operation> get operations sync* {
    for (final MapEntry(key: path, value: item) in _map(
      root['paths'],
    ).entries) {
      for (final method in httpMethods) {
        final operation = _map(item)[method];
        if (operation is Map<String, Object?>) {
          yield (path: path, method: method, operation: operation);
        }
      }
    }
  }

  /// The component schema [name]; an [ArgumentError] when there is none.
  Map<String, Object?> schema(String name) {
    final schema = schemas[name];
    if (schema is! Map<String, Object?>) {
      throw ArgumentError.value(name, 'name', 'no such schema');
    }
    return schema;
  }

  /// The operation at [path] (a template such as `/plaid/items/{item_id}`) and [method];
  /// an [ArgumentError] when there is none.
  Map<String, Object?> operation(String path, String method) {
    final item = _map(root['paths'])[path];
    final operation = _map(item)[method.toLowerCase()];
    if (operation is! Map<String, Object?>) {
      throw ArgumentError('no operation ${method.toUpperCase()} $path');
    }
    return operation;
  }

  /// The JSON schema of the request body of [path] and [method]; an [ArgumentError] when
  /// the operation takes no JSON body.
  Map<String, Object?> requestSchema(String path, String method) {
    final body = operation(path, method)['requestBody'];
    if (body == null) {
      throw ArgumentError('${method.toUpperCase()} $path takes no body');
    }
    final schema = _contentSchema(deref(body));
    if (schema == null) {
      throw ArgumentError('${method.toUpperCase()} $path takes no JSON body');
    }
    return schema;
  }

  /// The schema of the [status] response of [path] and [method], or null when that
  /// response has no body (a 204); an [ArgumentError] when the response is not declared.
  Map<String, Object?>? responseSchema(String path, String method, int status) {
    final responses = _map(operation(path, method)['responses']);
    final response = responses['$status'];
    if (response == null) {
      throw ArgumentError(
        '${method.toUpperCase()} $path declares no $status response',
      );
    }
    return _contentSchema(deref(response));
  }

  /// Follows a local `$ref` (`#/...`) to its target, repeatedly; returns any other node
  /// unchanged. An [ArgumentError] when a reference does not resolve.
  Map<String, Object?> deref(Object? node) {
    var current = node;
    final seen = <String>{};
    while (current is Map<String, Object?> && current[r'$ref'] is String) {
      final ref = current[r'$ref']! as String;
      if (!seen.add(ref)) throw ArgumentError('circular \$ref $ref');
      current = resolve(ref);
    }
    if (current is! Map<String, Object?>) {
      throw ArgumentError('not an object: $current');
    }
    return current;
  }

  /// The node a local reference such as `#/components/schemas/Money` names; an
  /// [ArgumentError] when it is not local or does not resolve.
  Object? resolve(String ref) {
    if (!ref.startsWith('#/')) {
      throw ArgumentError.value(
        ref,
        'ref',
        'only local references are allowed',
      );
    }
    Object? node = root;
    for (final raw in ref.substring(2).split('/')) {
      final key = raw.replaceAll('~1', '/').replaceAll('~0', '~');
      if (node is Map<String, Object?> && node.containsKey(key)) {
        node = node[key];
      } else {
        throw ArgumentError.value(ref, 'ref', 'does not resolve');
      }
    }
    return node;
  }

  Map<String, Object?>? _contentSchema(Map<String, Object?> holder) {
    final content = _map(holder['content']);
    for (final type in const ['application/json', 'application/problem+json']) {
      final schema = _map(content[type])['schema'];
      if (schema is Map<String, Object?>) return schema;
    }
    return null;
  }
}

Map<String, Object?> _map(Object? node) =>
    node is Map<String, Object?> ? node : const {};

/// Converts parsed YAML (or JSON) into plain `Map<String, Object?>`, `List<Object?>` and
/// scalars, with every map key a string.
Object? plainJson(Object? node) => switch (node) {
  final Map<Object?, Object?> map => <String, Object?>{
    for (final MapEntry(:key, :value) in map.entries)
      key.toString(): plainJson(value),
  },
  final List<Object?> list => [for (final value in list) plainJson(value)],
  _ => node,
};
