import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/api_config.dart';
import '../models/booking_model.dart';
import 'auth_service.dart';

class BookingResult {
  final bool success;
  final String message;
  final BookingModel? booking;

  const BookingResult({
    required this.success,
    required this.message,
    this.booking,
  });
}

class BookingService {
  static http.Client client = http.Client();

  static Future<List<BookingModel>> fetchBookings() async {
    final session = AuthService.getSavedSession();
    final token = session?.token ?? '';

    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/bookings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['success'] == true) {
      final list = (body['data'] as List<dynamic>? ?? []);
      return list
          .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['message']?.toString() ?? 'Gagal memuat riwayat booking');
  }

  static Future<BookingResult> createBooking({
    required int lapanganId,
    required String tanggalSewa,
    required String jamMulai,
    required int durasiJam,
    Uint8List? buktiBayarBytes,
    String? buktiBayarFileName,
  }) async {
    try {
      final session = AuthService.getSavedSession();
      final token = session?.token ?? '';

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/bookings');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['lapangan_id'] = lapanganId.toString();
      request.fields['tanggal_sewa'] = tanggalSewa;
      request.fields['jam_mulai'] = jamMulai;
      request.fields['durasi_jam'] = durasiJam.toString();

      if (buktiBayarBytes != null && buktiBayarBytes.isNotEmpty) {
        final safeName = (buktiBayarFileName != null && buktiBayarFileName.isNotEmpty)
            ? buktiBayarFileName
            : 'bukti_bayar.png';
        final lower = safeName.toLowerCase();
        final subType = (lower.endsWith('.jpg') || lower.endsWith('.jpeg'))
            ? 'jpeg'
            : 'png';

        request.files.add(
          http.MultipartFile.fromBytes(
            'bukti_bayar',
            buktiBayarBytes,
            filename: safeName,
            contentType: MediaType('image', subType),
          ),
        );
      }

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        return BookingResult(
          success: true,
          message: body['message']?.toString() ?? 'Booking berhasil dibuat',
          booking: data != null ? BookingModel.fromJson(data) : null,
        );
      }

      return BookingResult(
        success: false,
        message: body['message']?.toString() ?? 'Gagal membuat pesanan lapangan',
      );
    } catch (e) {
      return const BookingResult(
        success: false,
        message: 'Tidak dapat terhubung ke server backend. Pastikan server aktif.',
      );
    }
  }

  static Future<BookingResult> updateBuktiBayar({
    required int bookingId,
    required Uint8List buktiBayarBytes,
    required String buktiBayarFileName,
  }) async {
    try {
      final session = AuthService.getSavedSession();
      final token = session?.token ?? '';

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/bookings/$bookingId');
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final safeName = buktiBayarFileName.isNotEmpty
          ? buktiBayarFileName
          : 'bukti_bayar.png';
      final lower = safeName.toLowerCase();
      final subType = (lower.endsWith('.jpg') || lower.endsWith('.jpeg'))
          ? 'jpeg'
          : 'png';

      request.files.add(
        http.MultipartFile.fromBytes(
          'bukti_bayar',
          buktiBayarBytes,
          filename: safeName,
          contentType: MediaType('image', subType),
        ),
      );

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        return BookingResult(
          success: true,
          message: body['message']?.toString() ?? 'Bukti bayar berhasil diperbarui',
          booking: data != null ? BookingModel.fromJson(data) : null,
        );
      }

      return BookingResult(
        success: false,
        message: body['message']?.toString() ?? 'Gagal memperbarui bukti bayar',
      );
    } catch (e) {
      return const BookingResult(
        success: false,
        message: 'Tidak dapat terhubung ke server backend.',
      );
    }
  }

  static Future<BookingResult> deleteBooking(int bookingId) async {
    try {
      final session = AuthService.getSavedSession();
      final token = session?.token ?? '';

      final response = await client.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/bookings/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return BookingResult(
          success: true,
          message: body['message']?.toString() ?? 'Pesanan berhasil dibatalkan',
        );
      }

      return BookingResult(
        success: false,
        message: body['message']?.toString() ?? 'Gagal membatalkan pesanan',
      );
    } catch (e) {
      return const BookingResult(
        success: false,
        message: 'Tidak dapat terhubung ke server backend.',
      );
    }
  }

  static Future<BookingResult> updateBookingStatus({
    required int bookingId,
    required String statusBooking,
  }) async {
    try {
      final session = AuthService.getSavedSession();
      final token = session?.token ?? '';

      final response = await client.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/bookings/$bookingId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status_booking': statusBooking,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        return BookingResult(
          success: true,
          message: body['message']?.toString() ??
              'Status pesanan berhasil diubah menjadi $statusBooking',
          booking: data != null ? BookingModel.fromJson(data) : null,
        );
      }

      return BookingResult(
        success: false,
        message: body['message']?.toString() ?? 'Gagal mengubah status pesanan',
      );
    } catch (e) {
      return const BookingResult(
        success: false,
        message: 'Tidak dapat terhubung ke server backend.',
      );
    }
  }
}
