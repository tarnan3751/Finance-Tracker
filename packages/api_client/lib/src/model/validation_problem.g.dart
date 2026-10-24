// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validation_problem.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ValidationProblemStatusEnum _$validationProblemStatusEnum_number400 =
    const ValidationProblemStatusEnum._('number400');

ValidationProblemStatusEnum _$validationProblemStatusEnumValueOf(String name) {
  switch (name) {
    case 'number400':
      return _$validationProblemStatusEnum_number400;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ValidationProblemStatusEnum>
_$validationProblemStatusEnumValues = BuiltSet<ValidationProblemStatusEnum>(
  const <ValidationProblemStatusEnum>[_$validationProblemStatusEnum_number400],
);

const ValidationProblemCodeEnum _$validationProblemCodeEnum_validationFailed =
    const ValidationProblemCodeEnum._('validationFailed');

ValidationProblemCodeEnum _$validationProblemCodeEnumValueOf(String name) {
  switch (name) {
    case 'validationFailed':
      return _$validationProblemCodeEnum_validationFailed;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ValidationProblemCodeEnum> _$validationProblemCodeEnumValues =
    BuiltSet<ValidationProblemCodeEnum>(const <ValidationProblemCodeEnum>[
      _$validationProblemCodeEnum_validationFailed,
    ]);

Serializer<ValidationProblemStatusEnum>
_$validationProblemStatusEnumSerializer =
    _$ValidationProblemStatusEnumSerializer();
Serializer<ValidationProblemCodeEnum> _$validationProblemCodeEnumSerializer =
    _$ValidationProblemCodeEnumSerializer();

class _$ValidationProblemStatusEnumSerializer
    implements PrimitiveSerializer<ValidationProblemStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number400': 400,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    400: 'number400',
  };

  @override
  final Iterable<Type> types = const <Type>[ValidationProblemStatusEnum];
  @override
  final String wireName = 'ValidationProblemStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    ValidationProblemStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ValidationProblemStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ValidationProblemStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ValidationProblemCodeEnumSerializer
    implements PrimitiveSerializer<ValidationProblemCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'validationFailed': 'validation_failed',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'validation_failed': 'validationFailed',
  };

  @override
  final Iterable<Type> types = const <Type>[ValidationProblemCodeEnum];
  @override
  final String wireName = 'ValidationProblemCodeEnum';

  @override
  Object serialize(
    Serializers serializers,
    ValidationProblemCodeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ValidationProblemCodeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ValidationProblemCodeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ValidationProblem extends ValidationProblem {
  @override
  final String type;
  @override
  final String title;
  @override
  final ValidationProblemStatusEnum status;
  @override
  final String? detail;
  @override
  final String? instance;
  @override
  final ValidationProblemCodeEnum code;
  @override
  final BuiltList<FieldError> errors;

  factory _$ValidationProblem([
    void Function(ValidationProblemBuilder)? updates,
  ]) => (ValidationProblemBuilder()..update(updates))._build();

  _$ValidationProblem._({
    required this.type,
    required this.title,
    required this.status,
    this.detail,
    this.instance,
    required this.code,
    required this.errors,
  }) : super._();
  @override
  ValidationProblem rebuild(void Function(ValidationProblemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ValidationProblemBuilder toBuilder() =>
      ValidationProblemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ValidationProblem &&
        type == other.type &&
        title == other.title &&
        status == other.status &&
        detail == other.detail &&
        instance == other.instance &&
        code == other.code &&
        errors == other.errors;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, detail.hashCode);
    _$hash = $jc(_$hash, instance.hashCode);
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, errors.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ValidationProblem')
          ..add('type', type)
          ..add('title', title)
          ..add('status', status)
          ..add('detail', detail)
          ..add('instance', instance)
          ..add('code', code)
          ..add('errors', errors))
        .toString();
  }
}

class ValidationProblemBuilder
    implements Builder<ValidationProblem, ValidationProblemBuilder> {
  _$ValidationProblem? _$v;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  ValidationProblemStatusEnum? _status;
  ValidationProblemStatusEnum? get status => _$this._status;
  set status(ValidationProblemStatusEnum? status) => _$this._status = status;

  String? _detail;
  String? get detail => _$this._detail;
  set detail(String? detail) => _$this._detail = detail;

  String? _instance;
  String? get instance => _$this._instance;
  set instance(String? instance) => _$this._instance = instance;

  ValidationProblemCodeEnum? _code;
  ValidationProblemCodeEnum? get code => _$this._code;
  set code(ValidationProblemCodeEnum? code) => _$this._code = code;

  ListBuilder<FieldError>? _errors;
  ListBuilder<FieldError> get errors =>
      _$this._errors ??= ListBuilder<FieldError>();
  set errors(ListBuilder<FieldError>? errors) => _$this._errors = errors;

  ValidationProblemBuilder() {
    ValidationProblem._defaults(this);
  }

  ValidationProblemBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _type = $v.type;
      _title = $v.title;
      _status = $v.status;
      _detail = $v.detail;
      _instance = $v.instance;
      _code = $v.code;
      _errors = $v.errors.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ValidationProblem other) {
    _$v = other as _$ValidationProblem;
  }

  @override
  void update(void Function(ValidationProblemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ValidationProblem build() => _build();

  _$ValidationProblem _build() {
    _$ValidationProblem _$result;
    try {
      _$result =
          _$v ??
          _$ValidationProblem._(
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'ValidationProblem',
              'type',
            ),
            title: BuiltValueNullFieldError.checkNotNull(
              title,
              r'ValidationProblem',
              'title',
            ),
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'ValidationProblem',
              'status',
            ),
            detail: detail,
            instance: instance,
            code: BuiltValueNullFieldError.checkNotNull(
              code,
              r'ValidationProblem',
              'code',
            ),
            errors: errors.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'errors';
        errors.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ValidationProblem',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
