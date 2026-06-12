import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/local_storage_service.dart';

class ApiClient {
  ApiClient({LocalStorageService? storageService})
    : _storageService = storageService;

  // 1. GANTI DENGAN URL NGROK KAMU (Tanpa garis miring di akhir)
  //static const String baseUrl = '<LINK NGROK>/api';
  static const String baseUrl =
      'https://mortality-emote-creasing.ngrok-free.dev/api';
  static String get serverUrl => baseUrl.replaceFirst('/api', '');
  static const Map<String, String> imageHeaders = {
    'ngrok-skip-browser-warning': 'true',
  };

  final LocalStorageService? _storageService;

  Future<String?> _getToken() async {
    return _storageService?.getToken();
  }

  Map<String, String> _buildHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning':
          'true', // 2. WAJIB UNTUK BYPASS HALAMAN NGROK
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint, {bool unwrapData = true}) async {
    final token = await _getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(token),
      );
      return _processResponse(response, unwrapData: unwrapData);
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool unwrapData = true,
  }) async {
    final token = await _getToken();

    http.Response response;

    // 1. Blok ini HANYA untuk menangkap gagal koneksi (Internet mati, Server down)
    try {
      response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(token),
        body: json.encode(body),
      );
    } catch (e) {
      throw Exception(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    }

    // 2. Blok ini untuk membaca jawaban Laravel (termasuk error validasi)
    return _processResponse(response, unwrapData: unwrapData);
  }

  // 3. PERBAIKAN LOGIKA PARSING RESPONSE
  dynamic _processResponse(http.Response response, {required bool unwrapData}) {
    if (response.body.isEmpty) return null;

    // A. Validasi Tipe Konten: Pastikan server benar-benar merespon dengan JSON
    final contentType = response.headers['content-type'] ?? '';
    final isJson = contentType.contains('application/json');

    if (!isJson) {
      // Jika bukan JSON (misal Ngrok Error HTML atau Laravel Fatal Error HTML)
      throw Exception(
        'Server merespons dengan format yang tidak valid (bukan JSON). Status Code: ${response.statusCode}',
      );
    }

    // B. Aman untuk di-decode karena kita yakin formatnya JSON
    final decodedJson = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (unwrapData && decodedJson is Map<String, dynamic>) {
        return decodedJson['data'] ?? decodedJson;
      }
      return decodedJson;
    } else {
      // Penanganan Error dari Backend (400, 401, 422, dsb)
      final errorMessage = decodedJson is Map<String, dynamic>
          ? decodedJson['message'] ?? 'Terjadi kesalahan tidak diketahui'
          : 'Terjadi kesalahan tidak diketahui';
      throw Exception(errorMessage);
    }
  }
}
