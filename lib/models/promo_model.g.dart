// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromoModel _$PromoModelFromJson(Map<String, dynamic> json) => PromoModel(
  id: json['id'] as String,
  code: json['code'] as String,
  description: json['description'] as String?,
  discountType: json['discount_type'] as String,
  discountValue: (json['discount_value'] as num).toInt(),
  isActive: json['is_active'] as bool?,
  expiryDate: DateTime.parse(json['expiry_date'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$PromoModelToJson(PromoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'description': instance.description,
      'discount_type': instance.discountType,
      'discount_value': instance.discountValue,
      'is_active': instance.isActive,
      'expiry_date': instance.expiryDate.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };
