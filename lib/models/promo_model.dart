import 'package:json_annotation/json_annotation.dart';

part 'promo_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class PromoModel {
  final String id;
  final String code;
  final String? description;
  final String discountType;
  final int discountValue;
  final bool? isActive;
  final DateTime expiryDate;
  final DateTime? createdAt;

  PromoModel({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.isActive,
    required this.expiryDate,
    this.createdAt,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) => _$PromoModelFromJson(json);
  Map<String, dynamic> toJson() => _$PromoModelToJson(this);
}