// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rejected_entry.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RejectedEntry extends RejectedEntry {
  @override
  final String hlc;
  @override
  final String reason;

  factory _$RejectedEntry([void Function(RejectedEntryBuilder)? updates]) =>
      (RejectedEntryBuilder()..update(updates))._build();

  _$RejectedEntry._({required this.hlc, required this.reason}) : super._();
  @override
  RejectedEntry rebuild(void Function(RejectedEntryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RejectedEntryBuilder toBuilder() => RejectedEntryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RejectedEntry && hlc == other.hlc && reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, hlc.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RejectedEntry')
          ..add('hlc', hlc)
          ..add('reason', reason))
        .toString();
  }
}

class RejectedEntryBuilder
    implements Builder<RejectedEntry, RejectedEntryBuilder> {
  _$RejectedEntry? _$v;

  String? _hlc;
  String? get hlc => _$this._hlc;
  set hlc(String? hlc) => _$this._hlc = hlc;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  RejectedEntryBuilder() {
    RejectedEntry._defaults(this);
  }

  RejectedEntryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _hlc = $v.hlc;
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RejectedEntry other) {
    _$v = other as _$RejectedEntry;
  }

  @override
  void update(void Function(RejectedEntryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RejectedEntry build() => _build();

  _$RejectedEntry _build() {
    final _$result =
        _$v ??
        _$RejectedEntry._(
          hlc: BuiltValueNullFieldError.checkNotNull(
            hlc,
            r'RejectedEntry',
            'hlc',
          ),
          reason: BuiltValueNullFieldError.checkNotNull(
            reason,
            r'RejectedEntry',
            'reason',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
