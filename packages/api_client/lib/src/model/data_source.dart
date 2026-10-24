//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'data_source.g.dart';

/// Provenance (PLAN.md §7.1); `derived` values are labelled in the UI.
class DataSource extends EnumClass {
  @BuiltValueEnumConst(wireName: r'plaid')
  static const DataSource plaid = _$plaid;
  @BuiltValueEnumConst(wireName: r'manual')
  static const DataSource manual = _$manual;
  @BuiltValueEnumConst(wireName: r'import')
  static const DataSource import_ = _$import_;
  @BuiltValueEnumConst(wireName: r'derived')
  static const DataSource derived = _$derived;
  @BuiltValueEnumConst(wireName: r'demo')
  static const DataSource demo = _$demo;

  static Serializer<DataSource> get serializer => _$dataSourceSerializer;

  const DataSource._(String name) : super(name);

  static BuiltSet<DataSource> get values => _$values;
  static DataSource valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DataSourceMixin = Object with _$DataSourceMixin;
