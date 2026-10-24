/// Test matchers that check a decoded JSON body against the contract
/// (`docs/reference/api.md`, **Contract tests**). They validate strictly: a field the
/// contract does not declare fails.
library;

import 'package:contract_test/src/json_validator.dart';
import 'package:contract_test/src/openapi_document.dart';
import 'package:test/test.dart';

/// Matches the decoded body of the [status] response of [method] [path] (a path template
/// such as `/plaid/items/{item_id}`). A response declared without a body (a 204) matches
/// only null or an empty string; an `image/png` response matches only non-empty bytes
/// (a `List<int>`).
Matcher conformsToResponse(
  OpenApiDocument document,
  String path,
  String method,
  int status,
) => _Conforms(
  document,
  document.responseSchema(path, method, status),
  ValidationMode.response,
  '${method.toUpperCase()} $path $status response',
  binary: document.responseMediaType(path, method, status) == 'image/png',
);

/// Matches the decoded request body of [method] [path].
Matcher conformsToRequest(
  OpenApiDocument document,
  String path,
  String method,
) => _Conforms(
  document,
  document.requestSchema(path, method),
  ValidationMode.request,
  '${method.toUpperCase()} $path request body',
);

/// Matches a decoded value against the component schema [name], as a response unless
/// [mode] says otherwise.
Matcher conformsToSchema(
  OpenApiDocument document,
  String name, {
  ValidationMode mode = ValidationMode.response,
}) {
  document.schema(name);
  return _Conforms(
    document,
    {r'$ref': '#/components/schemas/$name'},
    mode,
    'the $name schema (${mode.name})',
  );
}

final class _Conforms extends Matcher {
  const _Conforms(
    this.document,
    this.schema,
    this.mode,
    this.label, {
    this.binary = false,
  });

  final OpenApiDocument document;
  final Map<String, Object?>? schema;
  final ValidationMode mode;
  final String label;
  final bool binary;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    final schema = this.schema;
    final List<String> errors;
    if (binary) {
      errors = item is List<int> && item.isNotEmpty
          ? const []
          : ['/: expected image bytes'];
    } else if (schema == null) {
      errors = item == null || item == '' ? const [] : ['/: expected no body'];
    } else {
      errors = document.validator.validate(schema, item, mode: mode);
    }
    matchState['errors'] = errors;
    return errors.isEmpty;
  }

  @override
  Description describe(Description description) =>
      description.add('conforms to $label');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    final errors = matchState['errors']! as List<String>;
    return mismatchDescription.add(errors.join('\n'));
  }
}
