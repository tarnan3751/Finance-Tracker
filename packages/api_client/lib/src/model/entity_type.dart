//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'entity_type.g.dart';

class EntityType extends EnumClass {
  @BuiltValueEnumConst(wireName: r'account')
  static const EntityType account = _$account;
  @BuiltValueEnumConst(wireName: r'transaction')
  static const EntityType transaction = _$transaction;
  @BuiltValueEnumConst(wireName: r'category')
  static const EntityType category = _$category;
  @BuiltValueEnumConst(wireName: r'rule')
  static const EntityType rule = _$rule;
  @BuiltValueEnumConst(wireName: r'budget')
  static const EntityType budget = _$budget;
  @BuiltValueEnumConst(wireName: r'recurring_stream')
  static const EntityType recurringStream = _$recurringStream;
  @BuiltValueEnumConst(wireName: r'bill_reminder')
  static const EntityType billReminder = _$billReminder;
  @BuiltValueEnumConst(wireName: r'goal')
  static const EntityType goal = _$goal;
  @BuiltValueEnumConst(wireName: r'settings')
  static const EntityType settings = _$settings;

  static Serializer<EntityType> get serializer => _$entityTypeSerializer;

  const EntityType._(String name) : super(name);

  static BuiltSet<EntityType> get values => _$values;
  static EntityType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class EntityTypeMixin = Object with _$EntityTypeMixin;
