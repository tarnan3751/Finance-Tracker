//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'problem_code.g.dart';

class ProblemCode extends EnumClass {
  @BuiltValueEnumConst(wireName: r'validation_failed')
  static const ProblemCode validationFailed = _$validationFailed;
  @BuiltValueEnumConst(wireName: r'invalid_credentials')
  static const ProblemCode invalidCredentials = _$invalidCredentials;
  @BuiltValueEnumConst(wireName: r'email_taken')
  static const ProblemCode emailTaken = _$emailTaken;
  @BuiltValueEnumConst(wireName: r'token_expired')
  static const ProblemCode tokenExpired = _$tokenExpired;
  @BuiltValueEnumConst(wireName: r'token_revoked')
  static const ProblemCode tokenRevoked = _$tokenRevoked;
  @BuiltValueEnumConst(wireName: r'not_found')
  static const ProblemCode notFound = _$notFound;
  @BuiltValueEnumConst(wireName: r'conflict')
  static const ProblemCode conflict = _$conflict;
  @BuiltValueEnumConst(wireName: r'item_login_required')
  static const ProblemCode itemLoginRequired = _$itemLoginRequired;
  @BuiltValueEnumConst(wireName: r'plaid_error')
  static const ProblemCode plaidError = _$plaidError;
  @BuiltValueEnumConst(wireName: r'rate_limited')
  static const ProblemCode rateLimited = _$rateLimited;
  @BuiltValueEnumConst(wireName: r'internal')
  static const ProblemCode internal = _$internal;
  @BuiltValueEnumConst(wireName: r'sync_cursor_invalid')
  static const ProblemCode syncCursorInvalid = _$syncCursorInvalid;
  @BuiltValueEnumConst(wireName: r'webhook_unverified')
  static const ProblemCode webhookUnverified = _$webhookUnverified;

  static Serializer<ProblemCode> get serializer => _$problemCodeSerializer;

  const ProblemCode._(String name) : super(name);

  static BuiltSet<ProblemCode> get values => _$values;
  static ProblemCode valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ProblemCodeMixin = Object with _$ProblemCodeMixin;
