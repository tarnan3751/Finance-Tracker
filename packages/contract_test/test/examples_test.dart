// Every example in the contract's component schemas conforms to its own schema, so the
// examples the generated documentation and readers rely on are never wrong.
import 'package:contract_test/contract_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  for (final MapEntry(key: name, value: schema) in contract.schemas.entries) {
    if (schema is! Map<String, Object?> || !schema.containsKey('example')) {
      continue;
    }
    test('the $name example conforms', () {
      final requestOnly = name.endsWith('Request') || name == 'ChangeLogEntry';
      expect(
        schema['example'],
        conformsToSchema(
          contract,
          name,
          mode: requestOnly ? ValidationMode.request : ValidationMode.response,
        ),
      );
    });
  }

  test('the main schemas carry examples', () {
    for (final name in [
      'Money',
      'Account',
      'Transaction',
      'Item',
      'ChangeLogEntry',
      'PulledChangeLogEntry',
      'Problem',
      'AuthTokens',
      'Health',
    ]) {
      expect(contract.schema(name), contains('example'), reason: name);
    }
  });
}
