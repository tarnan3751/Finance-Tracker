//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'webhook_code.g.dart';

/// The webhook codes `/sandbox/item/fire_webhook` can fire, in Plaid's spelling (the one exception to snake_case enums). `PENDING_EXPIRATION` is not fireable in Sandbox (Plaid's documentation) and is not offered.
class WebhookCode extends EnumClass {
  @BuiltValueEnumConst(wireName: r'SYNC_UPDATES_AVAILABLE')
  static const WebhookCode syncUpdatesAvailable = _$syncUpdatesAvailable;
  @BuiltValueEnumConst(wireName: r'DEFAULT_UPDATE')
  static const WebhookCode defaultUpdate = _$defaultUpdate;
  @BuiltValueEnumConst(wireName: r'RECURRING_TRANSACTIONS_UPDATE')
  static const WebhookCode recurringTransactionsUpdate =
      _$recurringTransactionsUpdate;
  @BuiltValueEnumConst(wireName: r'NEW_ACCOUNTS_AVAILABLE')
  static const WebhookCode newAccountsAvailable = _$newAccountsAvailable;
  @BuiltValueEnumConst(wireName: r'PENDING_DISCONNECT')
  static const WebhookCode pendingDisconnect = _$pendingDisconnect;
  @BuiltValueEnumConst(wireName: r'USER_PERMISSION_REVOKED')
  static const WebhookCode userPermissionRevoked = _$userPermissionRevoked;
  @BuiltValueEnumConst(wireName: r'LOGIN_REPAIRED')
  static const WebhookCode loginRepaired = _$loginRepaired;
  @BuiltValueEnumConst(wireName: r'ERROR')
  static const WebhookCode error = _$error;

  static Serializer<WebhookCode> get serializer => _$webhookCodeSerializer;

  const WebhookCode._(String name) : super(name);

  static BuiltSet<WebhookCode> get values => _$values;
  static WebhookCode valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class WebhookCodeMixin = Object with _$WebhookCodeMixin;
