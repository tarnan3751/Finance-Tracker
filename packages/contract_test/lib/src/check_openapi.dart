/// The structural checks `bin/check_openapi.dart` runs over the contract for the gate
/// (`tools/check_contract.sh`; `docs/reference/api.md`, **The structural check**).
library;

import 'package:contract_test/src/openapi_document.dart';

/// The operations that take no bearer token (`api/openapi.yaml`, `security: []`).
const publicOperations = {
  'register',
  'login',
  'refreshTokens',
  'getHealth',
  'receivePlaidWebhook',
};

/// The operations whose request body is free-form, exempt from the closed-body check.
const freeFormBodies = {'receivePlaidWebhook'};

/// A property whose name matches this must reference the `Money` schema.
final moneyName = RegExp(r'(amount|_balance|limit|target)$');

const _problemSchemas = {
  '#/components/schemas/Problem',
  '#/components/schemas/ValidationProblem',
};

/// Every violation of the contract's conventions in [document], one line each; empty
/// when it passes.
List<String> checkOpenApi(OpenApiDocument document) {
  final violations = <String>[];
  final root = document.root;

  final version = root['openapi'];
  if (version is! String || !version.startsWith('3.0.')) {
    violations.add('openapi is ${version ?? 'missing'}, not 3.0.x');
  }

  final paths = root['paths'];
  if (paths is Map<String, Object?>) {
    for (final path in paths.keys) {
      if (!path.startsWith('/')) {
        violations.add('path $path does not start with /');
      }
    }
  } else {
    violations.add('the document has no paths');
  }

  _walk(root, '#', (node, pointer) {
    final type = node['type'];
    if (type == 'number' ||
        (type is List<Object?> && type.contains('number'))) {
      violations.add(
        '$pointer: type number is not allowed (no double on the wire; '
        'amounts are Money, exact decimals are Decimal)',
      );
    }
    final ref = node[r'$ref'];
    if (ref is String) {
      try {
        document.resolve(ref);
      } on ArgumentError {
        violations.add('$pointer: \$ref $ref does not resolve');
      }
    }
    final properties = node['properties'];
    if (properties is Map<String, Object?>) {
      for (final MapEntry(key: name, value: property) in properties.entries) {
        if (moneyName.hasMatch(name) && !_isMoney(property)) {
          violations.add(
            '$pointer/properties/$name: an amount must reference Money',
          );
        }
      }
      final required = node['required'];
      if (required is List<Object?>) {
        for (final name in required) {
          if (!properties.containsKey(name)) {
            violations.add('$pointer: required $name is not a property');
          }
        }
      }
    }
  });

  final bearer = _resolveOrNull(
    document,
    '#/components/securitySchemes/bearerAuth',
  );
  if (bearer is! Map<String, Object?> ||
      bearer['type'] != 'http' ||
      bearer['scheme'] != 'bearer') {
    violations.add('components.securitySchemes.bearerAuth is not HTTP bearer');
  }

  final ids = <String>{};
  for (final (:path, :method, :operation) in document.operations) {
    final where = '${method.toUpperCase()} $path';
    final id = operation['operationId'];
    if (id is! String || id.isEmpty) {
      violations.add('$where has no operationId');
    } else if (!ids.add(id)) {
      violations.add('$where: operationId $id is not unique');
    }
    final summary = operation['summary'];
    if (summary is! String || summary.trim().isEmpty) {
      violations.add('$where has no summary');
    }
    _checkResponses(document, where, operation, violations);
    _checkSecurity(root, where, id, operation, violations);
    _checkBody(document, where, id, operation, violations);
  }
  return violations;
}

/// The one-line summary the checker prints when the document passes.
String summarize(OpenApiDocument document) =>
    '${document.operations.length} operations, '
    '${document.schemas.length} schemas';

void _checkResponses(
  OpenApiDocument document,
  String where,
  Map<String, Object?> operation,
  List<String> violations,
) {
  final responses = operation['responses'];
  if (responses is! Map<String, Object?>) {
    violations.add('$where has no responses');
    return;
  }
  var success = 0;
  for (final MapEntry(key: status, value: raw) in responses.entries) {
    final Map<String, Object?> response;
    try {
      response = document.deref(raw);
    } on ArgumentError {
      continue; // reported by the $ref walk
    }
    final content = response['content'];
    if (status.startsWith('2')) {
      success++;
      if (status == '204') {
        if (content != null) violations.add('$where 204 declares a body');
      } else if (_schemaOf(content, 'application/json') == null &&
          !_isImageBody(content)) {
        violations.add(
          '$where $status has no application/json schema or image body',
        );
      }
    } else if (status.startsWith('4') || status.startsWith('5')) {
      final schema = _schemaOf(content, 'application/problem+json');
      if (schema == null || !_problemSchemas.contains(schema[r'$ref'])) {
        violations.add(
          '$where $status is not application/problem+json with Problem',
        );
      }
    }
  }
  if (success == 0) violations.add('$where has no 2xx response');
}

void _checkSecurity(
  Map<String, Object?> root,
  String where,
  Object? id,
  Map<String, Object?> operation,
  List<String> violations,
) {
  final security = operation['security'] ?? root['security'];
  final schemes = <String>{
    if (security is List<Object?>)
      for (final requirement in security)
        if (requirement is Map<String, Object?>) ...requirement.keys,
  };
  if (publicOperations.contains(id)) {
    if (schemes.isNotEmpty) {
      violations.add('$where is public and must declare security: []');
    }
  } else if (!schemes.contains('bearerAuth')) {
    violations.add('$where must require bearerAuth');
  }
  if (id == 'receivePlaidWebhook') {
    final parameters = operation['parameters'];
    final hasHeader =
        parameters is List<Object?> &&
        parameters.any(
          (p) =>
              p is Map<String, Object?> &&
              p['in'] == 'header' &&
              p['name'] == 'Plaid-Verification' &&
              p['required'] == true,
        );
    if (!hasHeader) {
      violations.add('$where must require the Plaid-Verification header');
    }
  }
}

void _checkBody(
  OpenApiDocument document,
  String where,
  Object? id,
  Map<String, Object?> operation,
  List<String> violations,
) {
  final body = operation['requestBody'];
  if (body == null || freeFormBodies.contains(id)) return;
  try {
    final content = document.deref(body)['content'];
    if (_isImageBody(content)) return; // bytes: nothing to close
    final schema = _schemaOf(content, 'application/json');
    if (schema == null) {
      violations.add('$where request body has no application/json schema');
    } else if (document.deref(schema)['additionalProperties'] != false) {
      violations.add('$where request body must be additionalProperties: false');
    }
  } on ArgumentError {
    return; // reported by the $ref walk
  }
}

/// The media types an image body may have.
const imageMediaTypes = {'image/png', 'image/jpeg'};

/// A body that is only image bytes: one or more of [imageMediaTypes], each
/// `{type: string, format: binary}`.
bool _isImageBody(Object? content) {
  if (content is! Map<String, Object?> || content.isEmpty) return false;
  return content.keys.every((type) {
    final schema = _schemaOf(content, type);
    return imageMediaTypes.contains(type) &&
        schema != null &&
        schema['type'] == 'string' &&
        schema['format'] == 'binary';
  });
}

Map<String, Object?>? _schemaOf(Object? content, String type) {
  if (content is! Map<String, Object?>) return null;
  final media = content[type];
  if (media is! Map<String, Object?>) return null;
  final schema = media['schema'];
  return schema is Map<String, Object?> ? schema : null;
}

bool _isMoney(Object? property) {
  const money = '#/components/schemas/Money';
  if (property is! Map<String, Object?>) return false;
  if (property[r'$ref'] == money) return true;
  final allOf = property['allOf'];
  return allOf is List<Object?> &&
      allOf.length == 1 &&
      allOf.single is Map<String, Object?> &&
      (allOf.single! as Map<String, Object?>)[r'$ref'] == money;
}

Object? _resolveOrNull(OpenApiDocument document, String ref) {
  try {
    return document.resolve(ref);
  } on ArgumentError {
    return null;
  }
}

void _walk(
  Object? node,
  String pointer,
  void Function(Map<String, Object?> node, String pointer) visit,
) {
  if (node is Map<String, Object?>) {
    visit(node, pointer);
    for (final MapEntry(:key, :value) in node.entries) {
      _walk(
        value,
        '$pointer/${key.replaceAll('~', '~0').replaceAll('/', '~1')}',
        visit,
      );
    }
  } else if (node is List<Object?>) {
    for (var i = 0; i < node.length; i++) {
      _walk(node[i], '$pointer/$i', visit);
    }
  }
}
