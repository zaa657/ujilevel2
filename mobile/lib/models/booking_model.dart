import '../core/api_config.dart';

class BookingModel {
  final int id;
  final int userId;
  final String? namaPenyewa;
  final String? emailPenyewa;
  final int lapanganId;
  final String namaLapangan;
  final String jenisOlahraga;
  final double hargaPerJam;
  final String? fotoLapangan;
  final String tanggalSewa;
  final String jamMulai;
  final int durasiJam;
  final double totalHarga;
  final String? buktiBayar;
  final String statusBooking;
  final String? createdAt;

  const BookingModel({
    required this.id,
    required this.userId,
    this.namaPenyewa,
    this.emailPenyewa,
    required this.lapanganId,
    required this.namaLapangan,
    required this.jenisOlahraga,
    required this.hargaPerJam,
    this.fotoLapangan,
    required this.tanggalSewa,
    required this.jamMulai,
    required this.durasiJam,
    required this.totalHarga,
    this.buktiBayar,
    required this.statusBooking,
    this.createdAt,
  });

  String? get fullFotoLapanganUrl => ApiConfig.resolveImageUrl(fotoLapangan);
  String? get fullBuktiBayarUrl => ApiConfig.resolveImageUrl(buktiBayar);

  bool get hasBuktiBayar => buktiBayar != null && buktiBayar!.trim().isNotEmpty;

  String get buktiBayarFileName {
    if (!hasBuktiBayar) return 'Belum ada bukti bayar';
    final parts = buktiBayar!.replaceAll('\\', '/').split('/');
    return parts.isNotEmpty ? parts.last : buktiBayar!;
  }

  /// Normalizes backend status into one of: 'pending', 'confirmed', 'cancelled', 'completed'
  String get normalizedStatus {
    final lower = statusBooking.trim().toLowerCase();
    if (lower == 'confirmed' || lower == 'disetujui') {
      return 'confirmed';
    }
    if (lower == 'cancelled' || lower == 'ditolak' || lower == 'dibatalkan') {
      return 'cancelled';
    }
    if (lower == 'completed' || lower == 'selesai') {
      return 'completed';
    }
    return 'pending';
  }

  String get statusLabel {
    switch (normalizedStatus) {
      case 'confirmed':
        return 'confirmed';
      case 'cancelled':
        return 'cancelled';
      case 'completed':
        return 'completed';
      default:
        return 'pending';
    }
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['tanggal_sewa'] ?? '').toString();
    final cleanDate = rawDate.contains('T') ? rawDate.split('T').first : rawDate;

    return BookingModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      namaPenyewa: json['nama_penyewa']?.toString(),
      emailPenyewa: json['email_penyewa']?.toString(),
      lapanganId: int.tryParse(json['lapangan_id']?.toString() ?? '0') ?? 0,
      namaLapangan: (json['nama_lapangan'] ?? 'Lapangan').toString(),
      jenisOlahraga: (json['jenis_olahraga'] ?? '').toString(),
      hargaPerJam: double.tryParse(json['harga_per_jam']?.toString() ?? '0') ?? 0,
      fotoLapangan: json['foto_lapangan']?.toString(),
      tanggalSewa: cleanDate,
      jamMulai: (json['jam_mulai'] ?? '').toString(),
      durasiJam: int.tryParse(json['durasi_jam']?.toString() ?? '1') ?? 1,
      totalHarga: double.tryParse(json['total_harga']?.toString() ?? '0') ?? 0,
      buktiBayar: json['bukti_bayar']?.toString(),
      statusBooking: (json['status_booking'] ?? 'pending').toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
