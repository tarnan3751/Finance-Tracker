// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pull_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PullPage extends PullPage {
  @override
  final BuiltList<PulledChangeLogEntry> entries;
  @override
  final int nextSince;
  @override
  final bool hasMore;

  factory _$PullPage([void Function(PullPageBuilder)? updates]) =>
      (PullPageBuilder()..update(updates))._build();

  _$PullPage._({
    required this.entries,
    required this.nextSince,
    required this.hasMore,
  }) : super._();
  @override
  PullPage rebuild(void Function(PullPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PullPageBuilder toBuilder() => PullPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PullPage &&
        entries == other.entries &&
        nextSince == other.nextSince &&
        hasMore == other.hasMore;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, entries.hashCode);
    _$hash = $jc(_$hash, nextSince.hashCode);
    _$hash = $jc(_$hash, hasMore.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PullPage')
          ..add('entries', entries)
          ..add('nextSince', nextSince)
          ..add('hasMore', hasMore))
        .toString();
  }
}

class PullPageBuilder implements Builder<PullPage, PullPageBuilder> {
  _$PullPage? _$v;

  ListBuilder<PulledChangeLogEntry>? _entries;
  ListBuilder<PulledChangeLogEntry> get entries =>
      _$this._entries ??= ListBuilder<PulledChangeLogEntry>();
  set entries(ListBuilder<PulledChangeLogEntry>? entries) =>
      _$this._entries = entries;

  int? _nextSince;
  int? get nextSince => _$this._nextSince;
  set nextSince(int? nextSince) => _$this._nextSince = nextSince;

  bool? _hasMore;
  bool? get hasMore => _$this._hasMore;
  set hasMore(bool? hasMore) => _$this._hasMore = hasMore;

  PullPageBuilder() {
    PullPage._defaults(this);
  }

  PullPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _entries = $v.entries.toBuilder();
      _nextSince = $v.nextSince;
      _hasMore = $v.hasMore;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PullPage other) {
    _$v = other as _$PullPage;
  }

  @override
  void update(void Function(PullPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PullPage build() => _build();

  _$PullPage _build() {
    _$PullPage _$result;
    try {
      _$result =
          _$v ??
          _$PullPage._(
            entries: entries.build(),
            nextSince: BuiltValueNullFieldError.checkNotNull(
              nextSince,
              r'PullPage',
              'nextSince',
            ),
            hasMore: BuiltValueNullFieldError.checkNotNull(
              hasMore,
              r'PullPage',
              'hasMore',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'entries';
        entries.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PullPage',
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
