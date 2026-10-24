/// `dart run contract_test:check_openapi <openapi.yaml>`: the structural check of the
/// contract (`tools/check_contract.sh`). Prints each violation and exits 1, or prints a
/// one-line summary and exits 0. Exit 2 is a usage error.
library;

import 'dart:io';

import 'package:contract_test/contract_test.dart';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('usage: check_openapi <openapi.yaml>');
    exitCode = 2;
    return;
  }
  final file = File(arguments.single);
  final OpenApiDocument document;
  try {
    document = OpenApiDocument.load(file);
  } on FileSystemException catch (error) {
    stderr.writeln('${file.path}: ${error.message}');
    exitCode = 1;
    return;
  } on YamlException catch (error) {
    stderr.writeln('${file.path} does not parse: ${error.message}');
    exitCode = 1;
    return;
  } on FormatException catch (error) {
    stderr.writeln('${file.path}: ${error.message}');
    exitCode = 1;
    return;
  }
  final violations = checkOpenApi(document);
  if (violations.isEmpty) {
    stdout.writeln('openapi ok: ${summarize(document)}');
    return;
  }
  for (final violation in violations) {
    stdout.writeln(violation);
  }
  stdout.writeln('openapi: ${violations.length} violation(s) in ${file.path}');
  exitCode = 1;
}
