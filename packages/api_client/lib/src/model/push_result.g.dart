// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PushResult extends PushResult {
  @override
  final BuiltList<String> accepted;
  @override
  final BuiltList<RejectedEntry> rejected;

  factory _$PushResult([void Function(PushResultBuilder)? updates]) =>
      (PushResultBuilder()..update(updates))._build();

  _$PushResult._({required this.accepted, required this.rejected}) : super._();
  @override
  PushResult rebuild(void Function(PushResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PushResultBuilder toBuilder() => PushResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PushResult &&
        accepted == other.accepted &&
        rejected == other.rejected;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accepted.hashCode);
    _$hash = $jc(_$hash, rejected.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PushResult')
          ..add('accepted', accepted)
          ..add('rejected', rejected))
        .toString();
  }
}

class PushResultBuilder implements Builder<PushResult, PushResultBuilder> {
  _$PushResult? _$v;

  ListBuilder<String>? _accepted;
  ListBuilder<String> get accepted =>
      _$this._accepted ??= ListBuilder<String>();
  set accepted(ListBuilder<String>? accepted) => _$this._accepted = accepted;

  ListBuilder<RejectedEntry>? _rejected;
  ListBuilder<RejectedEntry> get rejected =>
      _$this._rejected ??= ListBuilder<RejectedEntry>();
  set rejected(ListBuilder<RejectedEntry>? rejected) =>
      _$this._rejected = rejected;

  PushResultBuilder() {
    PushResult._defaults(this);
  }

  PushResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accepted = $v.accepted.toBuilder();
      _rejected = $v.rejected.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PushResult other) {
    _$v = other as _$PushResult;
  }

  @override
  void update(void Function(PushResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PushResult build() => _build();

  _$PushResult _build() {
    _$PushResult _$result;
    try {
      _$result =
          _$v ??
          _$PushResult._(
            accepted: accepted.build(),
            rejected: rejected.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'accepted';
        accepted.build();
        _$failedField = 'rejected';
        rejected.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PushResult',
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
