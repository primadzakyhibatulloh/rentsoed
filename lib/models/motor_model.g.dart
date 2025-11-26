// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'motor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MotorModel _$MotorModelFromJson(Map<String, dynamic> json) => MotorModel(
  id: json['id'] as String? ?? '',
  categoryId: json['category_id'] as String? ?? '',
  namaMotor: json['nama_motor'] as String? ?? 'Tanpa Nama',
  harga: (json['harga'] as num?)?.toInt() ?? 0,
  tahunKeluaran: (json['tahun_keluaran'] as num?)?.toInt(),
  warnaMotor: json['warna_motor'] as String?,
  fotoMotor: json['foto_motor'] as String?,
  cc: (json['cc'] as num?)?.toInt(),
  deskripsi: json['deskripsi'] as String?,
  isAvailable: json['is_available'] as bool?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$MotorModelToJson(MotorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category_id': instance.categoryId,
      'nama_motor': instance.namaMotor,
      'harga': instance.harga,
      'tahun_keluaran': instance.tahunKeluaran,
      'warna_motor': instance.warnaMotor,
      'foto_motor': instance.fotoMotor,
      'cc': instance.cc,
      'deskripsi': instance.deskripsi,
      'is_available': instance.isAvailable,
      'created_at': instance.createdAt?.toIso8601String(),
    };
