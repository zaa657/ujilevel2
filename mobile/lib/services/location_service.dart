import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class UserLocationResult {
  final bool success;
  final double? latitude;
  final double? longitude;
  final String message;
  final String? addressLabel;

  const UserLocationResult({
    required this.success,
    this.latitude,
    this.longitude,
    required this.message,
    this.addressLabel,
  });

  factory UserLocationResult.ok({
    required double latitude,
    required double longitude,
    String? addressLabel,
  }) {
    return UserLocationResult(
      success: true,
      latitude: latitude,
      longitude: longitude,
      message: 'Lokasi Anda berhasil dideteksi',
      addressLabel: addressLabel ??
          'Koordinat: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
    );
  }

  factory UserLocationResult.fail(String message) {
    return UserLocationResult(
      success: false,
      message: message,
    );
  }
}

class LocationService {
  static Future<UserLocationResult> detectCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return UserLocationResult.fail(
          'Layanan GPS / Lokasi perangkat belum diaktifkan. Silakan aktifkan GPS HP Anda.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return UserLocationResult.fail(
            'Izin akses lokasi ditolak oleh pengguna.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return UserLocationResult.fail(
          'Izin akses lokasi ditolak permanen. Silakan izinkan di Pengaturan aplikasi.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      String label = 'Koordinat: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      if (lat >= -6.40 && lat <= -6.08 && lng >= 106.65 && lng <= 107.00) {
        label = 'Sekitar Jabodetabek (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})';
      }

      return UserLocationResult.ok(
        latitude: lat,
        longitude: lng,
        addressLabel: label,
      );
    } catch (e) {
      debugPrint('Error detecting location: $e');
      return UserLocationResult.fail(
        'Gagal mendeteksi lokasi: ${e.toString().replaceAll('Exception:', '').trim()}',
      );
    }
  }
}
