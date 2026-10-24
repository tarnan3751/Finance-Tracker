// The lookups of OpenApiDocument against the real contract: component schemas, request
// and response schemas through $ref, a 204 without a body, and errors for what the
// contract does not declare.
import 'package:contract_test/contract_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('finds component schemas and rejects unknown ones', () {
    expect(contract.schema('Money')['required'], ['minor_units', 'currency']);
    expect(() => contract.schema('Nope'), throwsArgumentError);
  });

  test('lists every operation once', () {
    final ids = [
      for (final op in contract.operations) op.operation['operationId'],
    ];
    expect(ids, hasLength(27));
    expect(ids.toSet(), hasLength(27));
  });

  test('finds request schemas', () {
    expect(contract.requestSchema('/auth/login', 'POST'), {
      r'$ref': '#/components/schemas/LoginRequest',
    });
    expect(() => contract.requestSchema('/me', 'get'), throwsArgumentError);
  });

  test('finds response schemas through component responses', () {
    expect(
      contract.responseSchema('/plaid/items/{item_id}/sync', 'post', 202),
      {r'$ref': '#/components/schemas/SyncRun'},
    );
    expect(contract.responseSchema('/me', 'get', 401), {
      r'$ref': '#/components/schemas/Problem',
    });
    expect(contract.responseSchema('/auth/register', 'post', 400), {
      r'$ref': '#/components/schemas/ValidationProblem',
    });
  });

  test('a 204 has no response schema', () {
    expect(contract.responseSchema('/me', 'delete', 204), isNull);
  });

  test('reports response media types', () {
    expect(contract.responseMediaType('/me', 'get', 200), 'application/json');
    expect(
      contract.responseMediaType('/me', 'get', 401),
      'application/problem+json',
    );
    expect(contract.responseMediaType('/me', 'delete', 204), isNull);
    const logo = '/institutions/{institution_id}/logo';
    expect(contract.responseMediaType(logo, 'get', 200), 'image/png');
    expect(contract.responseSchema(logo, 'get', 200), isNull);
    expect([0x89, 0x50], conformsToResponse(contract, logo, 'get', 200));
    expect(<int>[], isNot(conformsToResponse(contract, logo, 'get', 200)));
    expect({'a': 1}, isNot(conformsToResponse(contract, logo, 'get', 200)));
  });

  test('undeclared operations and statuses are errors', () {
    expect(() => contract.operation('/nope', 'get'), throwsArgumentError);
    expect(
      () => contract.responseSchema('/me', 'get', 418),
      throwsArgumentError,
    );
  });

  test('resolves only local references', () {
    expect(
      contract.resolve('#/components/schemas/Hlc'),
      isA<Map<String, Object?>>(),
    );
    expect(
      () => contract.resolve('#/components/schemas/Nope'),
      throwsArgumentError,
    );
    expect(() => contract.resolve('other.yaml#/X'), throwsArgumentError);
  });
}
