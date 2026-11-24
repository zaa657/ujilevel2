import 'package:flutter/material.dart';
import '../core/api_config.dart';
import '../core/app_theme.dart';
import '../models/booking_model.dart';
import 'court_widgets.dart';

class BookingStatusBadge extends StatelessWidget {
  final String status;
  const BookingStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.trim().toLowerCase();
    final (Color bg, Color fg, IconData icon, String label) = switch (lower) {
      'confirmed' || 'disetujui' => (const Color(0xFFDCFCE7), const Color(0xFF166534), Icons.check_circle_outline_rounded, 'confirmed'),
      'cancelled' || 'ditolak' => (AppColors.errorSurface, AppColors.errorInk, Icons.cancel_outlined, 'cancelled'),
      'completed' || 'selesai' => (const Color(0xFFE0F2FE), const Color(0xFF075985), Icons.task_alt_rounded, 'completed'),
      _ => (const Color(0xFFFEF3C7), const Color(0xFF92400E), Icons.schedule_rounded, 'pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

class MyBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onViewDetail;

  const MyBookingCard({
    super.key,
    required this.booking,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.pureWhite,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onViewDetail,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: CourtPhotoDisplay(
                        imageUrl: booking.fullFotoLapanganUrl,
                        jenisOlahraga: booking.jenisOlahraga,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#SB-${booking.id.toString().padLeft(3, '0')} • ${booking.jenisOlahraga}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.turfGreenDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.namaLapangan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.courtInk),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  BookingStatusBadge(status: booking.normalizedStatus),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.fieldMist, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tanggal: ${booking.tanggalSewa}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.courtInk)),
                          const SizedBox(height: 2),
                          Text('Jam ${booking.jamMulai} WIB (${booking.durasiJam} Jam)', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ApiConfig.formatRupiah(booking.totalHarga),
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.turfGreenDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          booking.hasBuktiBayar ? Icons.receipt_long_rounded : Icons.warning_amber_rounded,
                          size: 17,
                          color: booking.hasBuktiBayar ? AppColors.turfGreenDark : AppColors.errorInk,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            booking.hasBuktiBayar ? 'Bukti bayar: ${booking.buktiBayarFileName}' : 'Belum ada bukti bayar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: booking.hasBuktiBayar ? AppColors.courtInk : AppColors.errorInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onViewDetail,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.courtInk,
                      minimumSize: const Size(80, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text(
                      'Detail Bukti Bayar',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, decoration: TextDecoration.underline, color: AppColors.courtInk),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
