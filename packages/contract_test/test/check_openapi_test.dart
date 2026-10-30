// The structural checks: the real contract passes, the minimal fixture passes, and a
// copy of the fixture broken in one way fails with the message naming that rule.
import 'dart:convert';
import 'dart:io';

import 'package:contract_test/contract_test.dart';
import 'package:test/test.dart';

import 'support.dart';

Map<String, Object?> _minimal() =>
    OpenApiDocument.load(File('test/fixtures/minimal.yaml')).root;

Map<String, Object?> _at(Map<String, Object?> node, List<String> path) {
  var current = node;
  for (final key in path) {
    current = current[key]! as Map<String, Object?>;
  }
  return current;
}

List<String> _check(Map<String, Object?> root) => checkOpenApi(
  OpenApiDocument(jsonDecode(jsonEncode(root)) as Map<String, Object?>),
);

void main() {
  test('the contract passes', () {
    expect(checkOpenApi(contract), isEmpty);
  });

  test('the minimal fixture passes', () {
    expect(_check(_minimal()), isEmpty);
  });

  final health = ['paths', '/health', 'get'];
  final wallet = ['paths', '/wallet', 'post'];
  final schemas = ['components', 'schemas'];

  Map<String, Object?> png(Map<String, Object?> schema) => {
    'image/png': {'schema': schema},
  };

  test('a 2xx of image/png bytes passes', () {
    final root = _minimal();
    _at(root, [...health, 'responses', '200'])['content'] = png({
      'type': 'string',
      'format': 'binary',
    });
    expect(_check(root), isEmpty);
  });

  const binary = {'type': 'string', 'format': 'binary'};

  test('a 2xx of image/jpeg or image/png bytes passes', () {
    final root = _minimal();
    _at(root, [...health, 'responses', '200'])['content'] = {
      'image/jpeg': {'schema': binary},
      'image/png': {'schema': binary},
    };
    expect(_check(root), isEmpty);
  });

  test('a request body of image bytes passes, unclosed', () {
    final root = _minimal();
    _at(root, wallet)['requestBody'] = {
      'required': true,
      'content': {
        'image/jpeg': {'schema': binary},
      },
    };
    expect(_check(root), isEmpty);
  });

  final cases = <String, (void Function(Map<String, Object?>), String)>{
    'an OpenAPI version other than 3.0.x': (
      (root) => root['openapi'] = '3.1.0',
      'not 3.0.x',
    ),
    'a path without a leading slash': (
      (root) {
        final paths = _at(root, ['paths']);
        paths['health'] = paths.remove('/health');
      },
      'does not start with /',
    ),
    'a missing operationId': (
      (root) => _at(root, health).remove('operationId'),
      'has no operationId',
    ),
    'a duplicate operationId': (
      (root) => _at(root, wallet)['operationId'] = 'getHealth',
      'is not unique',
    ),
    'a missing summary': (
      (root) => _at(root, health).remove('summary'),
      'has no summary',
    ),
    'no 2xx response': (
      (root) => _at(root, [...health, 'responses']).remove('200'),
      'has no 2xx response',
    ),
    'a 2xx without a schema': (
      (root) => _at(root, [...health, 'responses', '200']).remove('content'),
      'has no application/json schema',
    ),
    'a 2xx of image/png that is not binary': (
      (root) => _at(root, [...health, 'responses', '200'])['content'] = png({
        'type': 'object',
      }),
      'has no application/json schema or image body',
    ),
    'a 2xx of an image type that is not png or jpeg': (
      (root) => _at(root, [...health, 'responses', '200'])['content'] = {
        'image/gif': {'schema': binary},
      },
      'has no application/json schema or image body',
    ),
    'a request body of bytes that are not an image': (
      (root) => _at(root, wallet)['requestBody'] = {
        'content': {
          'application/octet-stream': {'schema': binary},
        },
      },
      'request body has no application/json schema',
    ),
    'a 204 with a body': (
      (root) => _at(root, [...wallet, 'responses', '204'])['content'] = {
        'application/json': {
          'schema': {'type': 'object'},
        },
      },
      '204 declares a body',
    ),
    'an error that is not a Problem': (
      (root) => _at(root, [
        ...wallet,
        'responses',
        '400',
        'content',
        'application/problem+json',
      ])['schema'] = {'type': 'object'},
      'is not application/problem+json with Problem',
    ),
    'a dangling reference': (
      (root) => _at(root, [...schemas, 'Fill', 'properties'])['note'] = {
        r'$ref': '#/components/schemas/Nope',
      },
      'does not resolve',
    ),
    'an amount that is not Money': (
      (root) => _at(root, [...schemas, 'Fill', 'properties'])['amount'] = {
        'type': 'number',
      },
      'an amount must reference Money',
    ),
    'a limit that is not Money': (
      (root) => _at(root, [...schemas, 'Wallet', 'properties'])['limit'] = {
        'type': 'integer',
      },
      'an amount must reference Money',
    ),
    'a required name that is not a property': (
      (root) =>
          _at(root, [...schemas, 'Fill'])['required'] = ['amount', 'amout'],
      'required amout is not a property',
    ),
    'a public operation that requires a token': (
      (root) => _at(root, health).remove('security'),
      'is public and must declare security: []',
    ),
    'a private operation without a token': (
      (root) => _at(root, wallet)['security'] = <Object?>[],
      'must require bearerAuth',
    ),
    'a webhook without the verification header': (
      (root) =>
          _at(root, ['paths', '/webhooks/plaid', 'post']).remove('parameters'),
      'must require the Plaid-Verification header',
    ),
    'an open request body': (
      (root) => _at(root, [...schemas, 'Fill']).remove('additionalProperties'),
      'must be additionalProperties: false',
    ),
    'a number type': (
      (root) => _at(root, [...schemas, 'Wallet', 'properties'])['ratio'] = {
        'type': 'number',
      },
      'type number is not allowed',
    ),
    'a number in a type list': (
      (root) => _at(root, [...schemas, 'Fill', 'properties'])['ratio'] = {
        'type': ['number', 'null'],
      },
      'type number is not allowed',
    ),
    'a missing bearer scheme': (
      (root) => _at(root, ['components']).remove('securitySchemes'),
      'bearerAuth is not HTTP bearer',
    ),
  };

  for (final MapEntry(key: name, value: (breakIt, message)) in cases.entries) {
    test('fails on $name', () {
      final root = _minimal();
      breakIt(root);
      expect(_check(root), contains(contains(message)));
    });
  }
}
