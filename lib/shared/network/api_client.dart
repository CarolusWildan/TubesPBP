import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/local_storage_service.dart';

/// ApiClient bertindak sebagai gerbang tunggal untuk semua komunikasi keluar.
/// Ini mengisolasi logika HTTP (Headers, Tokens, Error Handling) dari Repositori.
class ApiClient {
  ApiClient({LocalStorageService? storageService})
      : _storageService = storageService;

  // Ganti IP ini dengan IP Localhost Anda jika menggunakan emulator
  // Android Emulator = 10.0.2.2 | iOS Simulator = 127.0.0.1 | Physical Device = IP WiFi Laptop
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  final LocalStorageService? _storageService;

  Future<String?> _getToken() async {
    return _storageService?.getToken();
  }

  Map<String, String> _buildHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept':
          'application/json', // Wajib untuk Laravel agar me-return JSON saat error
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fungsi GET untuk mengambil data (Daftar Hotel, Profil, dsb)
  Future<dynamic> get(String endpoint) async {
    final token = await _getToken();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(token),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  /// Fungsi POST untuk mengirim data (Login, Register, Checkout Booking)
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final token = await _getToken();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(token),
        body: json.encode(body),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Gagal mengirim data ke server: $e');
    }
  }

  /// Fungsi internal untuk menangani standarisasi respon Laravel
  dynamic _processResponse(http.Response response) {
    final decodedJson = response.body.isEmpty
        ? null
        : json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Asumsi Laravel menggunakan wrapper: { "status": "success", "data": [...] }
      // Jika Laravel tidak menggunakan wrapper, langsung return decodedJson;
      if (decodedJson is Map<String, dynamic>) {
        return decodedJson['data'] ?? decodedJson;
      }
      return decodedJson;
    } else {
      // Jika terjadi error (401, 404, 500), ambil pesan error dari Laravel
      final errorMessage = decodedJson is Map<String, dynamic>
          ? decodedJson['message'] ?? 'Terjadi kesalahan tidak diketahui'
          : 'Terjadi kesalahan tidak diketahui';
      throw Exception('Error ${response.statusCode}: $errorMessage');
    }
  }
}
