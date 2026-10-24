// The OAS 3.0 to draft 7 translation, rule by rule, on a small document: nullable with a
// type, a nullable enum, a nullable reference, readOnly and writeOnly by mode, strict
// mode, the boolean exclusive bounds, formats, dropped keywords and the error text.
import 'package:contract_test/contract_test.dart';
import 'package:test/test.dart';

final _document = OpenApiDocument.parse(r'''
openapi: 3.0.3
info: {title: t, version: '1'}
paths: {}
components:
  schemas:
    Money:
      type: object
      required: [minor_units, currency]
      properties:
        minor_units: {type: integer, format: int64}
        currency: {type: string, pattern: '^[A-Z]{3}$'}
      example: {minor_units: 1, currency: USD}
      x-note: dropped
    Colour:
      type: string
      enum: [red, green]
    Thing:
      type: object
      required: [id, name, secret, balance, colour, when, day]
      properties:
        id: {type: string, readOnly: true}
        name: {type: string, nullable: true}
        secret: {type: string, writeOnly: true}
        balance:
          allOf: [{$ref: '#/components/schemas/Money'}]
          nullable: true
        colour:
          type: string
          enum: [red, green]
          nullable: true
        when: {type: string, format: date-time}
        day: {type: string, format: date}
        free: {type: object, additionalProperties: true}
    Bounded:
      type: integer
      minimum: 0
      exclusiveMinimum: true
      maximum: 10
      exclusiveMaximum: true
      deprecated: true
''');

Map<String, Object?> _thing() => {
  'id': 't1',
  'name': null,
  'secret': 's',
  'balance': {'minor_units': -5, 'currency': 'USD'},
  'colour': 'red',
  'when': '2026-10-24T09:30:00.000Z',
  'day': '2026-10-24',
};

void main() {
  final validator = JsonValidator(_document);
  List<String> response(Object? value) =>
      validator.validateSchema('Thing', value, mode: ValidationMode.response);
  List<String> request(Object? value) =>
      validator.validateSchema('Thing', value, mode: ValidationMode.request);

  test('a conforming response has no errors', () {
    expect(response(_thing()..remove('secret')), isEmpty);
  });

  test('nullable with a type accepts null and still checks the type', () {
    expect(
      response(
        _thing()
          ..remove('secret')
          ..['name'] = 1,
      ),
      isNotEmpty,
    );
  });

  test('a nullable enum accepts null and rejects other values', () {
    expect(
      response(
        _thing()
          ..remove('secret')
          ..['colour'] = null,
      ),
      isEmpty,
    );
    expect(
      response(
        _thing()
          ..remove('secret')
          ..['colour'] = 'blue',
      ),
      isNotEmpty,
    );
  });

  test('a nullable reference accepts null and checks the target', () {
    expect(
      response(
        _thing()
          ..remove('secret')
          ..['balance'] = null,
      ),
      isEmpty,
    );
    expect(
      response(
        _thing()
          ..remove('secret')
          ..['balance'] = {'minor_units': 1.5, 'currency': 'usd'},
      ),
      isNotEmpty,
    );
  });

  test('a request drops readOnly properties, so sending one fails', () {
    final body = _thing()..remove('id');
    expect(request(body), isEmpty);
    expect(request(body..['id'] = 't1'), isNotEmpty);
  });

  test('a response drops writeOnly properties', () {
    expect(response(_thing()), isNotEmpty);
    expect(response(_thing()..remove('secret')), isEmpty);
  });

  test(
    'strict mode rejects an undeclared property; free-form objects stay open',
    () {
      final value = _thing()
        ..remove('secret')
        ..['free'] = {'anything': true};
      expect(response(value), isEmpty);
      expect(response(value..['extra'] = 1), isNotEmpty);
      final lenient = JsonValidator(_document, strict: false);
      expect(
        lenient.validateSchema('Thing', value, mode: ValidationMode.response),
        isEmpty,
      );
    },
  );

  test('a missing required property fails', () {
    expect(
      response(
        _thing()
          ..remove('secret')
          ..remove('day'),
      ),
      isNotEmpty,
    );
  });

  test('formats are checked', () {
    expect(
      response(
        _thing()
          ..remove('secret')
          ..['day'] = '2026-13-40',
      ),
      isNotEmpty,
    );
    expect(
      response(
        _thing()
          ..remove('secret')
          ..['when'] = 'yesterday',
      ),
      isNotEmpty,
    );
  });

  test('the boolean exclusive bounds become numeric ones', () {
    List<String> bounded(Object? value) => validator.validateSchema(
      'Bounded',
      value,
      mode: ValidationMode.response,
    );
    expect(bounded(5), isEmpty);
    expect(bounded(0), isNotEmpty);
    expect(bounded(10), isNotEmpty);
  });

  test('the translation drops OAS-only keywords and rewrites references', () {
    final translated = validator.toJsonSchema({
      r'$ref': '#/components/schemas/Thing',
    }, mode: ValidationMode.response);
    final definitions = translated['definitions']! as Map<String, Object?>;
    final money = definitions['Money']! as Map<String, Object?>;
    expect(money.keys, isNot(contains('example')));
    expect(money.keys, isNot(contains('x-note')));
    final balance =
        (translated['properties']! as Map<String, Object?>)['balance'];
    expect(balance, {
      'anyOf': [
        {
          'allOf': [
            {r'$ref': '#/definitions/Money'},
          ],
        },
        {'type': 'null'},
      ],
    });
    final bounded = definitions['Bounded']! as Map<String, Object?>;
    expect(bounded, {
      'type': 'integer',
      'exclusiveMinimum': 0,
      'exclusiveMaximum': 10,
    });
  });

  test('a reference outside components.schemas is refused', () {
    expect(
      () => validator.validate(
        {r'$ref': '#/components/responses/X'},
        null,
        mode: ValidationMode.response,
      ),
      throwsArgumentError,
    );
  });

  test('errors name the instance path', () {
    final errors = response(
      _thing()
        ..remove('secret')
        ..['balance'] = {'minor_units': 1, 'currency': 'usd'},
    );
    expect(errors, isNotEmpty);
    expect(errors.join('\n'), contains('/balance'));
  });

  test('the matchers describe the mismatch', () {
    final matcher = conformsToSchema(_document, 'Money');
    expect({'minor_units': 1, 'currency': 'USD'}, matcher);
    final state = <Object?, Object?>{};
    expect(matcher.matches({'minor_units': 1}, state), isFalse);
    final description = matcher
        .describeMismatch({'minor_units': 1}, StringDescription(), state, false)
        .toString();
    expect(description, contains('currency'));
  });
}
