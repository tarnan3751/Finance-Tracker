//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/student_loan_liability.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/mortgage_liability.dart';
import 'package:api_client/src/model/credit_liability.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'liabilities.g.dart';

/// Liabilities
///
/// Properties:
/// * [credit]
/// * [mortgage]
/// * [student]
@BuiltValue()
abstract class Liabilities implements Built<Liabilities, LiabilitiesBuilder> {
  @BuiltValueField(wireName: r'credit')
  BuiltList<CreditLiability> get credit;

  @BuiltValueField(wireName: r'mortgage')
  BuiltList<MortgageLiability> get mortgage;

  @BuiltValueField(wireName: r'student')
  BuiltList<StudentLoanLiability> get student;

  Liabilities._();

  factory Liabilities([void updates(LiabilitiesBuilder b)]) = _$Liabilities;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LiabilitiesBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Liabilities> get serializer => _$LiabilitiesSerializer();
}

class _$LiabilitiesSerializer implements PrimitiveSerializer<Liabilities> {
  @override
  final Iterable<Type> types = const [Liabilities, _$Liabilities];

  @override
  final String wireName = r'Liabilities';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Liabilities object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'credit';
    yield serializers.serialize(
      object.credit,
      specifiedType: const FullType(BuiltList, [FullType(CreditLiability)]),
    );
    yield r'mortgage';
    yield serializers.serialize(
      object.mortgage,
      specifiedType: const FullType(BuiltList, [FullType(MortgageLiability)]),
    );
    yield r'student';
    yield serializers.serialize(
      object.student,
      specifiedType: const FullType(BuiltList, [
        FullType(StudentLoanLiability),
      ]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Liabilities object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(
      serializers,
      object,
      specifiedType: specifiedType,
    ).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LiabilitiesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'credit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(CreditLiability),
            ]),
          ) as BuiltList<CreditLiability>;
          result.credit.replace(valueDes);
          break;
        case r'mortgage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(MortgageLiability),
            ]),
          ) as BuiltList<MortgageLiability>;
          result.mortgage.replace(valueDes);
          break;
        case r'student':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(StudentLoanLiability),
            ]),
          ) as BuiltList<StudentLoanLiability>;
          result.student.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Liabilities deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LiabilitiesBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}
