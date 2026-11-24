import 'package:geolocator/geolocator.dart';
import '../core/api_config.dart';

class LapanganModel {
  final int id;
  final int? idKategori;
  final String namaLapangan;
  final String jenisOlahraga;
  final double hargaPerJam;
  final String deskripsi;
  final String? fotoLapangan;
  final String? keteranganKategori;
  final double? latitude;
  final double? longitude;
  final String? alamat;

  const LapanganModel({
    required this.id,
    this.idKategori,
    required this.namaLapangan,
    required this.jenisOlahraga,
    required this.hargaPerJam,
    required this.deskripsi,
    this.fotoLapangan,
    this.keteranganKategori,
    this.latitude,
    this.longitude,
    this.alamat,
  });

  String? get fullFotoUrl => ApiConfig.resolveImageUrl(fotoLapangan);
  bool get hasCoordinates => latitude != null && longitude != null;

  double? calculateDistanceInMeters(double userLat, double userLon) {
    if (!hasCoordinates) return null;
    return Geolocator.distanceBetween(userLat, userLon, latitude!, longitude!);
  }

  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    }
    return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
  }

  factory LapanganModel.fromJson(Map<String, dynamic> json) {
    return LapanganModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      idKategori: json['id_kategori'] != null
          ? int.tryParse(json['id_kategori'].toString())
          : null,
      namaLapangan: (json['nama_lapangan'] ?? '').toString(),
      jenisOlahraga: (json['jenis_olahraga'] ?? '').toString(),
      hargaPerJam: double.tryParse(json['harga_per_jam']?.toString() ?? '0') ?? 0,
      deskripsi: (json['deskripsi'] ?? '').toString(),
      fotoLapangan: json['foto_lapangan']?.toString(),
      keteranganKategori: json['keterangan_kategori']?.toString(),
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      alamat: json['alamat']?.toString(),
    );
  }
}
