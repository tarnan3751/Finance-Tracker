// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BillReminder _$BillReminderFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_BillReminder',
      json,
      ($checkedConvert) {
        final val = _BillReminder(
          id: $checkedConvert('id', (v) => v as String),
          streamId: $checkedConvert('stream_id', (v) => v as String?),
          name: $checkedConvert('name', (v) => v as String?),
          amount: $checkedConvert(
            'amount',
            (v) => v == null ? null : Money.fromJson(v as Map<String, dynamic>),
          ),
          dueDate: $checkedConvert(
            'due_date',
            (v) => LocalDate.fromJson(v as String),
          ),
          reminderOffsetDays: $checkedConvert(
            'reminder_offset_days',
            (v) => (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'streamId': 'stream_id',
        'dueDate': 'due_date',
        'reminderOffsetDays': 'reminder_offset_days',
      },
    );

Map<String, dynamic> _$BillReminderToJson(_BillReminder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'stream_id': instance.streamId,
      'name': instance.name,
      'amount': instance.amount?.toJson(),
      'due_date': instance.dueDate.toJson(),
      'reminder_offset_days': instance.reminderOffsetDays,
    };
