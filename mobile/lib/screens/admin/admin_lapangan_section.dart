import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/api_config.dart';
import '../../core/app_theme.dart';
import '../../core/image_picker_helper.dart';
import '../../models/kategori_model.dart';
import '../../models/lapangan_model.dart';
import '../../services/lapangan_service.dart';
import '../lapangan_detail_screen.dart';
import 'admin_common_widgets.dart';

class AdminLapanganSection extends StatelessWidget {
  final List<LapanganModel> lapanganList;
  final List<KategoriModel> kategoriList;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback? onDataChanged;

  const AdminLapanganSection({
    super.key,
    required this.lapanganList,
    required this.kategoriList,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    this.onDataChanged,
  });

  void _openLapanganFormSheet(BuildContext context, {LapanganModel? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _LapanganFormSheet(
        existing: existing,
        kategoriList: kategoriList,
        onSaved: () {
          onRefresh();
          onDataChanged?.call();
        },
      ),
    );
  }

  Future<void> _confirmDeleteLapangan(
    BuildContext context,
    LapanganModel lapangan,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Data Lapangan?',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.courtInk),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${lapangan.namaLapangan}"?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.courtInk)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorInk,
              foregroundColor: AppColors.pureWhite,
              elevation: 0,
            ),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await LapanganService.deleteLapangan(lapangan.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.courtInk : AppColors.errorInk,
      ),
    );
    if (result.success) {
      onRefresh();
      onDataChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => _openLapanganFormSheet(context),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Tambah Lapangan', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.courtInk,
                foregroundColor: AppColors.pureWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.courtInk))
              : errorMessage != null
                  ? AdminErrorState(message: errorMessage!, onRetry: onRefresh)
                  : lapanganList.isEmpty
                      ? AdminEmptyState(
                          icon: Icons.stadium_outlined,
                          title: 'Belum ada data lapangan yang terdaftar.',
                          actionLabel: 'Tambah Lapangan Baru',
                          onAction: () => _openLapanganFormSheet(context),
                        )
                      : RefreshIndicator(
                          color: AppColors.courtInk,
                          onRefresh: onRefresh,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: lapanganList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final lap = lapanganList[index];
                              return AdminLapanganItemCard(
                                lapangan: lap,
                                onEdit: () => _openLapanganFormSheet(context, existing: lap),
                                onDelete: () => _confirmDeleteLapangan(context, lap),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class _LapanganFormSheet extends StatefulWidget {
  final LapanganModel? existing;
  final List<KategoriModel> kategoriList;
  final VoidCallback onSaved;

  const _LapanganFormSheet({
    this.existing,
    required this.kategoriList,
    required this.onSaved,
  });

  @override
  State<_LapanganFormSheet> createState() => _LapanganFormSheetState();
}

class _LapanganFormSheetState extends State<_LapanganFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _hargaController;
  late final TextEditingController _deskripsiController;
  late final TextEditingController _jenisController;

  int? _selectedKategoriId;
  String _selectedJenis = 'Futsal';
  Uint8List? _pickedBytes;
  String? _pickedFileName;
  String? _error;
  bool _isSubmitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _namaController = TextEditingController(text: item?.namaLapangan ?? '');
    _hargaController = TextEditingController(text: item != null ? item.hargaPerJam.round().toString() : '');
    _deskripsiController = TextEditingController(text: item?.deskripsi ?? '');

    if (item != null) {
      _selectedKategoriId = item.idKategori;
      _selectedJenis = item.jenisOlahraga;
    } else if (widget.kategoriList.isNotEmpty) {
      _selectedKategoriId = widget.kategoriList.first.idKategori;
      _selectedJenis = widget.kategoriList.first.jenisOlahraga;
    }
    _jenisController = TextEditingController(text: _selectedJenis);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _deskripsiController.dispose();
    _jenisController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePickerHelper.pickImage();
    if (picked != null && mounted) {
      setState(() {
        _pickedBytes = picked.bytes;
        _pickedFileName = picked.fileName;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final nama = _namaController.text.trim();
    final jenis = _jenisController.text.trim();
    final harga = double.parse(_hargaController.text.trim());
    final deskripsi = _deskripsiController.text.trim();

    final result = _isEdit
        ? await LapanganService.updateLapangan(
            id: widget.existing!.id,
            namaLapangan: nama,
            jenisOlahraga: jenis,
            hargaPerJam: harga,
            deskripsi: deskripsi,
            idKategori: _selectedKategoriId,
            fotoBytes: _pickedBytes,
            fotoFileName: _pickedFileName,
          )
        : await LapanganService.createLapangan(
            namaLapangan: nama,
            jenisOlahraga: jenis,
            hargaPerJam: harga,
            deskripsi: deskripsi,
            idKategori: _selectedKategoriId,
            fotoBytes: _pickedBytes,
            fotoFileName: _pickedFileName,
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppColors.courtInk),
      );
      widget.onSaved();
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 20, 22, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdit ? 'Edit Data Lapangan' : 'Tambah Lapangan Baru',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.courtInk),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.courtInk),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.errorSurface, borderRadius: BorderRadius.circular(10)),
                  child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.errorInk, fontWeight: FontWeight.w600)),
                ),
              ],
              const SizedBox(height: 14),
              const Text('Nama Lapangan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.courtInk)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _namaController,
                decoration: adminInputDecoration('Masukkan nama lapangan'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nama lapangan wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              const Text('Kategori Olahraga', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.courtInk)),
              const SizedBox(height: 6),
              if (widget.kategoriList.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.kategoriList.map((kat) {
                    final isSelected = _selectedKategoriId == kat.idKategori;
                    return ChoiceChip(
                      label: Text(kat.jenisOlahraga),
                      selected: isSelected,
                      selectedColor: AppColors.turfGreen,
                      backgroundColor: AppColors.fieldMist,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: AppColors.courtInk,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedKategoriId = kat.idKategori;
                          _selectedJenis = kat.jenisOlahraga;
                          _jenisController.text = kat.jenisOlahraga;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _jenisController,
                decoration: adminInputDecoration('Jenis olahraga (Futsal, Badminton, dll)'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Jenis olahraga wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              const Text('Harga per Jam (Rp)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.courtInk)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _hargaController,
                keyboardType: TextInputType.number,
                decoration: adminInputDecoration('Contoh: 120000'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Harga per jam wajib diisi';
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) return 'Harga harus angka lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              const Text('Deskripsi Lapangan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.courtInk)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 2,
                decoration: adminInputDecoration('Fasilitas, rumput sintetis, penerangan, dll'),
              ),
              const SizedBox(height: 14),
              const Text('Foto Lapangan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.courtInk)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.fieldMist,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    if (_pickedBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_pickedBytes!, width: 48, height: 48, fit: BoxFit.cover),
                      )
                    else if (widget.existing?.fotoLapangan != null)
                      const Icon(Icons.image_outlined, size: 36, color: AppColors.turfGreenDark)
                    else
                      const Icon(Icons.photo_library_outlined, size: 36, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pickedFileName ??
                            (widget.existing?.fotoLapangan != null ? 'Foto terpasang' : 'Belum ada foto'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.courtInk),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _pickPhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.turfGreen,
                        foregroundColor: AppColors.courtInk,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Pilih', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.courtInk,
                    foregroundColor: AppColors.pureWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pureWhite))
                      : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Lapangan', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminLapanganItemCard extends StatelessWidget {
  final LapanganModel lapangan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminLapanganItemCard({
    super.key,
    required this.lapangan,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: SizedBox(
              width: double.infinity,
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CourtPhotoDisplay(
                    imageUrl: lapangan.fullFotoUrl,
                    jenisOlahraga: lapangan.jenisOlahraga,
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.courtInk.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lapangan.jenisOlahraga,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.pureWhite),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${ApiConfig.formatRupiah(lapangan.hargaPerJam)}/jam',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.courtInk),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lapangan.namaLapangan,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.courtInk),
                      ),
                    ),
                    Text(
                      'ID #${lapangan.id}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                    ),
                  ],
                ),
                if (lapangan.alamat != null && lapangan.alamat!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    lapangan.alamat!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  lapangan.deskripsi.isNotEmpty ? lapangan.deskripsi : 'Belum ada deskripsi lapangan.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.courtInk,
                          side: const BorderSide(color: AppColors.borderSubtle),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Hapus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorInk,
                          side: const BorderSide(color: AppColors.errorInk),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
