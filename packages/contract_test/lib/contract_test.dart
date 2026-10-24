/// Contract tests for `api/openapi.yaml`: the document as plain maps, a validator that
/// translates its OAS 3.0 schemas to JSON Schema draft 7, matchers for request and
/// response bodies, and the structural checks the gate runs.
///
/// Pure Dart. How to use it: `docs/reference/api.md`, **Contract tests**.
library;

export 'src/check_openapi.dart' show checkOpenApi, summarize;
export 'src/json_validator.dart';
export 'src/matchers.dart';
export 'src/openapi_document.dart' show OpenApiDocument, Operation;
