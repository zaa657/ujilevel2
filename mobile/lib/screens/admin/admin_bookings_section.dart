import 'package:flutter/material.dart';
import '../../core/api_config.dart';
import '../../core/app_theme.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../my_bookings_screen.dart';
import 'admin_common_widgets.dart';

class AdminBookingsSection extends StatefulWidget {
  final List<BookingModel> bookings;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback? onDataChanged;

  const AdminBookingsSection({
    super.key,
    required this.bookings,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    this.onDataChanged,
  });

  @override
  State<AdminBookingsSection> createState() => _AdminBookingsSectionState();
}

class _AdminBookingsSectionState extends State<AdminBookingsSection> {
  String _bookingStatusFilter = 'Semua';

  static const List<String> _statusOptions = [
    'pending',
    'confirmed',
    'cancelled',
    'completed',
  ];

  List<BookingModel> get _filteredBookings {
    if (_bookingStatusFilter == 'Semua') return widget.bookings;
    return widget.bookings
        .where((b) => b.normalizedStatus == _bookingStatusFilter)
        .toList();
  }

  int _countBookingsByStatus(String filter) {
    if (filter == 'Semua') return widget.bookings.length;
    return widget.bookings.where((b) => b.normalizedStatus == filter).length;
  }

  Future<void> _openAdminBookingSheet(BookingModel booking) async {
    String selectedStatus = booking.normalizedStatus;
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  22,
                  20,
                  22,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Verifikasi Booking & Bukti Bayar',
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
                              Expanded(
                                child: Text(
                                  'Pesanan #SB-${booking.id.toString().padLeft(3, '0')}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.courtInk,
                                  ),
                                ),
                              ),
                              BookingStatusBadge(status: selectedStatus),
                            ],
                          ),
                          const SizedBox(height: 10),
                          AdminInfoRow(
                            label: 'Penyewa',
                            value: booking.namaPenyewa?.isNotEmpty == true
                                ? '${booking.namaPenyewa} (${booking.emailPenyewa ?? '-'})'
                                : 'User ID #${booking.userId}',
                          ),
                          const SizedBox(height: 6),
                          AdminInfoRow(
                            label: 'Lapangan',
                            value:
                                '${booking.namaLapangan} (${booking.jenisOlahraga})',
                          ),
                          const SizedBox(height: 6),
                          AdminInfoRow(
                            label: 'Tanggal & Jam',
                            value:
                                '${booking.tanggalSewa} • ${booking.jamMulai} WIB (${booking.durasiJam} Jam)',
                          ),
                          const SizedBox(height: 6),
                          AdminInfoRow(
                            label: 'Total Bayar',
                            value: ApiConfig.formatRupiah(booking.totalHarga),
                            highlight: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Foto Bukti Bayar',
                      style: TextStyle(
                        fontSize: 14.5,
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
                        borderRadius: BorderRadius.circular(16),
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
                                    height: 175,
                                    child: Image.network(
                                      booking.fullBuktiBayarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.pureWhite,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.receipt_long_rounded,
                                              size: 40,
                                              color: AppColors.turfGreenDark,
                                            ),
                                            const SizedBox(height: 6),
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
                                              'Lampiran bukti transfer tersedia',
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
                                      Icons.verified_rounded,
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
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.errorInk,
                                    size: 22,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Penyewa belum mengunggah foto bukti bayar.',
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

                    const SizedBox(height: 18),
                    const Text(
                      'Ubah Status Pesanan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.courtInk,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _statusOptions.map((st) {
                        final isSelected = selectedStatus == st;
                        return Material(
                          color: isSelected
                              ? AppColors.courtInk
                              : AppColors.fieldMist,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedStatus = st;
                              });
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.courtInk
                                      : AppColors.borderSubtle,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    size: 16,
                                    color: isSelected
                                        ? AppColors.turfGreen
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    st,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? AppColors.pureWhite
                                          : AppColors.courtInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      Navigator.of(sheetContext).pop();
                                      await _confirmDeleteBooking(booking);
                                    },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.errorInk,
                                size: 18,
                              ),
                              label: const Text(
                                'Hapus',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.errorInk,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.errorInk,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      setModalState(() {
                                        isSaving = true;
                                      });

                                      final result =
                                          await BookingService.updateBookingStatus(
                                        bookingId: booking.id,
                                        statusBooking: selectedStatus,
                                      );

                                      if (!sheetContext.mounted) return;
                                      setModalState(() {
                                        isSaving = false;
                                      });

                                      if (result.success) {
                                        Navigator.of(sheetContext).pop();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(result.message),
                                              backgroundColor:
                                                  AppColors.courtInk,
                                            ),
                                          );
                                          widget.onRefresh();
                                          widget.onDataChanged?.call();
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(result.message),
                                            backgroundColor:
                                                AppColors.errorInk,
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.courtInk,
                                foregroundColor: AppColors.pureWhite,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: AppColors.pureWhite,
                                      ),
                                    )
                                  : Text(
                                      'Simpan Status ($selectedStatus)',
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteBooking(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Data Pesanan?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.courtInk,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data pesanan #SB-${booking.id.toString().padLeft(3, '0')} (${booking.namaLapangan} - ${booking.namaPenyewa ?? 'User #${booking.userId}'})? Tindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
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
              'Ya, Hapus',
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
        backgroundColor:
            result.success ? AppColors.courtInk : AppColors.errorInk,
      ),
    );
    if (result.success) {
      widget.onRefresh();
      widget.onDataChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBookings;
    const filters = ['Semua', 'pending', 'confirmed', 'cancelled', 'completed'];

    return RefreshIndicator(
      color: AppColors.courtInk,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filters.map((f) {
              final selected = _bookingStatusFilter == f;
              final count = _countBookingsByStatus(f);
              return Material(
                color: selected ? AppColors.courtInk : AppColors.fieldMist,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _bookingStatusFilter = f;
                    });
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: Text(
                      '$f ($count)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color:
                            selected ? AppColors.pureWhite : AppColors.courtInk,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (widget.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.courtInk),
              ),
            )
          else if (widget.errorMessage != null)
            AdminErrorState(
              message: widget.errorMessage!,
              onRetry: widget.onRefresh,
            )
          else if (filtered.isEmpty)
            AdminEmptyState(
              icon: Icons.inbox_rounded,
              title: _bookingStatusFilter == 'Semua'
                  ? 'Belum ada pesanan penyewa yang masuk.'
                  : 'Tidak ada pesanan dengan status "$_bookingStatusFilter".',
              actionLabel: _bookingStatusFilter == 'Semua'
                  ? 'Muat Ulang Pesanan'
                  : 'Tampilkan Semua Status',
              onAction: _bookingStatusFilter == 'Semua'
                  ? widget.onRefresh
                  : () => setState(() => _bookingStatusFilter = 'Semua'),
            )
          else
            for (final booking in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AdminBookingItemCard(
                  booking: booking,
                  onManageTap: () => _openAdminBookingSheet(booking),
                  onDeleteTap: () => _confirmDeleteBooking(booking),
                ),
              ),
        ],
      ),
    );
  }
}

class AdminBookingItemCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onManageTap;
  final VoidCallback onDeleteTap;

  const AdminBookingItemCard({
    super.key,
    required this.booking,
    required this.onManageTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final tenantText = (booking.namaPenyewa != null &&
            booking.namaPenyewa!.isNotEmpty)
        ? '${booking.namaPenyewa} (${booking.emailPenyewa ?? '-'})'
        : 'Penyewa #${booking.userId}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#SB-${booking.id.toString().padLeft(3, '0')} • ${booking.jenisOlahraga}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.turfGreenDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.namaLapangan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.courtInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Penyewa: $tenantText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BookingStatusBadge(status: booking.statusLabel),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.fieldMist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${booking.tanggalSewa} • ${booking.jamMulai} WIB (${booking.durasiJam} Jam)',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.courtInk,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ApiConfig.formatRupiah(booking.totalHarga),
                  style: const TextStyle(
                    fontSize: 14.5,
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
                      size: 16,
                      color: booking.hasBuktiBayar
                          ? AppColors.turfGreenDark
                          : AppColors.errorInk,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.hasBuktiBayar
                            ? 'Bukti: ${booking.buktiBayarFileName}'
                            : 'Belum ada bukti bayar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onDeleteTap,
                    tooltip: 'Hapus data pesanan',
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.errorInk,
                      backgroundColor: AppColors.fieldMist,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: onManageTap,
                      icon: const Icon(Icons.fact_check_outlined, size: 16),
                      label: const Text(
                        'Cek Bukti & Status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.turfGreen,
                        foregroundColor: AppColors.courtInk,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
