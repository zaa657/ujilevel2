class KategoriModel {
  final int idKategori;
  final String jenisOlahraga;
  final String? keterangan;

  const KategoriModel({
    required this.idKategori,
    required this.jenisOlahraga,
    this.keterangan,
  });

  factory KategoriModel.fromJson(Map<String, dynamic> json) {
    return KategoriModel(
      idKategori: json['id_kategori'] is int
          ? json['id_kategori'] as int
          : int.tryParse(json['id_kategori']?.toString() ?? '0') ?? 0,
      jenisOlahraga: (json['jenis_olahraga'] ?? '').toString(),
      keterangan: json['keterangan']?.toString(),
    );
  }
}
