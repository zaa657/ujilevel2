import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/kategori_model.dart';
import '../../services/lapangan_service.dart';
import '../lapangan_detail_screen.dart';
import 'admin_common_widgets.dart';

class AdminKategoriSection extends StatelessWidget {
  final List<KategoriModel> kategoriList;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback? onDataChanged;

  const AdminKategoriSection({
    super.key,
    required this.kategoriList,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    this.onDataChanged,
  });

  void _openKategoriFormSheet(BuildContext context, {KategoriModel? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _KategoriFormSheet(
        existing: existing,
        onSaved: () {
          onRefresh();
          onDataChanged?.call();
        },
      ),
    );
  }

  Future<void> _confirmDeleteKategori(
    BuildContext context,
    KategoriModel kategori,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Kategori?',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.courtInk),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus kategori "${kategori.jenisOlahraga}"?',
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

    final result = await LapanganService.deleteKategori(kategori.idKategori);
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
              onPressed: () => _openKategoriFormSheet(context),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Tambah Kategori', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
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
                  : kategoriList.isEmpty
                      ? AdminEmptyState(
                          icon: Icons.category_outlined,
                          title: 'Belum ada kategori olahraga terdaftar.',
                          actionLabel: 'Tambah Kategori Baru',
                          onAction: () => _openKategoriFormSheet(context),
                        )
                      : RefreshIndicator(
                          color: AppColors.courtInk,
                          onRefresh: onRefresh,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: kategoriList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final kat = kategoriList[index];
                              return AdminKategoriItemCard(
                                kategori: kat,
                                onEdit: () => _openKategoriFormSheet(context, existing: kat),
                                onDelete: () => _confirmDeleteKategori(context, kat),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class _KategoriFormSheet extends StatefulWidget {
  final KategoriModel? existing;
  final VoidCallback onSaved;

  const _KategoriFormSheet({this.existing, required this.onSaved});

  @override
  State<_KategoriFormSheet> createState() => _KategoriFormSheetState();
}

class _KategoriFormSheetState extends State<_KategoriFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _jenisController;
  late final TextEditingController _keteranganController;
  String? _error;
  bool _isSubmitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _jenisController = TextEditingController(text: widget.existing?.jenisOlahraga ?? '');
    _keteranganController = TextEditingController(text: widget.existing?.keterangan ?? '');
  }

  @override
  void dispose() {
    _jenisController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final jenis = _jenisController.text.trim();
    final ket = _keteranganController.text.trim();

    final result = _isEdit
        ? await LapanganService.updateKategori(
            idKategori: widget.existing!.idKategori,
            jenisOlahraga: jenis,
            keterangan: ket,
          )
        : await LapanganService.createKategori(
            jenisOlahraga: jenis,
            keterangan: ket,
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
                    _isEdit ? 'Edit Kategori Olahraga' : 'Tambah Kategori Olahraga',
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
              const Text('Jenis Olahraga', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.courtInk)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _jenisController,
                decoration: adminInputDecoration('Contoh: Futsal, Badminton, Basket'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Jenis olahraga wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              const Text('Keterangan Kategori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.courtInk)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _keteranganController,
                maxLines: 2,
                decoration: adminInputDecoration('Keterangan fasilitas atau standar lapangan'),
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
                      : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Kategori', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminKategoriItemCard extends StatelessWidget {
  final KategoriModel kategori;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminKategoriItemCard({
    super.key,
    required this.kategori,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: SportCategoryHelper.accentBgFor(kategori.jenisOlahraga),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              SportCategoryHelper.iconFor(kategori.jenisOlahraga),
              color: AppColors.courtInk,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kategori.jenisOlahraga,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.courtInk),
                ),
                const SizedBox(height: 2),
                Text(
                  kategori.keterangan?.isNotEmpty == true
                      ? kategori.keterangan!
                      : 'Fasilitas ${kategori.jenisOlahraga}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.courtInk),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.errorInk),
          ),
        ],
      ),
    );
  }
}
