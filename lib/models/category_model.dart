import 'package:json_annotation/json_annotation.dart';

part 'category_model.g.dart'; 

@JsonSerializable()
class CategoryModel {
  @JsonKey(defaultValue: '') 
  final String id;
  
  @JsonKey(name: 'nama_kategori', defaultValue: 'Nama Kosong')
  final String namaKategori;

  final String? ikonUrl; 

  CategoryModel({
    required this.id,
    required this.namaKategori,
    this.ikonUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => _$CategoryModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);
}