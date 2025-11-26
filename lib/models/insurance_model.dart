import 'package:json_annotation/json_annotation.dart';

part 'insurance_model.g.dart';

@JsonSerializable()
class InsuranceModel {
  @JsonKey(defaultValue: '')
  final String id;

  @JsonKey(defaultValue: 'Proteksi')
  final String name;

  // ✅ FIX: Jika daily_cost adalah NULL, gunakan 0
  @JsonKey(name: 'daily_cost', defaultValue: 0) 
  final int dailyCost; 

  // ✅ FIX: Jika coverage adalah NULL, gunakan string kosong
  @JsonKey(defaultValue: null) 
  final String? coverage;

  InsuranceModel({
    required this.id,
    required this.name,
    required this.dailyCost,
    this.coverage,
  });

  factory InsuranceModel.fromJson(Map<String, dynamic> json) => _$InsuranceModelFromJson(json);
  Map<String, dynamic> toJson() => _$InsuranceModelToJson(this);
}