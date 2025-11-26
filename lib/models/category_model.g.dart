// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryModel _$CategoryModelFromJson(Map<String, dynamic> json) =>
    CategoryModel(
      id: json['id'] as String? ?? '',
      namaKategori: json['nama_kategori'] as String? ?? 'Nama Kosong',
      ikonUrl: json['ikonUrl'] as String?,
    );

Map<String, dynamic> _$CategoryModelToJson(CategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nama_kategori': instance.namaKategori,
      'ikonUrl': instance.ikonUrl,
    };
