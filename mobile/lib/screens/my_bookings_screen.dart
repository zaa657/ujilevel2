import 'package:flutter/material.dart';
import '../core/api_config.dart';
import '../core/app_theme.dart';
import '../core/image_picker_helper.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'lapangan_detail_screen.dart';

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

  static const List<String> _statusFilters = [
    'Semua',
    'pending',
    'confirmed',
    'cancelled',
    'completed',
  ];

  List<BookingModel> get _filteredBookings {
    if (_selectedStatusFilter == 'Semua') {
      return widget.bookings;
    }
    return widget.bookings
        .where((b) => b.normalizedStatus == _selectedStatusFilter)
        .toList();
  }

  int _countForStatus(String filter) {
    if (filter == 'Semua') return widget.bookings.length;
    return widget.bookings
        .where((b) => b.normalizedStatus == filter)
        .length;
  }

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
    if (result.success) {
      widget.onRefresh();
    }
  }

  Future<void> _confirmCancelBooking(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Batalkan Pesanan?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.courtInk,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan pesanan ${booking.namaLapangan} pada tanggal ${booking.tanggalSewa} jam ${booking.jamMulai}?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Kembali',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.courtInk,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorInk,
              foregroundColor: AppColors.pureWhite,
              elevation: 0,
            ),
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
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
    if (result.success) {
      widget.onRefresh();
    }
  }

  Future<void> _showBookingAndBuktiBayarDetail(BookingModel booking) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.courtInk,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      tooltip: 'Tutup',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.courtInk,
                      ),
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
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.courtInk,
                            ),
                          ),
                          BookingStatusBadge(status: booking.statusLabel),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _DetailInfoRow(
                        label: 'Lapangan',
                        value: booking.namaLapangan,
                      ),
                      const SizedBox(height: 6),
                      _DetailInfoRow(
                        label: 'Kategori Olahraga',
                        value: booking.jenisOlahraga,
                      ),
                      const SizedBox(height: 6),
                      _DetailInfoRow(
                        label: 'Tanggal Sewa',
                        value: booking.tanggalSewa,
                      ),
                      const SizedBox(height: 6),
                      _DetailInfoRow(
                        label: 'Jam Mulai & Durasi',
                        value: '${booking.jamMulai} WIB (${booking.durasiJam} Jam)',
                      ),
                      const SizedBox(height: 6),
                      _DetailInfoRow(
                        label: 'Total Harga',
                        value: ApiConfig.formatRupiah(booking.totalHarga),
                        isHighlighted: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                const Text(
                  'Detail Bukti Bayar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.courtInk,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.fieldMist,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: booking.hasBuktiBayar
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: double.infinity,
                                height: 180,
                                child: Image.network(
                                  booking.fullBuktiBayarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.pureWhite,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.receipt_long_rounded,
                                          size: 42,
                                          color: AppColors.turfGreenDark,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          booking.buktiBayarFileName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.courtInk,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Bukti pembayaran telah terunggah',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: AppColors.turfGreenDark,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'File: ${booking.buktiBayarFileName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.courtInk,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.errorInk,
                                size: 24,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Belum ada file bukti bayar yang diunggah untuk pesanan ini.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.courtInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

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
                              booking.hasBuktiBayar
                                  ? 'Ganti Bukti Bayar'
                                  : 'Upload Bukti Bayar',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.courtInk,
                              foregroundColor: AppColors.pureWhite,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Batalkan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
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
                            Text(
                              'My Bookings',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.courtInk,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Riwayat Pesanan Saya',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: AppColors.courtInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onRefresh,
                        tooltip: 'Muat ulang pesanan',
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.courtInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statusFilters.map((filter) {
                      final isSelected = _selectedStatusFilter == filter;
                      final count = _countForStatus(filter);
                      return Material(
                        color: isSelected
                            ? AppColors.courtInk
                            : AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedStatusFilter = filter;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            child: Text(
                              '$filter ($count)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? AppColors.pureWhite
                                    : AppColors.courtInk,
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
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.courtInk),
                )
              : widget.errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.errorInk,
                              size: 34,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.errorInk,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: widget.onRefresh,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.courtInk,
                                foregroundColor: AppColors.pureWhite,
                                minimumSize: const Size(120, 44),
                              ),
                              child: const Text('Muat Ulang'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 40,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedStatusFilter == 'Semua'
                                      ? 'Belum ada riwayat pesanan lapangan.'
                                      : 'Tidak ada pesanan dengan status "$_selectedStatusFilter".',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.courtInk,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton(
                                  onPressed: _selectedStatusFilter == 'Semua'
                                      ? widget.onBrowseCatalog
                                      : () {
                                          setState(() {
                                            _selectedStatusFilter = 'Semua';
                                          });
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.turfGreen,
                                    foregroundColor: AppColors.courtInk,
                                    elevation: 0,
                                    minimumSize: const Size(160, 46),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    _selectedStatusFilter == 'Semua'
                                        ? 'Lihat Katalog Lapangan'
                                        : 'Tampilkan Semua Status',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                              return _MyBookingCard(
                                booking: booking,
                                onViewDetail: () =>
                                    _showBookingAndBuktiBayarDetail(booking),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class _MyBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onViewDetail;

  const _MyBookingCard({
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
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.turfGreenDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.namaLapangan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.courtInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  BookingStatusBadge(status: booking.statusLabel),
                ],
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fieldMist,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanggal: ${booking.tanggalSewa}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.courtInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Jam ${booking.jamMulai} WIB (${booking.durasiJam} Jam)',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ApiConfig.formatRupiah(booking.totalHarga),
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.turfGreenDark,
                      ),
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
                          booking.hasBuktiBayar
                              ? Icons.receipt_long_rounded
                              : Icons.warning_amber_rounded,
                          size: 17,
                          color: booking.hasBuktiBayar
                              ? AppColors.turfGreenDark
                              : AppColors.errorInk,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            booking.hasBuktiBayar
                                ? 'Bukti bayar: ${booking.buktiBayarFileName}'
                                : 'Belum ada bukti bayar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: booking.hasBuktiBayar
                                  ? AppColors.courtInk
                                  : AppColors.errorInk,
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
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        color: AppColors.courtInk,
                      ),
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

class BookingStatusBadge extends StatelessWidget {
  final String status;

  const BookingStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final lower = status.trim().toLowerCase();
    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;

    if (lower == 'confirmed' || lower == 'disetujui') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
      icon = Icons.check_circle_outline_rounded;
      label = 'confirmed';
    } else if (lower == 'cancelled' || lower == 'ditolak') {
      bg = AppColors.errorSurface;
      fg = AppColors.errorInk;
      icon = Icons.cancel_outlined;
      label = 'cancelled';
    } else if (lower == 'completed' || lower == 'selesai') {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF075985);
      icon = Icons.task_alt_rounded;
      label = 'completed';
    } else {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
      icon = Icons.schedule_rounded;
      label = 'pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _DetailInfoRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 15 : 13.5,
            fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
            color: isHighlighted ? AppColors.turfGreenDark : AppColors.courtInk,
          ),
        ),
      ],
    );
  }
}
