import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiConfig {
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        final scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
        return '$scheme://$host:5000';
      }
      return 'http://localhost:5000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.2.8.39:5000';
    }
    return 'http://localhost:5000';
  }

  static String? resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final normalized = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$normalized';
  }

  static String formatRupiah(num value) {
    final str = value.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  static http.MultipartFile buildImageMultipart(
    String fieldName,
    Uint8List bytes,
    String? fileName, {
    String fallbackName = 'upload.png',
  }) {
    final safeName = (fileName != null && fileName.isNotEmpty) ? fileName : fallbackName;
    final lower = safeName.toLowerCase();
    final subType = (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) ? 'jpeg' : 'png';
    return http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: safeName,
      contentType: MediaType('image', subType),
    );
  }
}
