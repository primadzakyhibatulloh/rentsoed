import 'package:json_annotation/json_annotation.dart';

part 'review_model.g.dart';

@JsonSerializable()
class ReviewModel {
  final String id;
  final String bookingId; // FK ke booking
  final String userId;
  final String motorId;
  final int? rating; // 1-5
  final String? comment;
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.motorId,
    this.rating,
    this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => _$ReviewModelFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewModelToJson(this);
}