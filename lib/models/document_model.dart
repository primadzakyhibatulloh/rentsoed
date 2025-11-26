import 'package:json_annotation/json_annotation.dart';

part 'document_model.g.dart';

@JsonSerializable()
class DocumentModel {
  final String id;
  final String userId;
  final String documentType; // KTP, SIM A, SIM C
  final String? documentNumber;
  final String imageUrl;
  final bool? isVerified;
  final DateTime? uploadDate;

  DocumentModel({
    required this.id,
    required this.userId,
    required this.documentType,
    this.documentNumber,
    required this.imageUrl,
    this.isVerified,
    this.uploadDate,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => _$DocumentModelFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentModelToJson(this);
}