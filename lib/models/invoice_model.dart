import 'package:json_annotation/json_annotation.dart';

part 'invoice_model.g.dart';

@JsonSerializable()
class InvoiceModel {
  final String id;
  final String bookingId;
  final int subtotal;
  final int? insuranceFee;
  final String? promoCodeUsed; // Kode promo yang dipakai
  final int? discountUsed; // Diskon nominal
  final int finalTotal;
  final String? adminId;
  final bool? isPaid;
  final DateTime? issuedDate;

  InvoiceModel({
    required this.id,
    required this.bookingId,
    required this.subtotal,
    this.insuranceFee,
    this.promoCodeUsed,
    this.discountUsed,
    required this.finalTotal,
    this.adminId,
    this.isPaid,
    this.issuedDate,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => _$InvoiceModelFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceModelToJson(this);
}