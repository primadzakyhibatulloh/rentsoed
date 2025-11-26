// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewModel _$ReviewModelFromJson(Map<String, dynamic> json) => ReviewModel(
  id: json['id'] as String,
  bookingId: json['bookingId'] as String,
  userId: json['userId'] as String,
  motorId: json['motorId'] as String,
  rating: (json['rating'] as num?)?.toInt(),
  comment: json['comment'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ReviewModelToJson(ReviewModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookingId': instance.bookingId,
      'userId': instance.userId,
      'motorId': instance.motorId,
      'rating': instance.rating,
      'comment': instance.comment,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
