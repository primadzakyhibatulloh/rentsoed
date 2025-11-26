// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvoiceModel _$InvoiceModelFromJson(Map<String, dynamic> json) => InvoiceModel(
  id: json['id'] as String,
  bookingId: json['bookingId'] as String,
  subtotal: (json['subtotal'] as num).toInt(),
  insuranceFee: (json['insuranceFee'] as num?)?.toInt(),
  promoCodeUsed: json['promoCodeUsed'] as String?,
  discountUsed: (json['discountUsed'] as num?)?.toInt(),
  finalTotal: (json['finalTotal'] as num).toInt(),
  adminId: json['adminId'] as String?,
  isPaid: json['isPaid'] as bool?,
  issuedDate: json['issuedDate'] == null
      ? null
      : DateTime.parse(json['issuedDate'] as String),
);

Map<String, dynamic> _$InvoiceModelToJson(InvoiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookingId': instance.bookingId,
      'subtotal': instance.subtotal,
      'insuranceFee': instance.insuranceFee,
      'promoCodeUsed': instance.promoCodeUsed,
      'discountUsed': instance.discountUsed,
      'finalTotal': instance.finalTotal,
      'adminId': instance.adminId,
      'isPaid': instance.isPaid,
      'issuedDate': instance.issuedDate?.toIso8601String(),
    };
