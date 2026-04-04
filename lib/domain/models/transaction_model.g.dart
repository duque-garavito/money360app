// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    _TransactionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      accountId: json['accountId'] as String,
      categoryId: json['categoryId'] as String,
      date: json['date'] as String,
      createdAt: _timestampFromJson(json['createdAt']),
    );

Map<String, dynamic> _$TransactionModelToJson(_TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': instance.amount,
      'description': instance.description,
      'accountId': instance.accountId,
      'categoryId': instance.categoryId,
      'date': instance.date,
      'createdAt': _timestampToJson(instance.createdAt),
    };
