import 'dart:convert';
import 'dart:io'; // 🟢 WAJIB DITAMBAHKAN UNTUK MENGENALI DATA 'File'
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../core/services/local_storage_service.dart';

class ApiClient {
  ApiClient({LocalStorageService? storageService})
    : _storageService = storageService;

  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL']?.trim();
    if (url == null || url.isEmpty) {
      throw Exception('API_BASE_URL belum diatur di file .env');
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
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
      'ngrok-skip-browser-warning': 'true', 
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

  // --- 🟢 FUNGSI BARU UNTUK UPLOAD GAMBAR (MULTIPART) 🟢 ---
  Future<dynamic> postMultipart(
    String endpoint,
    Map<String, String> fields, {
    File? file,
    String fileField = 'user_image',
    bool unwrapData = true,
  }) async {
    final token = await _getToken();
    
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      
      // Header untuk autentikasi (Tanpa Content-Type karena diatur otomatis oleh MultipartRequest)
      request.headers.addAll({
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      // 1. Masukkan data teks (Nama, No HP, Alamat)
      request.fields.addAll(fields);

      // 2. Masukkan data file (Gambar Profil) jika ada
      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(fileField, file.path)
        );
      }

      // 3. Kirim ke Laravel
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // 4. Proses balasan menggunakan logika yang sama
      return _processResponse(response, unwrapData: unwrapData);
      
    } catch (e) {
      throw Exception('Gagal mengirim data. Periksa koneksi internet Anda.');
    }
  }

  Future<dynamic> postMultipartMultiple(
    String endpoint,
    Map<String, String> fields, {
    List<File>? files,
    String fileField = 'media[]', // Array naming convention di Laravel
    bool unwrapData = true,
  }) async {
    final token = await _getToken();
    
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      
      request.headers.addAll({
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.fields.addAll(fields);

      // Looping untuk memasukkan banyak file
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          request.files.add(
            await http.MultipartFile.fromPath(fileField, file.path)
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response, unwrapData: unwrapData);
    } catch (e) {
      throw Exception('Gagal mengupload review: $e');
    }
  }

  // ---------------------------------------------------------

  // 3. PERBAIKAN LOGIKA PARSING RESPONSE
  dynamic _processResponse(http.Response response, {required bool unwrapData}) {
    if (response.body.isEmpty) return null;

    // A. Validasi Tipe Konten: Pastikan server benar-benar merespon dengan JSON
    final contentType = response.headers['content-type'] ?? '';
    final isJson = contentType.contains('application/json');

    if (!isJson) {
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
