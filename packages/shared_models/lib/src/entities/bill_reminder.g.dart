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
            (v) => v == null
                ? const [2]
                : const _OffsetsConverter().fromJson(v as List),
          ),
          cadence: $checkedConvert(
            'cadence',
            (v) => $enumDecodeNullable(_$RecurringCadenceEnumMap, v),
          ),
          accountId: $checkedConvert('account_id', (v) => v as String?),
          liabilityAccountId: $checkedConvert(
            'liability_account_id',
            (v) => v as String?,
          ),
          reminderMinutes: $checkedConvert(
            'reminder_minutes',
            (v) => v == null
                ? defaultReminderMinutes
                : const _MinutesConverter().fromJson((v as num).toInt()),
          ),
          active: $checkedConvert('active', (v) => v as bool? ?? true),
          autopay: $checkedConvert('autopay', (v) => v as bool? ?? false),
          paidOccurrences: $checkedConvert(
            'paid_occurrences',
            (v) => v == null
                ? const <LocalDate>[]
                : const _PaidConverter().fromJson(v as List),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'streamId': 'stream_id',
        'dueDate': 'due_date',
        'reminderOffsetDays': 'reminder_offset_days',
        'accountId': 'account_id',
        'liabilityAccountId': 'liability_account_id',
        'reminderMinutes': 'reminder_minutes',
        'paidOccurrences': 'paid_occurrences',
      },
    );

Map<String, dynamic> _$BillReminderToJson(
  _BillReminder instance,
) => <String, dynamic>{
  'id': instance.id,
  'stream_id': instance.streamId,
  'name': instance.name,
  'amount': instance.amount?.toJson(),
  'due_date': instance.dueDate.toJson(),
  'reminder_offset_days': const _OffsetsConverter().toJson(
    instance.reminderOffsetDays,
  ),
  'cadence': _$RecurringCadenceEnumMap[instance.cadence],
  'account_id': instance.accountId,
  'liability_account_id': instance.liabilityAccountId,
  'reminder_minutes': const _MinutesConverter().toJson(
    instance.reminderMinutes,
  ),
  'active': instance.active,
  'autopay': instance.autopay,
  'paid_occurrences': const _PaidConverter().toJson(instance.paidOccurrences),
};

const _$RecurringCadenceEnumMap = {
  RecurringCadence.weekly: 'weekly',
  RecurringCadence.biweekly: 'biweekly',
  RecurringCadence.semiMonthly: 'semi_monthly',
  RecurringCadence.quarterly: 'quarterly',
  RecurringCadence.monthly: 'monthly',
  RecurringCadence.annually: 'annually',
  RecurringCadence.unknown: 'unknown',
};
