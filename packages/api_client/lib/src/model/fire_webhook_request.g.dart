// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fire_webhook_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FireWebhookRequest extends FireWebhookRequest {
  @override
  final WebhookCode webhookCode;

  factory _$FireWebhookRequest([
    void Function(FireWebhookRequestBuilder)? updates,
  ]) => (FireWebhookRequestBuilder()..update(updates))._build();

  _$FireWebhookRequest._({required this.webhookCode}) : super._();
  @override
  FireWebhookRequest rebuild(
    void Function(FireWebhookRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  FireWebhookRequestBuilder toBuilder() =>
      FireWebhookRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FireWebhookRequest && webhookCode == other.webhookCode;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, webhookCode.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'FireWebhookRequest',
    )..add('webhookCode', webhookCode)).toString();
  }
}

class FireWebhookRequestBuilder
    implements Builder<FireWebhookRequest, FireWebhookRequestBuilder> {
  _$FireWebhookRequest? _$v;

  WebhookCode? _webhookCode;
  WebhookCode? get webhookCode => _$this._webhookCode;
  set webhookCode(WebhookCode? webhookCode) =>
      _$this._webhookCode = webhookCode;

  FireWebhookRequestBuilder() {
    FireWebhookRequest._defaults(this);
  }

  FireWebhookRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _webhookCode = $v.webhookCode;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FireWebhookRequest other) {
    _$v = other as _$FireWebhookRequest;
  }

  @override
  void update(void Function(FireWebhookRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FireWebhookRequest build() => _build();

  _$FireWebhookRequest _build() {
    final _$result =
        _$v ??
        _$FireWebhookRequest._(
          webhookCode: BuiltValueNullFieldError.checkNotNull(
            webhookCode,
            r'FireWebhookRequest',
            'webhookCode',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
