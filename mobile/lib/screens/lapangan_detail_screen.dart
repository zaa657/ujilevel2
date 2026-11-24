import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api_config.dart';
import '../core/app_theme.dart';
import '../core/image_picker_helper.dart';
import '../models/lapangan_model.dart';
import '../services/booking_service.dart';
import '../widgets/court_widgets.dart';

export '../widgets/court_widgets.dart';

class LapanganDetailScreen extends StatefulWidget {
  final LapanganModel lapangan;
  const LapanganDetailScreen({super.key, required this.lapangan});

  @override
  State<LapanganDetailScreen> createState() => _LapanganDetailScreenState();
}

class _LapanganDetailScreenState extends State<LapanganDetailScreen> {
  late DateTime _selectedDate;
  String _selectedJamMulai = '10:00';
  int _durasiJam = 1;
  Uint8List? _buktiBayarBytes;
  String? _buktiBayarFileName;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const _availableHours = [
    '08:00', '09:00', '10:00', '11:00', '13:00', '14:00',
    '15:00', '16:00', '17:00', '19:00', '20:00', '21:00',
  ];

  static const _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  String get _formattedTanggalSewa =>
      '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  String get _formattedReadableDate =>
      '${_selectedDate.day} ${_months[_selectedDate.month - 1]} ${_selectedDate.year}';

  String get _calculatedEndHour {
    final startHour = int.tryParse(_selectedJamMulai.split(':').first) ?? 10;
    return '${(startHour + _durasiJam).clamp(0, 24).toString().padLeft(2, '0')}:00';
  }

  double get _totalHarga => widget.lapangan.hargaPerJam * _durasiJam;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _pickBuktiFromDeviceDirectly() async {
    final picked = await ImagePickerHelper.pickImage();
    if (!mounted || picked == null) return;
    if (picked.bytes.lengthInBytes > 2 * 1024 * 1024) {
      setState(() => _errorMessage = 'Ukuran file bukti bayar maksimal 2 MB.');
      return;
    }
    setState(() {
      _buktiBayarBytes = picked.bytes;
      _buktiBayarFileName = picked.fileName;
      _errorMessage = null;
    });
  }

  Future<void> _submitBooking() async {
    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    final result = await BookingService.createBooking(
      lapanganId: widget.lapangan.id,
      tanggalSewa: _formattedTanggalSewa,
      jamMulai: _selectedJamMulai,
      durasiJam: _durasiJam,
      buktiBayarBytes: _buktiBayarBytes,
      buktiBayarFileName: _buktiBayarFileName,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppColors.courtInk),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lap = widget.lapangan;
    return ResponsiveContainer(
      backgroundColor: AppColors.pureWhite,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 235,
                        child: CourtPhotoDisplay(
                          imageUrl: lap.fullFotoUrl,
                          jenisOlahraga: lap.jenisOlahraga,
                        ),
                      ),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Material(
                                color: AppColors.pureWhite,
                                shape: const CircleBorder(),
                                elevation: 2,
                                child: IconButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  tooltip: 'Kembali ke Katalog',
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.courtInk),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(color: AppColors.turfGreen, borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  lap.jenisOlahraga,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.courtInk),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (lap.keteranganKategori != null && lap.keteranganKategori!.isNotEmpty) ...[
                          Text(
                            lap.keteranganKategori!,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.turfGreenDark),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          lap.namaLapangan,
                          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.courtInk, height: 1.2),
                        ),
                        if (lap.alamat != null && lap.alamat!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 16, color: AppColors.turfGreenDark),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  lap.alamat!,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              ApiConfig.formatRupiah(lap.hargaPerJam),
                              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppColors.turfGreenDark),
                            ),
                            const SizedBox(width: 6),
                            const Text('/ jam', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          lap.deskripsi.isNotEmpty
                              ? lap.deskripsi
                              : 'Lapangan olahraga siap pakai untuk jadwal latihan maupun pertandingan.',
                          style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.courtInk)),
                        const SizedBox(height: 16),
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppColors.errorSurface, borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.errorInk, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.errorInk),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Tanggal Sewa', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.courtInk)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_formattedReadableDate ($_formattedTanggalSewa)',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _pickDate,
                              style: TextButton.styleFrom(foregroundColor: AppColors.courtInk, minimumSize: const Size(64, 44)),
                              child: const Text(
                                'Pilih Tanggal',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, decoration: TextDecoration.underline, color: AppColors.courtInk),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final offset in [(label: 'Hari Ini', days: 0), (label: 'Besok', days: 1), (label: 'Lusa', days: 2)])
                              QuickSelectChip(
                                label: offset.label,
                                isSelected: _isSameDay(_selectedDate, DateTime.now().add(Duration(days: offset.days))),
                                onTap: () => setState(() => _selectedDate = DateTime.now().add(Duration(days: offset.days))),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('Jam Mulai', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.courtInk)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_selectedJamMulai - $_calculatedEndHour WIB',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.turfGreenDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableHours
                              .map((jam) => QuickSelectChip(
                                    label: jam,
                                    isSelected: _selectedJamMulai == jam,
                                    onTap: () => setState(() => _selectedJamMulai = jam),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('Durasi Sewa', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.courtInk)),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: _durasiJam > 1 ? () => setState(() => _durasiJam--) : null,
                                  tooltip: 'Kurangi durasi',
                                  icon: const Icon(Icons.remove_circle_outline_rounded),
                                  color: AppColors.courtInk,
                                ),
                                Text('$_durasiJam Jam', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.courtInk)),
                                IconButton(
                                  onPressed: _durasiJam < 8 ? () => setState(() => _durasiJam++) : null,
                                  tooltip: 'Tambah durasi',
                                  icon: const Icon(Icons.add_circle_outline_rounded),
                                  color: AppColors.courtInk,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [1, 2, 3, 4]
                              .map((jam) => QuickSelectChip(
                                    label: '$jam Jam',
                                    isSelected: _durasiJam == jam,
                                    onTap: () => setState(() => _durasiJam = jam),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 22),
                        const Text('Bukti Pembayaran', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.courtInk)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.fieldMist,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: _buktiBayarBytes == null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(color: AppColors.pureWhite, borderRadius: BorderRadius.circular(12)),
                                          child: const Icon(Icons.photo_library_outlined, color: AppColors.courtInk),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Belum ada foto bukti bayar', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.courtInk)),
                                              SizedBox(height: 2),
                                              Text('Pilih foto struk transfer dari Galeri atau File (JPG/PNG)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: ElevatedButton.icon(
                                        onPressed: _pickBuktiFromDeviceDirectly,
                                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                                        label: const Text('Pilih dari Galeri / File', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.courtInk,
                                          foregroundColor: AppColors.pureWhite,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(_buktiBayarBytes!, width: 52, height: 52, fit: BoxFit.cover),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _buktiBayarFileName ?? 'bukti_bayar.png',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.courtInk),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${(_buktiBayarBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB siap dikirim',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.turfGreenDark),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _pickBuktiFromDeviceDirectly,
                                      child: const Text('Ganti', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.courtInk)),
                                    ),
                                    IconButton(
                                      onPressed: () => setState(() {
                                        _buktiBayarBytes = null;
                                        _buktiBayarFileName = null;
                                      }),
                                      tooltip: 'Hapus bukti bayar',
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorInk),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: AppColors.borderSubtle, height: 1),
                        const SizedBox(height: 18),
                        const Text('Price details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.courtInk)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Harga Sewa (${ApiConfig.formatRupiah(lap.hargaPerJam)} x $_durasiJam jam)',
                                style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ApiConfig.formatRupiah(_totalHarga),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.courtInk),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('Total Harga (total_harga)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.courtInk)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ApiConfig.formatRupiah(_totalHarga),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.turfGreenDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
            decoration: const BoxDecoration(
              color: AppColors.pureWhite,
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.courtInk,
                    foregroundColor: AppColors.pureWhite,
                    disabledBackgroundColor: AppColors.textMuted,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.pureWhite),
                        )
                      : Text(
                          'Confirm & Booking (${ApiConfig.formatRupiah(_totalHarga)})',
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
