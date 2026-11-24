import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/booking_model.dart';
import '../models/kategori_model.dart';
import '../models/lapangan_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/lapangan_service.dart';
import 'admin_dashboard_screen.dart';
import 'lapangan_detail_screen.dart';
import 'my_bookings_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  final int initialTabIndex;

  const HomeScreen({
    super.key,
    required this.user,
    this.initialTabIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentTabIndex;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedKategori = 'Semua';

  List<KategoriModel> _kategoriList = [];
  List<LapanganModel> _lapanganList = [];
  bool _isLoadingCatalog = true;
  String? _catalogError;

  List<BookingModel> _bookingList = [];
  bool _isLoadingBookings = false;
  String? _bookingError;

  bool get _isAdmin => widget.user.isAdmin;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    if (!_isAdmin) {
      _loadCatalogData();
      if (_currentTabIndex == 1) {
        _loadBookingsData();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogData() async {
    setState(() {
      _isLoadingCatalog = true;
      _catalogError = null;
    });
    try {
      final results = await Future.wait([
        LapanganService.fetchKategori(),
        LapanganService.fetchLapangan(),
      ]);
      if (!mounted) return;
      setState(() {
        _kategoriList = results[0] as List<KategoriModel>;
        _lapanganList = results[1] as List<LapanganModel>;
        _isLoadingCatalog = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _catalogError = 'Gagal memuat katalog lapangan. Pastikan server backend aktif.';
        _isLoadingCatalog = false;
      });
    }
  }

  Future<void> _loadBookingsData() async {
    setState(() {
      _isLoadingBookings = true;
      _bookingError = null;
    });
    try {
      final bookings = await BookingService.fetchBookings();
      if (!mounted) return;
      setState(() {
        _bookingList = bookings;
        _isLoadingBookings = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bookingError = 'Gagal memuat riwayat booking.';
        _isLoadingBookings = false;
      });
    }
  }

  List<LapanganModel> get _filteredLapangan {
    final query = _searchQuery.trim().toLowerCase();
    return _lapanganList.where((lap) {
      final matchesKategori = _selectedKategori == 'Semua' ||
          lap.jenisOlahraga.toLowerCase() == _selectedKategori.toLowerCase();
      final matchesSearch = query.isEmpty ||
          lap.namaLapangan.toLowerCase().contains(query) ||
          lap.jenisOlahraga.toLowerCase().contains(query) ||
          lap.deskripsi.toLowerCase().contains(query);
      return matchesKategori && matchesSearch;
    }).toList();
  }

  Future<void> _openLapanganDetail(LapanganModel lapangan) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LapanganDetailScreen(lapangan: lapangan)),
    );
    if (created == true && mounted) {
      setState(() => _currentTabIndex = 1);
      _loadBookingsData();
    }
  }

  void _logout() {
    AuthService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  void _resetCatalogFilter() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedKategori = 'Semua';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      backgroundColor: AppColors.pureWhite,
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentTabIndex,
              children: _isAdmin
                  ? [
                      AdminManagementView(user: widget.user),
                      _buildProfileTab(),
                    ]
                  : [
                      _buildCatalogTab(),
                      MyBookingsView(
                        bookings: _bookingList,
                        isLoading: _isLoadingBookings,
                        errorMessage: _bookingError,
                        onRefresh: _loadBookingsData,
                        onBrowseCatalog: () => setState(() => _currentTabIndex = 0),
                      ),
                      _buildProfileTab(),
                    ],
            ),
          ),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildCatalogTab() {
    final filtered = _filteredLapangan;
    return Column(
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                              'Halo, ${widget.user.name}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.courtInk),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Katalog Lapangan Olahraga',
                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.courtInk),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _loadCatalogData,
                        tooltip: 'Muat ulang katalog',
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.courtInk),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(color: AppColors.pureWhite, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.courtInk),
                            decoration: const InputDecoration(
                              hintText: 'Cari nama lapangan atau olahraga...',
                              hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty || _selectedKategori != 'Semua')
                          IconButton(
                            onPressed: _resetCatalogFilter,
                            tooltip: 'Reset filter',
                            icon: const Icon(Icons.tune_rounded, size: 19, color: AppColors.courtInk),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.tune_rounded, size: 19, color: AppColors.courtInk),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.courtInk,
            onRefresh: _loadCatalogData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                SizedBox(
                  height: 86,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      CategoryCircleItem(
                        label: 'Semua',
                        icon: Icons.grid_view_rounded,
                        bgColor: const Color(0xFFECFDF5),
                        isSelected: _selectedKategori == 'Semua',
                        onTap: () => setState(() => _selectedKategori = 'Semua'),
                      ),
                      for (final kat in _kategoriList)
                        CategoryCircleItem(
                          label: kat.jenisOlahraga,
                          icon: SportCategoryHelper.iconFor(kat.jenisOlahraga),
                          bgColor: SportCategoryHelper.accentBgFor(kat.jenisOlahraga),
                          isSelected: _selectedKategori.toLowerCase() == kat.jenisOlahraga.toLowerCase(),
                          onTap: () => setState(() => _selectedKategori = kat.jenisOlahraga),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (_isLoadingCatalog)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(child: CircularProgressIndicator(color: AppColors.courtInk)),
                  )
                else if (_catalogError != null)
                  AdminErrorState(message: _catalogError!, onRetry: _loadCatalogData)
                else if (filtered.isEmpty)
                  AdminEmptyState(
                    icon: Icons.sports_soccer_rounded,
                    title: 'Tidak ada lapangan yang sesuai dengan filter.',
                    actionLabel: 'Tampilkan Semua',
                    onAction: _resetCatalogFilter,
                  )
                else
                  for (final lap in filtered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: LapanganCatalogCard(
                        lapangan: lap,
                        onTap: () => _openLapanganDetail(lap),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profil Akun', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.courtInk)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.fieldMist,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.turfGreen, borderRadius: BorderRadius.circular(14)),
                    child: Text(
                      widget.user.role.toUpperCase(),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.courtInk),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.courtInk)),
                  const SizedBox(height: 4),
                  Text(widget.user.email, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Keluar Akun', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.courtInk,
                  side: const BorderSide(color: AppColors.courtInk, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final items = _isAdmin
        ? [
            (icon: Icons.admin_panel_settings_rounded, label: 'Admin UMKM'),
            (icon: Icons.person_rounded, label: 'Profile'),
          ]
        : [
            (icon: Icons.home_rounded, label: 'Home'),
            (icon: Icons.receipt_long_rounded, label: 'Booking'),
            (icon: Icons.person_rounded, label: 'Profile'),
          ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                BottomNavItem(
                  icon: items[i].icon,
                  label: items[i].label,
                  isActive: _currentTabIndex == i,
                  onTap: () {
                    setState(() => _currentTabIndex = i);
                    if (!_isAdmin && i == 1) _loadBookingsData();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
