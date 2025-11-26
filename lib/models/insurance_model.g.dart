// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insurance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InsuranceModel _$InsuranceModelFromJson(Map<String, dynamic> json) =>
    InsuranceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Proteksi',
      dailyCost: (json['daily_cost'] as num?)?.toInt() ?? 0,
      coverage: json['coverage'] as String?,
    );

Map<String, dynamic> _$InsuranceModelToJson(InsuranceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'daily_cost': instance.dailyCost,
      'coverage': instance.coverage,
    };
