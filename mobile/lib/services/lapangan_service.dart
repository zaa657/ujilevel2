import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
    final session = AuthService.getSavedSession();
    final token = session?.token ?? '';
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
  }) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/kategori'),
        headers: _authJsonHeaders(),
        body: jsonEncode({
          'jenis_olahraga': jenisOlahraga.trim(),
          'keterangan': keterangan?.trim() ?? '',
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        return ServiceActionResult(
          success: true,
          message:
              body['message']?.toString() ?? 'Kategori olahraga berhasil ditambahkan',
          data: data != null ? KategoriModel.fromJson(data) : null,
        );
      }
      return ServiceActionResult(
        success: false,
        message:
            body['message']?.toString() ?? 'Gagal menambahkan kategori olahraga',
      );
    } catch (_) {
      return const ServiceActionResult(
        success: false,
        message: 'Tidak dapat terhubung ke server backend.',
      );
    }
  }

  static Future<ServiceActionResult<KategoriModel>> updateKategori({
    required int idKategori,
    required String jenisOlahraga,
    String? keterangan,
  }) async {
    try {
      final response = await client.put(
        Uri.parse('${ApiConfig.baseUrl}/api/kategori/$idKategori'),
        headers: _authJsonHeaders(),
        body: jsonEncode({
          'jenis_olahraga': jenisOlahraga.trim(),
          'keterangan': keterangan?.trim() ?? '',
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        return ServiceActionResult(
          success: true,
          message:
              body['message']?.toString() ?? 'Kategori olahraga berhasil diperbarui',
          data: data != null ? KategoriModel.fromJson(data) : null,
        );
      }
      return ServiceActionResult(
        success: false,
        message:
            body['message']?.toString() ?? 'Gagal memperbarui kategori olahraga',
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
          message:
              body['message']?.toString() ?? 'Kategori olahraga berhasil dihapus',
        );
      }
      return ServiceActionResult(
        success: false,
        message:
            body['message']?.toString() ?? 'Gagal menghapus kategori olahraga',
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

  static Future<LapanganModel> fetchLapanganById(int id) async {
    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/lapangan/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['success'] == true) {
      return LapanganModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(
      body['message']?.toString() ?? 'Gagal memuat detail lapangan',
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
  }) async {
    try {
      final session = AuthService.getSavedSession();
      final token = session?.token ?? '';

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/lapangan');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['nama_lapangan'] = namaLapangan.trim();
      request.fields['jenis_olahraga'] = jenisOlahraga.trim();
      request.fields['harga_per_jam'] = hargaPerJam.round().toString();
      request.fields['deskripsi'] = deskripsi.trim();
      if (idKategori != null) {
        request.fields['id_kategori'] = idKategori.toString();
      }

      if (fotoBytes != null && fotoBytes.isNotEmpty) {
        final safeName = (fotoFileName != null && fotoFileName.isNotEmpty)
            ? fotoFileName
            : 'foto_lapangan.png';
        final lower = safeName.toLowerCase();
        final subType = (lower.endsWith('.jpg') || lower.endsWith('.jpeg'))
            ? 'jpeg'
            : 'png';

        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_lapangan',
            fotoBytes,
            filename: safeName,
            contentType: MediaType('image', subType),
          ),
        );
      }

      final streamed = await client.send(request);
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        return ServiceActionResult(
          success: true,
          message:
              body['message']?.toString() ?? 'Data lapangan berhasil ditambahkan',
          data: data != null ? LapanganModel.fromJson(data) : null,
        );
      }
      return ServiceActionResult(
        success: false,
        message:
            body['message']?.toString() ?? 'Gagal menambahkan data lapangan',
      );
    } catch (_) {
      return const ServiceActionResult(
        success: false,
        message: 'Tidak dapat terhubung ke server backend.',
      );
    }
  }

  static Future<ServiceActionResult<LapanganModel>> updateLapangan({
    required int id,
    required String namaLapangan,
    required String jenisOlahraga,
    required double hargaPerJam,
    required String deskripsi,
    int? idKategori,
    Uint8List? fotoBytes,
    String? fotoFileName,
  }) async {
    try {
      final session = AuthService.getSavedSession();
      final token = session?.token ?? '';

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/lapangan/$id');
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['nama_lapangan'] = namaLapangan.trim();
      request.fields['jenis_olahraga'] = jenisOlahraga.trim();
      request.fields['harga_per_jam'] = hargaPerJam.round().toString();
      request.fields['deskripsi'] = deskripsi.trim();
      if (idKategori != null) {
        request.fields['id_kategori'] = idKategori.toString();
      }

      if (fotoBytes != null && fotoBytes.isNotEmpty) {
        final safeName = (fotoFileName != null && fotoFileName.isNotEmpty)
            ? fotoFileName
            : 'foto_lapangan.png';
        final lower = safeName.toLowerCase();
        final subType = (lower.endsWith('.jpg') || lower.endsWith('.jpeg'))
            ? 'jpeg'
            : 'png';

        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_lapangan',
            fotoBytes,
            filename: safeName,
            contentType: MediaType('image', subType),
          ),
        );
      }

      final streamed = await client.send(request);
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        return ServiceActionResult(
          success: true,
          message:
              body['message']?.toString() ?? 'Data lapangan berhasil diperbarui',
          data: data != null ? LapanganModel.fromJson(data) : null,
        );
      }
      return ServiceActionResult(
        success: false,
        message:
            body['message']?.toString() ?? 'Gagal memperbarui data lapangan',
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
