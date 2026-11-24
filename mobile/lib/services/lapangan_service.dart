import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/kategori_model.dart';
import '../models/lapangan_model.dart';
import 'auth_service.dart';

class ServiceActionResult<T> {
  final bool success;
  final String message;
  final T? data;

  const ServiceActionResult({
    required this.success,
    required this.message,
    this.data,
  });
}

class LapanganService {
  static http.Client client = http.Client();

  static Map<String, String> _authJsonHeaders() {
    final token = AuthService.getSavedSession()?.token ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<KategoriModel>> fetchKategori() async {
    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/kategori'),
      headers: {'Content-Type': 'application/json'},
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['success'] == true) {
      final list = (body['data'] as List<dynamic>? ?? []);
      return list
          .map((item) => KategoriModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      body['message']?.toString() ?? 'Gagal memuat kategori olahraga',
    );
  }

  static Future<ServiceActionResult<KategoriModel>> createKategori({
    required String jenisOlahraga,
    String? keterangan,
  }) =>
      _saveKategori(
        method: 'POST',
        path: '/api/kategori',
        jenisOlahraga: jenisOlahraga,
        keterangan: keterangan,
      );

  static Future<ServiceActionResult<KategoriModel>> updateKategori({
    required int idKategori,
    required String jenisOlahraga,
    String? keterangan,
  }) =>
      _saveKategori(
        method: 'PUT',
        path: '/api/kategori/$idKategori',
        jenisOlahraga: jenisOlahraga,
        keterangan: keterangan,
      );

  static Future<ServiceActionResult<KategoriModel>> _saveKategori({
    required String method,
    required String path,
    required String jenisOlahraga,
    String? keterangan,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      final payload = jsonEncode({
        'jenis_olahraga': jenisOlahraga.trim(),
        'keterangan': keterangan?.trim() ?? '',
      });
      final response = method == 'POST'
          ? await client.post(uri, headers: _authJsonHeaders(), body: payload)
          : await client.put(uri, headers: _authJsonHeaders(), body: payload);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        return ServiceActionResult(
          success: true,
          message: body['message']?.toString() ?? 'Kategori olahraga berhasil disimpan',
          data: data != null ? KategoriModel.fromJson(data) : null,
        );
      }
      return ServiceActionResult(
        success: false,
        message: body['message']?.toString() ?? 'Gagal menyimpan kategori olahraga',
      );
    } catch (_) {
      return const ServiceActionResult(
        success: false,
        message: 'Tidak dapat terhubung ke server backend.',
      );
    }
  }

  static Future<ServiceActionResult<void>> deleteKategori(int idKategori) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/kategori/$idKategori'),
        headers: _authJsonHeaders(),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return ServiceActionResult(
          success: true,
          message: body['message']?.toString() ?? 'Kategori olahraga berhasil dihapus',
        );
      }
      return ServiceActionResult(
        success: false,
        message: body['message']?.toString() ?? 'Gagal menghapus kategori olahraga',
      );
    } catch (_) {
      return const ServiceActionResult(
        success: false,
        message: 'Tidak dapat terhubung ke server backend.',
      );
    }
  }

  static Future<List<LapanganModel>> fetchLapangan() async {
    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/lapangan'),
      headers: {'Content-Type': 'application/json'},
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['success'] == true) {
      final list = (body['data'] as List<dynamic>? ?? []);
      return list
          .map((item) => LapanganModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      body['message']?.toString() ?? 'Gagal memuat daftar lapangan',
    );
  }

  static Future<ServiceActionResult<LapanganModel>> createLapangan({
    required String namaLapangan,
    required String jenisOlahraga,
    required double hargaPerJam,
    required String deskripsi,
    int? idKategori,
    Uint8List? fotoBytes,
    String? fotoFileName,
  }) =>
      _saveLapangan(
        method: 'POST',
        path: '/api/lapangan',
        namaLapangan: namaLapangan,
        jenisOlahraga: jenisOlahraga,
        hargaPerJam: hargaPerJam,
        deskripsi: deskripsi,
        idKategori: idKategori,
        fotoBytes: fotoBytes,
        fotoFileName: fotoFileName,
      );

  static Future<ServiceActionResult<LapanganModel>> updateLapangan({
    required int id,
    required String namaLapangan,
    required String jenisOlahraga,
    required double hargaPerJam,
    required String deskripsi,
    int? idKategori,
    Uint8List? fotoBytes,
    String? fotoFileName,
  }) =>
      _saveLapangan(
        method: 'PUT',
        path: '/api/lapangan/$id',
        namaLapangan: namaLapangan,
        jenisOlahraga: jenisOlahraga,
        hargaPerJam: hargaPerJam,
        deskripsi: deskripsi,
        idKategori: idKategori,
        fotoBytes: fotoBytes,
        fotoFileName: fotoFileName,
      );

  static Future<ServiceActionResult<LapanganModel>> _saveLapangan({
    required String method,
    required String path,
    required String namaLapangan,
    required String jenisOlahraga,
    required double hargaPerJam,
    required String deskripsi,
    int? idKategori,
    Uint8List? fotoBytes,
    String? fotoFileName,
  }) async {
    try {
      final token = AuthService.getSavedSession()?.token ?? '';
      final request = http.MultipartRequest(
        method,
        Uri.parse('${ApiConfig.baseUrl}$path'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['nama_lapangan'] = namaLapangan.trim();
      request.fields['jenis_olahraga'] = jenisOlahraga.trim();
      request.fields['harga_per_jam'] = hargaPerJam.round().toString();
      request.fields['deskripsi'] = deskripsi.trim();
      if (idKategori != null) {
        request.fields['id_kategori'] = idKategori.toString();
      }

      if (fotoBytes != null && fotoBytes.isNotEmpty) {
        request.files.add(
          ApiConfig.buildImageMultipart(
            'foto_lapangan',
            fotoBytes,
            fotoFileName,
            fallbackName: 'foto_lapangan.png',
          ),
        );
      }

      final response = await http.Response.fromStream(await client.send(request));
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        return ServiceActionResult(
          success: true,
          message: body['message']?.toString() ?? 'Data lapangan berhasil disimpan',
          data: data != null ? LapanganModel.fromJson(data) : null,
        );
      }
      return ServiceActionResult(
        success: false,
        message: body['message']?.toString() ?? 'Gagal menyimpan data lapangan',
      );
    } catch (_) {
      return const ServiceActionResult(
        success: false,
        message: 'Tidak dapat terhubung ke server backend.',
      );
    }
  }

  static Future<ServiceActionResult<void>> deleteLapangan(int id) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/lapangan/$id'),
        headers: _authJsonHeaders(),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return ServiceActionResult(
          success: true,
          message: body['message']?.toString() ?? 'Data lapangan berhasil dihapus',
        );
      }
      return ServiceActionResult(
        success: false,
        message: body['message']?.toString() ?? 'Gagal menghapus data lapangan',
      );
    } catch (_) {
      return const ServiceActionResult(
        success: false,
        message: 'Tidak dapat terhubung ke server backend.',
      );
    }
  }
}
