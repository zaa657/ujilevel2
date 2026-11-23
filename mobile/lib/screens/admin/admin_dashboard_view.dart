import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/booking_model.dart';
import '../../models/kategori_model.dart';
import '../../models/lapangan_model.dart';
import '../../models/user_model.dart';
import '../../services/booking_service.dart';
import '../../services/lapangan_service.dart';
import 'admin_bookings_section.dart';
import 'admin_common_widgets.dart';
import 'admin_kategori_section.dart';
import 'admin_lapangan_section.dart';

class AdminDashboardScreen extends StatelessWidget {
  final UserModel user;

  const AdminDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      backgroundColor: AppColors.pureWhite,
      child: AdminManagementView(
        user: user,
      ),
    );
  }
}

class AdminManagementView extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onDataChanged;

  const AdminManagementView({
    super.key,
    required this.user,
    this.onDataChanged,
  });

  @override
  State<AdminManagementView> createState() => _AdminManagementViewState();
}

class _AdminManagementViewState extends State<AdminManagementView> {
  int _activeSection = 0;

  List<BookingModel> _bookings = [];
  bool _isLoadingBookings = true;
  String? _bookingsError;

  List<LapanganModel> _lapanganList = [];
  bool _isLoadingLapangan = true;
  String? _lapanganError;

  List<KategoriModel> _kategoriList = [];
  bool _isLoadingKategori = true;
  String? _kategoriError;

  @override
  void initState() {
    super.initState();
    _refreshAllData();
  }

  Future<void> _refreshAllData() async {
    await Future.wait([
      _loadBookings(),
      _loadLapangan(),
      _loadKategori(),
    ]);
    widget.onDataChanged?.call();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoadingBookings = true;
      _bookingsError = null;
    });
    try {
      final list = await BookingService.fetchBookings();
      if (!mounted) return;
      setState(() {
        _bookings = list;
        _isLoadingBookings = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bookingsError =
            'Gagal memuat daftar pesanan masuk. Pastikan server backend aktif.';
        _isLoadingBookings = false;
      });
    }
  }

  Future<void> _loadLapangan() async {
    setState(() {
      _isLoadingLapangan = true;
      _lapanganError = null;
    });
    try {
      final list = await LapanganService.fetchLapangan();
      if (!mounted) return;
      setState(() {
        _lapanganList = list;
        _isLoadingLapangan = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lapanganError =
            'Gagal memuat daftar lapangan. Pastikan server backend aktif.';
        _isLoadingLapangan = false;
      });
    }
  }

  Future<void> _loadKategori() async {
    setState(() {
      _isLoadingKategori = true;
      _kategoriError = null;
    });
    try {
      final list = await LapanganService.fetchKategori();
      if (!mounted) return;
      setState(() {
        _kategoriList = list;
        _isLoadingKategori = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _kategoriError =
            'Gagal memuat daftar kategori olahraga. Pastikan server backend aktif.';
        _isLoadingKategori = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Panel Admin • ${widget.user.name}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.courtInk,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Manajemen UMKM SportsBook',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.courtInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _refreshAllData,
                        tooltip: 'Muat ulang data admin',
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.courtInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AdminSectionTabButton(
                          label: 'Booking Masuk',
                          count: _bookings.length,
                          isSelected: _activeSection == 0,
                          onTap: () => setState(() => _activeSection = 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AdminSectionTabButton(
                          label: 'Data Lapangan',
                          count: _lapanganList.length,
                          isSelected: _activeSection == 1,
                          onTap: () => setState(() => _activeSection = 1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AdminSectionTabButton(
                          label: 'Kategori',
                          count: _kategoriList.length,
                          isSelected: _activeSection == 2,
                          onTap: () => setState(() => _activeSection = 2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: IndexedStack(
            index: _activeSection,
            children: [
              AdminBookingsSection(
                bookings: _bookings,
                isLoading: _isLoadingBookings,
                errorMessage: _bookingsError,
                onRefresh: _loadBookings,
                onDataChanged: () {
                  _refreshAllData();
                  widget.onDataChanged?.call();
                },
              ),
              AdminLapanganSection(
                lapanganList: _lapanganList,
                kategoriList: _kategoriList,
                isLoading: _isLoadingLapangan,
                errorMessage: _lapanganError,
                onRefresh: _loadLapangan,
                onDataChanged: () {
                  _refreshAllData();
                  widget.onDataChanged?.call();
                },
              ),
              AdminKategoriSection(
                kategoriList: _kategoriList,
                isLoading: _isLoadingKategori,
                errorMessage: _kategoriError,
                onRefresh: _loadKategori,
                onDataChanged: () {
                  _refreshAllData();
                  widget.onDataChanged?.call();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
