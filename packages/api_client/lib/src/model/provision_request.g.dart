// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provision_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProvisionRequest extends ProvisionRequest {
  @override
  final ProvisionPersona persona;
  @override
  final int? seed;
  @override
  final int? days;

  factory _$ProvisionRequest([
    void Function(ProvisionRequestBuilder)? updates,
  ]) => (ProvisionRequestBuilder()..update(updates))._build();

  _$ProvisionRequest._({required this.persona, this.seed, this.days})
    : super._();
  @override
  ProvisionRequest rebuild(void Function(ProvisionRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProvisionRequestBuilder toBuilder() =>
      ProvisionRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProvisionRequest &&
        persona == other.persona &&
        seed == other.seed &&
        days == other.days;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, persona.hashCode);
    _$hash = $jc(_$hash, seed.hashCode);
    _$hash = $jc(_$hash, days.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProvisionRequest')
          ..add('persona', persona)
          ..add('seed', seed)
          ..add('days', days))
        .toString();
  }
}

class ProvisionRequestBuilder
    implements Builder<ProvisionRequest, ProvisionRequestBuilder> {
  _$ProvisionRequest? _$v;

  ProvisionPersona? _persona;
  ProvisionPersona? get persona => _$this._persona;
  set persona(ProvisionPersona? persona) => _$this._persona = persona;

  int? _seed;
  int? get seed => _$this._seed;
  set seed(int? seed) => _$this._seed = seed;

  int? _days;
  int? get days => _$this._days;
  set days(int? days) => _$this._days = days;

  ProvisionRequestBuilder() {
    ProvisionRequest._defaults(this);
  }

  ProvisionRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _persona = $v.persona;
      _seed = $v.seed;
      _days = $v.days;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProvisionRequest other) {
    _$v = other as _$ProvisionRequest;
  }

  @override
  void update(void Function(ProvisionRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProvisionRequest build() => _build();

  _$ProvisionRequest _build() {
    final _$result =
        _$v ??
        _$ProvisionRequest._(
          persona: BuiltValueNullFieldError.checkNotNull(
            persona,
            r'ProvisionRequest',
            'persona',
          ),
          seed: seed,
          days: days,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
