import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/user_model.dart';

class AuthResult {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;

  const AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });
}

class AuthService {
  static String? _currentToken;
  static UserModel? _currentUser;

  static String? get token => _currentToken;
  static UserModel? get currentUser => _currentUser;

  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        final token = data['token'].toString();
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        _currentToken = token;
        _currentUser = user;

        return AuthResult(
          success: true,
          message: (body['message'] ?? 'Login berhasil').toString(),
          token: token,
          user: user,
        );
      }

      return AuthResult(
        success: false,
        message: (body['message'] ?? 'Email atau kata sandi salah').toString(),
      );
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Tidak dapat terhubung ke server. Pastikan backend berjalan di port 5000.',
      );
    }
  }

  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 201 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        final token = data['token'].toString();
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        _currentToken = token;
        _currentUser = user;

        return AuthResult(
          success: true,
          message: (body['message'] ?? 'Registrasi akun berhasil').toString(),
          token: token,
          user: user,
        );
      }

      return AuthResult(
        success: false,
        message: (body['message'] ?? 'Gagal mendaftarkan akun').toString(),
      );
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Tidak dapat terhubung ke server. Pastikan backend berjalan di port 5000.',
      );
    }
  }

  static AuthResult? getSavedSession() {
    if (_currentToken == null || _currentUser == null) return null;
    return AuthResult(
      success: true,
      message: 'Sesi aktif',
      token: _currentToken,
      user: _currentUser,
    );
  }

  static void logout() {
    _currentToken = null;
    _currentUser = null;
  }
}
