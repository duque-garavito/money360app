import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'account_model.freezed.dart';
part 'account_model.g.dart';

@freezed
abstract class Account with _$Account {
  const factory Account({
    required String id,
    required String name,
    required String type, // "cash", "bank", "credit", "saving"
    @Default(0.0) double balance,
    required String color,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    required DateTime createdAt,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}

DateTime _timestampFromJson(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  } else if (value is String) {
    return DateTime.parse(value);
  }
  return DateTime.now();
}

dynamic _timestampToJson(DateTime date) => Timestamp.fromDate(date);
