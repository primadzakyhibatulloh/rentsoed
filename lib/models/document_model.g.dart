// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentModel _$DocumentModelFromJson(Map<String, dynamic> json) =>
    DocumentModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      documentType: json['documentType'] as String,
      documentNumber: json['documentNumber'] as String?,
      imageUrl: json['imageUrl'] as String,
      isVerified: json['isVerified'] as bool?,
      uploadDate: json['uploadDate'] == null
          ? null
          : DateTime.parse(json['uploadDate'] as String),
    );

Map<String, dynamic> _$DocumentModelToJson(DocumentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'documentType': instance.documentType,
      'documentNumber': instance.documentNumber,
      'imageUrl': instance.imageUrl,
      'isVerified': instance.isVerified,
      'uploadDate': instance.uploadDate?.toIso8601String(),
    };
