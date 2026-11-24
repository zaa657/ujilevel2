import 'package:flutter/material.dart';
import '../core/api_config.dart';
import '../core/app_theme.dart';
import '../models/lapangan_model.dart';

class SportCategoryHelper {
  static IconData iconFor(String jenisOlahraga) {
    final lower = jenisOlahraga.toLowerCase();
    if (lower.contains('futsal') || lower.contains('sepak') || lower.contains('football')) {
      return Icons.sports_soccer_rounded;
    }
    if (lower.contains('badminton') || lower.contains('bulu') || lower.contains('tenis')) {
      return Icons.sports_tennis_rounded;
    }
    if (lower.contains('basket')) return Icons.sports_basketball_rounded;
    if (lower.contains('voli') || lower.contains('volley')) return Icons.sports_volleyball_rounded;
    return Icons.stadium_rounded;
  }

  static Color accentBgFor(String jenisOlahraga) {
    final lower = jenisOlahraga.toLowerCase();
    if (lower.contains('basket')) return const Color(0xFFFFEDD5);
    if (lower.contains('badminton') || lower.contains('bulu')) return const Color(0xFFDCFCE7);
    if (lower.contains('tenis')) return const Color(0xFFE0F2FE);
    return const Color(0xFFECFDF5);
  }
}

class CourtPhotoDisplay extends StatelessWidget {
  final String? imageUrl;
  final String jenisOlahraga;

  const CourtPhotoDisplay({
    super.key,
    required this.imageUrl,
    required this.jenisOlahraga,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _CourtFallbackBanner(jenisOlahraga: jenisOlahraga),
      );
    }
    return _CourtFallbackBanner(jenisOlahraga: jenisOlahraga);
  }
}

class _CourtFallbackBanner extends StatelessWidget {
  final String jenisOlahraga;
  const _CourtFallbackBanner({required this.jenisOlahraga});

  @override
  Widget build(BuildContext context) {
    final lower = jenisOlahraga.toLowerCase();
    final surfaceColor = (lower.contains('badminton') || lower.contains('bulu'))
        ? const Color(0xFF0F766E)
        : lower.contains('basket')
            ? const Color(0xFF1E3A8A)
            : (lower.contains('tenis') || lower.contains('tennis'))
                ? const Color(0xFF0369A1)
                : const Color(0xFF15803D);

    return CustomPaint(
      painter: _CourtMarkingsPainter(surfaceColor: surfaceColor),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 110) {
            return Center(
              child: Icon(SportCategoryHelper.iconFor(jenisOlahraga), color: AppColors.pureWhite, size: 22),
            );
          }
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.courtInk.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(SportCategoryHelper.iconFor(jenisOlahraga), color: AppColors.turfGreen, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      jenisOlahraga,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.pureWhite),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CourtMarkingsPainter extends CustomPainter {
  final Color surfaceColor;
  const _CourtMarkingsPainter({required this.surfaceColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = surfaceColor);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRect(Rect.fromLTRB(w * 0.08, h * 0.12, w * 0.92, h * 0.88), linePaint);
    canvas.drawLine(Offset(w * 0.5, h * 0.12), Offset(w * 0.5, h * 0.88), linePaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), h * 0.18, linePaint);
    canvas.drawRect(Rect.fromLTRB(w * 0.08, h * 0.30, w * 0.22, h * 0.70), linePaint);
    canvas.drawRect(Rect.fromLTRB(w * 0.78, h * 0.30, w * 0.92, h * 0.70), linePaint);
  }

  @override
  bool shouldRepaint(covariant _CourtMarkingsPainter oldDelegate) =>
      oldDelegate.surfaceColor != surfaceColor;
}

class QuickSelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const QuickSelectChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.turfGreen : AppColors.fieldMist,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.courtInk : AppColors.borderSubtle,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.courtInk,
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryCircleItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCircleItem({
    super.key,
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
              child: Icon(icon, size: 25, color: AppColors.courtInk),
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

class LapanganCatalogCard extends StatelessWidget {
  final LapanganModel lapangan;
  final double? userLatitude;
  final double? userLongitude;
  final VoidCallback onTap;

  const LapanganCatalogCard({
    super.key,
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.courtInk.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.turfGreen.withValues(alpha: 0.6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.near_me_rounded, size: 13, color: AppColors.turfGreen),
                                const SizedBox(width: 4),
                                Text(
                                  '${LapanganModel.formatDistance(distanceInMeters)} dari Anda',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.pureWhite),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.courtInk, borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            '${ApiConfig.formatRupiah(lapangan.hargaPerJam)}/jam',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.turfGreen),
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
                    Text(
                      lapangan.namaLapangan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.courtInk),
                    ),
                    if (lapangan.alamat != null && lapangan.alamat!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lapangan.alamat!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      lapangan.deskripsi.isNotEmpty ? lapangan.deskripsi : 'Lapangan olahraga standar kompetisi.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: SportCategoryHelper.accentBgFor(lapangan.jenisOlahraga),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            lapangan.jenisOlahraga,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.courtInk),
                          ),
                        ),
                        const Text(
                          'Pilih & Booking',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.turfGreenDark),
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

class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const BottomNavItem({
    super.key,
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
              Icon(icon, size: 22, color: isActive ? AppColors.turfGreenDark : AppColors.textMuted),
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
