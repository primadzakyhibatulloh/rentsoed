// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingModel _$BookingModelFromJson(Map<String, dynamic> json) => BookingModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  email: json['email'] as String?,
  motorId: json['motorId'] as String,
  motorName: json['motorName'] as String?,
  motorImage: json['motorImage'] as String?,
  startDate: json['startDate'] == null
      ? null
      : DateTime.parse(json['startDate'] as String),
  endDate: json['endDate'] == null
      ? null
      : DateTime.parse(json['endDate'] as String),
  totalDays: (json['totalDays'] as num?)?.toInt(),
  totalHarga: (json['totalHarga'] as num?)?.toInt(),
  status: json['status'] as String?,
  paymentProofUrl: json['paymentProofUrl'] as String?,
  paidAt: json['paidAt'] == null
      ? null
      : DateTime.parse(json['paidAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$BookingModelToJson(BookingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'email': instance.email,
      'motorId': instance.motorId,
      'motorName': instance.motorName,
      'motorImage': instance.motorImage,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'totalDays': instance.totalDays,
      'totalHarga': instance.totalHarga,
      'status': instance.status,
      'paymentProofUrl': instance.paymentProofUrl,
      'paidAt': instance.paidAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };
