import 'package:json_annotation/json_annotation.dart';

part 'booking_model.g.dart';

@JsonSerializable()
class BookingModel {
  final String id;
  final String userId;
  final String? email;
  final String motorId;
  final String? motorName;
  final String? motorImage;
  final DateTime? startDate; // Diubah dari text ke DateTime/Date
  final DateTime? endDate;   // Diubah dari text ke DateTime/Date
  final int? totalDays;
  final int? totalHarga; // total_price
  final String? status; // 'Menunggu Pembayaran', 'Dibayar', 'Selesai', 'Dibatalkan'
  final String? paymentProofUrl;
  final DateTime? paidAt;
  final DateTime? createdAt;

  BookingModel({
    required this.id,
    required this.userId,
    this.email,
    required this.motorId,
    this.motorName,
    this.motorImage,
    this.startDate,
    this.endDate,
    this.totalDays,
    this.totalHarga,
    this.status,
    this.paymentProofUrl,
    this.paidAt,
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => _$BookingModelFromJson(json);
  Map<String, dynamic> toJson() => _$BookingModelToJson(this);
}