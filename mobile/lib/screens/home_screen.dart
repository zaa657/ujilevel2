import 'package:flutter/material.dart';
import '../core/api_config.dart';
import '../core/app_theme.dart';
import '../models/booking_model.dart';
import '../models/kategori_model.dart';
import '../models/lapangan_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/lapangan_service.dart';
import '../services/location_service.dart';
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

  double? _userLatitude;
  double? _userLongitude;
  String? _userAddressLabel;
  bool _isDetectingLocation = false;
  bool _sortByNearest = false;

  bool get _isAdmin => widget.user.role.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _loadCatalogData();
    if (_currentTabIndex == 2) {
      _loadBookingsData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _detectUserLocation() async {
    setState(() {
      _isDetectingLocation = true;
    });

    final result = await LocationService.detectCurrentLocation();

    if (!mounted) return;
    setState(() {
      _isDetectingLocation = false;
    });

    if (result.success && result.latitude != null && result.longitude != null) {
      setState(() {
        _userLatitude = result.latitude;
        _userLongitude = result.longitude;
        _userAddressLabel = result.addressLabel;
        _sortByNearest = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lokasi terdeteksi! Menampilkan lapangan terdekat dari posisi Anda.',
          ),
          backgroundColor: AppColors.courtInk,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.errorInk,
        ),
      );
    }
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
    } catch (e) {
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bookingError = 'Gagal memuat riwayat booking.';
        _isLoadingBookings = false;
      });
    }
  }

  List<LapanganModel> get _filteredLapangan {
    final list = _lapanganList.where((lap) {
      final matchesKategori = _selectedKategori == 'Semua' ||
          lap.jenisOlahraga.toLowerCase() == _selectedKategori.toLowerCase();

      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          lap.namaLapangan.toLowerCase().contains(query) ||
          lap.jenisOlahraga.toLowerCase().contains(query) ||
          lap.deskripsi.toLowerCase().contains(query) ||
          (lap.alamat != null && lap.alamat!.toLowerCase().contains(query));

      return matchesKategori && matchesSearch;
    }).toList();

    if (_sortByNearest && _userLatitude != null && _userLongitude != null) {
      list.sort((a, b) {
        final distA = a.calculateDistanceInMeters(_userLatitude!, _userLongitude!) ??
            double.infinity;
        final distB = b.calculateDistanceInMeters(_userLatitude!, _userLongitude!) ??
            double.infinity;
        return distA.compareTo(distB);
      });
    }

    return list;
  }

  Future<void> _openLapanganDetail(LapanganModel lapangan) async {
    final created = await Navigator.of(context).push<bool>(
      RollUpPageRoute(
        page: LapanganDetailScreen(lapangan: lapangan),
      ),
    );

    if (created == true && mounted) {
      setState(() {
        _currentTabIndex = 1;
      });
      _loadBookingsData();
    }
  }

  void _logout() {
    AuthService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      RollUpPageRoute(page: const WelcomeScreen()),
      (route) => false,
    );
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
                      AdminManagementView(
                        user: widget.user,
                        onDataChanged: () {
                          _loadCatalogData();
                        },
                      ),
                      _buildCatalogTab(),
                      _buildProfileTab(),
                    ]
                  : [
                      _buildCatalogTab(),
                      _buildBookingsTab(),
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
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
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
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.courtInk,
                              ),
                            ),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: _isDetectingLocation ? null : _detectUserLocation,
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      _userLatitude != null
                                          ? Icons.my_location_rounded
                                          : Icons.location_on_rounded,
                                      size: 16,
                                      color: AppColors.courtInk,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        _userAddressLabel ??
                                            'Deteksi Lokasi Saya (Cari Terdekat)',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.courtInk,
                                          decoration: _userLatitude == null
                                              ? TextDecoration.underline
                                              : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (_isDetectingLocation)
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.courtInk,
                                        ),
                                      )
                                    else if (_userLatitude != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.courtInk,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'GPS Aktif',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.turfGreen,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _loadCatalogData,
                        tooltip: 'Muat ulang katalog',
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.courtInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.courtInk,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Cari nama lapangan atau olahraga...',
                              hintStyle: TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textMuted,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty || _selectedKategori != 'Semua')
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _selectedKategori = 'Semua';
                              });
                            },
                            tooltip: 'Reset filter',
                            icon: const Icon(
                              Icons.tune_rounded,
                              size: 19,
                              color: AppColors.courtInk,
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 19,
                              color: AppColors.courtInk,
                            ),
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
                      _CategoryCircleItem(
                        label: 'Semua',
                        icon: Icons.grid_view_rounded,
                        bgColor: const Color(0xFFECFDF5),
                        isSelected: _selectedKategori == 'Semua',
                        onTap: () {
                          setState(() {
                            _selectedKategori = 'Semua';
                          });
                        },
                      ),
                      for (final kat in _kategoriList)
                        _CategoryCircleItem(
                          label: kat.jenisOlahraga,
                          icon: SportCategoryHelper.iconFor(kat.jenisOlahraga),
                          bgColor: SportCategoryHelper.accentBgFor(kat.jenisOlahraga),
                          isSelected: _selectedKategori.toLowerCase() ==
                              kat.jenisOlahraga.toLowerCase(),
                          onTap: () {
                            setState(() {
                              _selectedKategori = kat.jenisOlahraga;
                            });
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                if (_userLatitude == null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fieldMist,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          color: AppColors.courtInk,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cari Lapangan Terdekat',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.courtInk,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Aktifkan GPS untuk menemukan venue terdekat dari posisi Anda.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isDetectingLocation ? null : _detectUserLocation,
                          icon: _isDetectingLocation
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.courtInk,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded, size: 14),
                          label: const Text(
                            'Deteksi',
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
                      ],
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.turfGreenDark.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.turfGreenDark,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lokasi Anda: $_userAddressLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.courtInk,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _sortByNearest,
                          showCheckmark: false,
                          avatar: Icon(
                            Icons.sort_rounded,
                            size: 14,
                            color: _sortByNearest
                                ? AppColors.pureWhite
                                : AppColors.courtInk,
                          ),
                          label: Text(
                            _sortByNearest ? 'Terdekat Aktif' : 'Urutkan Terdekat',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: _sortByNearest
                                  ? AppColors.pureWhite
                                  : AppColors.courtInk,
                            ),
                          ),
                          backgroundColor: AppColors.pureWhite,
                          selectedColor: AppColors.courtInk,
                          onSelected: (val) {
                            setState(() {
                              _sortByNearest = val;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_isLoadingCatalog)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.courtInk,
                      ),
                    ),
                  )
                else if (_catalogError != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.errorInk,
                          size: 32,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _catalogError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.errorInk,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: _loadCatalogData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.courtInk,
                            foregroundColor: AppColors.pureWhite,
                            minimumSize: const Size(120, 44),
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                else if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fieldMist,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.sports_soccer_rounded,
                          size: 36,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tidak ada lapangan yang sesuai dengan filter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.courtInk,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedKategori != 'Semua' || _searchQuery.isNotEmpty)
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedKategori = 'Semua';
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.courtInk,
                              minimumSize: const Size(120, 44),
                            ),
                            child: const Text('Tampilkan Semua'),
                          ),
                      ],
                    ),
                  )
                else
                  ...filtered.map(
                    (lap) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _LapanganCatalogCard(
                        lapangan: lap,
                        userLatitude: _userLatitude,
                        userLongitude: _userLongitude,
                        onTap: () => _openLapanganDetail(lap),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsTab() {
    return MyBookingsView(
      bookings: _bookingList,
      isLoading: _isLoadingBookings,
      errorMessage: _bookingError,
      onRefresh: _loadBookingsData,
      onBrowseCatalog: () {
        setState(() {
          _currentTabIndex = 0;
        });
      },
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
            const Text(
              'Profil Akun',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.courtInk,
              ),
            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.turfGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      widget.user.role.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.courtInk,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.courtInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
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
                label: const Text(
                  'Keluar Akun',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.courtInk,
                  side: const BorderSide(color: AppColors.courtInk, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: _isAdmin
                ? [
                    _BottomNavItem(
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'Admin UMKM',
                      isActive: _currentTabIndex == 0,
                      onTap: () {
                        setState(() {
                          _currentTabIndex = 0;
                        });
                      },
                    ),
                    _BottomNavItem(
                      icon: Icons.home_rounded,
                      label: 'Katalog',
                      isActive: _currentTabIndex == 1,
                      onTap: () {
                        setState(() {
                          _currentTabIndex = 1;
                        });
                      },
                    ),
                    _BottomNavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      isActive: _currentTabIndex == 2,
                      onTap: () {
                        setState(() {
                          _currentTabIndex = 2;
                        });
                      },
                    ),
                  ]
                : [
                    _BottomNavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isActive: _currentTabIndex == 0,
                      onTap: () {
                        setState(() {
                          _currentTabIndex = 0;
                        });
                      },
                    ),
                    _BottomNavItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Booking',
                      isActive: _currentTabIndex == 1,
                      onTap: () {
                        setState(() {
                          _currentTabIndex = 1;
                        });
                        _loadBookingsData();
                      },
                    ),
                    _BottomNavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      isActive: _currentTabIndex == 2,
                      onTap: () {
                        setState(() {
                          _currentTabIndex = 2;
                        });
                      },
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCircleItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCircleItem({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.turfGreen : bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.courtInk : AppColors.borderSubtle,
                  width: isSelected ? 2.2 : 1.0,
                ),
              ),
              child: Icon(
                icon,
                size: 25,
                color: AppColors.courtInk,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: AppColors.courtInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LapanganCatalogCard extends StatelessWidget {
  final LapanganModel lapangan;
  final double? userLatitude;
  final double? userLongitude;
  final VoidCallback onTap;

  const _LapanganCatalogCard({
    required this.lapangan,
    this.userLatitude,
    this.userLongitude,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distanceInMeters = (userLatitude != null && userLongitude != null)
        ? lapangan.calculateDistanceInMeters(userLatitude!, userLongitude!)
        : null;

    return Material(
      color: AppColors.pureWhite,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(17),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 172,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CourtPhotoDisplay(
                        imageUrl: lapangan.fullFotoUrl,
                        jenisOlahraga: lapangan.jenisOlahraga,
                      ),
                      if (distanceInMeters != null)
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.courtInk.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.turfGreen.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.near_me_rounded,
                                  size: 13,
                                  color: AppColors.turfGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${LapanganModel.formatDistance(distanceInMeters)} dari Anda',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.pureWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.courtInk,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${ApiConfig.formatRupiah(lapangan.hargaPerJam)}/jam',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.turfGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lapangan.namaLapangan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.courtInk,
                      ),
                    ),
                    if (lapangan.alamat != null &&
                        lapangan.alamat!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lapangan.alamat!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      lapangan.deskripsi.isNotEmpty
                          ? lapangan.deskripsi
                          : 'Lapangan olahraga standar kompetisi.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: SportCategoryHelper.accentBgFor(
                              lapangan.jenisOlahraga,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            lapangan.jenisOlahraga,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.courtInk,
                            ),
                          ),
                        ),
                        const Text(
                          'Pilih & Booking',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.turfGreenDark,
                          ),
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
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive ? AppColors.turfGreenDark : AppColors.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? AppColors.courtInk : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
