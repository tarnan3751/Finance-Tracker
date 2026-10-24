// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PushRequest extends PushRequest {
  @override
  final BuiltList<ChangeLogEntry> entries;

  factory _$PushRequest([void Function(PushRequestBuilder)? updates]) =>
      (PushRequestBuilder()..update(updates))._build();

  _$PushRequest._({required this.entries}) : super._();
  @override
  PushRequest rebuild(void Function(PushRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PushRequestBuilder toBuilder() => PushRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PushRequest && entries == other.entries;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, entries.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'PushRequest',
    )..add('entries', entries)).toString();
  }
}

class PushRequestBuilder implements Builder<PushRequest, PushRequestBuilder> {
  _$PushRequest? _$v;

  ListBuilder<ChangeLogEntry>? _entries;
  ListBuilder<ChangeLogEntry> get entries =>
      _$this._entries ??= ListBuilder<ChangeLogEntry>();
  set entries(ListBuilder<ChangeLogEntry>? entries) =>
      _$this._entries = entries;

  PushRequestBuilder() {
    PushRequest._defaults(this);
  }

  PushRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _entries = $v.entries.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PushRequest other) {
    _$v = other as _$PushRequest;
  }

  @override
  void update(void Function(PushRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PushRequest build() => _build();

  _$PushRequest _build() {
    _$PushRequest _$result;
    try {
      _$result = _$v ?? _$PushRequest._(entries: entries.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'entries';
        entries.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PushRequest',
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
