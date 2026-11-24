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

  const LapanganModel({
    required this.id,
    this.idKategori,
    required this.namaLapangan,
    required this.jenisOlahraga,
    required this.hargaPerJam,
    required this.deskripsi,
    this.fotoLapangan,
    this.keteranganKategori,
  });

  String? get fullFotoUrl => ApiConfig.resolveImageUrl(fotoLapangan);

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
    );
  }
}
