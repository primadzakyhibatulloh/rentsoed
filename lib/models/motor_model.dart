// file: motor_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'motor_model.g.dart';

@JsonSerializable()
class MotorModel {
  @JsonKey(defaultValue: '') // Safetynet ID
  final String id;

  @JsonKey(name: 'category_id', defaultValue: '') // Pastikan nama key sesuai kolom DB
  final String categoryId;

  @JsonKey(name: 'nama_motor', defaultValue: 'Tanpa Nama') // Safetynet Nama Motor
  final String namaMotor;

  @JsonKey(name: 'harga', defaultValue: 0) // Safetynet Harga
  final int harga;

  @JsonKey(name: 'tahun_keluaran')
  final int? tahunKeluaran;

  @JsonKey(name: 'warna_motor')
  final String? warnaMotor;

  @JsonKey(name: 'foto_motor')
  final String? fotoMotor;

  @JsonKey(name: 'cc')
  final int? cc;

  @JsonKey(name: 'deskripsi')
  final String? deskripsi;

  @JsonKey(name: 'is_available')
  final bool? isAvailable;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  MotorModel({
    required this.id,
    required this.categoryId,
    required this.namaMotor,
    required this.harga,
    this.tahunKeluaran,
    this.warnaMotor,
    this.fotoMotor,
    this.cc,
    this.deskripsi,
    this.isAvailable,
    this.createdAt,
  });

  factory MotorModel.fromJson(Map<String, dynamic> json) => _$MotorModelFromJson(json);
  Map<String, dynamic> toJson() => _$MotorModelToJson(this);
}