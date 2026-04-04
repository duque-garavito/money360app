// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Account _$AccountFromJson(Map<String, dynamic> json) => _Account(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
  color: json['color'] as String,
  createdAt: _timestampFromJson(json['createdAt']),
);

Map<String, dynamic> _$AccountToJson(_Account instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': instance.type,
  'balance': instance.balance,
  'color': instance.color,
  'createdAt': _timestampToJson(instance.createdAt),
};
