// The repository's contract, loaded once for the tests. `dart test` runs in the package
// directory, so the document is two levels up.
import 'dart:io';

import 'package:contract_test/contract_test.dart';
import 'package:path/path.dart' as p;

/// `api/openapi.yaml`.
final OpenApiDocument contract = OpenApiDocument.load(
  File(p.join('..', '..', 'api', 'openapi.yaml')),
);
