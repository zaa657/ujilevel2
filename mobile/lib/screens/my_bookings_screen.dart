import 'package:flutter/material.dart';
import '../core/api_config.dart';
import '../core/app_theme.dart';
import '../core/image_picker_helper.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../widgets/booking_widgets.dart';
import 'admin/admin_common_widgets.dart';

export '../widgets/booking_widgets.dart';

class MyBookingsView extends StatefulWidget {
  final List<BookingModel> bookings;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;
  final VoidCallback onBrowseCatalog;

  const MyBookingsView({
    super.key,
    required this.bookings,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onBrowseCatalog,
  });

  @override
  State<MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<MyBookingsView> {
  String _selectedStatusFilter = 'Semua';
  static const _statusFilters = ['Semua', 'pending', 'confirmed', 'cancelled', 'completed'];

  List<BookingModel> get _filteredBookings => _selectedStatusFilter == 'Semua'
      ? widget.bookings
      : widget.bookings.where((b) => b.normalizedStatus == _selectedStatusFilter).toList();

  int _countForStatus(String filter) => filter == 'Semua'
      ? widget.bookings.length
      : widget.bookings.where((b) => b.normalizedStatus == filter).length;

  Future<void> _uploadBuktiBayarForBooking(BookingModel booking) async {
    final picked = await ImagePickerHelper.pickImage();
    if (picked == null || !mounted) return;

    final result = await BookingService.updateBuktiBayar(
      bookingId: booking.id,
      buktiBayarBytes: picked.bytes,
      buktiBayarFileName: picked.fileName,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.courtInk : AppColors.errorInk,
      ),
    );
    if (result.success) widget.onRefresh();
  }

  Future<void> _confirmCancelBooking(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Batalkan Pesanan?',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.courtInk),
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan pesanan ${booking.namaLapangan} pada tanggal ${booking.tanggalSewa} jam ${booking.jamMulai}?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.courtInk)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorInk,
              foregroundColor: AppColors.pureWhite,
              elevation: 0,
            ),
            child: const Text('Ya, Batalkan', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final result = await BookingService.deleteBooking(booking.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.courtInk : AppColors.errorInk,
      ),
    );
    if (result.success) widget.onRefresh();
  }

  Future<void> _showBookingAndBuktiBayarDetail(BookingModel booking) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Detail Pesanan & Bukti Bayar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.courtInk),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    tooltip: 'Tutup',
                    icon: const Icon(Icons.close_rounded, color: AppColors.courtInk),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.fieldMist,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ID Pesanan #SB-${booking.id.toString().padLeft(3, '0')}',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.courtInk),
                        ),
                        BookingStatusBadge(status: booking.normalizedStatus),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AdminInfoRow(label: 'Lapangan', value: booking.namaLapangan),
                    const SizedBox(height: 6),
                    AdminInfoRow(label: 'Kategori Olahraga', value: booking.jenisOlahraga),
                    const SizedBox(height: 6),
                    AdminInfoRow(label: 'Tanggal Sewa', value: booking.tanggalSewa),
                    const SizedBox(height: 6),
                    AdminInfoRow(label: 'Jam Mulai & Durasi', value: '${booking.jamMulai} WIB (${booking.durasiJam} Jam)'),
                    const SizedBox(height: 6),
                    AdminInfoRow(label: 'Total Harga', value: ApiConfig.formatRupiah(booking.totalHarga), highlight: true),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Detail Bukti Bayar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.courtInk)),
              const SizedBox(height: 8),
              BookingReceiptBox(booking: booking),
              if (booking.normalizedStatus == 'pending') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.of(sheetContext).pop();
                            await _uploadBuktiBayarForBooking(booking);
                          },
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: Text(
                            booking.hasBuktiBayar ? 'Ganti Bukti Bayar' : 'Upload Bukti Bayar',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.courtInk,
                            foregroundColor: AppColors.pureWhite,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await _confirmCancelBooking(booking);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorInk,
                          side: const BorderSide(color: AppColors.errorInk),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Batalkan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBookings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.turfGreen,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Bookings', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.courtInk)),
                            SizedBox(height: 2),
                            Text('Riwayat Pesanan Saya', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.courtInk)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onRefresh,
                        tooltip: 'Muat ulang pesanan',
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.courtInk),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statusFilters.map((filter) {
                      final isSelected = _selectedStatusFilter == filter;
                      return Material(
                        color: isSelected ? AppColors.courtInk : AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () => setState(() => _selectedStatusFilter = filter),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            child: Text(
                              '$filter (${_countForStatus(filter)})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? AppColors.pureWhite : AppColors.courtInk,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: widget.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.courtInk))
              : widget.errorMessage != null
                  ? AdminErrorState(message: widget.errorMessage!, onRetry: widget.onRefresh)
                  : filtered.isEmpty
                      ? AdminEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: _selectedStatusFilter == 'Semua'
                              ? 'Belum ada riwayat pesanan lapangan.'
                              : 'Tidak ada pesanan dengan status "$_selectedStatusFilter".',
                          actionLabel: _selectedStatusFilter == 'Semua' ? 'Lihat Katalog Lapangan' : 'Tampilkan Semua Status',
                          onAction: _selectedStatusFilter == 'Semua'
                              ? widget.onBrowseCatalog
                              : () => setState(() => _selectedStatusFilter = 'Semua'),
                        )
                      : RefreshIndicator(
                          color: AppColors.courtInk,
                          onRefresh: () async => widget.onRefresh(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final booking = filtered[index];
                              return MyBookingCard(
                                booking: booking,
                                onViewDetail: () => _showBookingAndBuktiBayarDetail(booking),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}
