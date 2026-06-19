/*
|--------------------------------------------------------------------------
| Api Client
|--------------------------------------------------------------------------
| Tujuan file:
| Menjadi satu pintu HTTP client untuk komunikasi Flutter dengan backend API.
|
| Peran dalam arsitektur:
| Provider/Repository -> ApiClient -> Backend API.
| ApiClient menambahkan base URL, header JSON, Bearer token, multipart upload,
| dan parsing response/error backend.
|
| Hubungan dengan Authentication/Profile:
| AuthRepository memakai client ini untuk /login, /register, /privacy,
| /logout, dan multipart /profile. Profile UI juga memakai serverUrl untuk
| memuat foto user dari storage backend.
|
| Kapan digunakan:
| Dibuat di main() dan disuntikkan ke repository/provider yang perlu request
| backend.
|--------------------------------------------------------------------------
*/

// JSON encoder/decoder untuk body request dan response backend.
import 'dart:convert';

// Tipe File dipakai untuk upload multipart foto profil/review.
import 'dart:io';

// Membaca API_BASE_URL dari file .env.
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Package HTTP untuk request REST dan multipart.
import 'package:http/http.dart' as http;

// Secure storage token yang dipakai untuk Authorization header.
import '../../core/services/local_storage_service.dart';

/*
|--------------------------------------------------------------------------
| ApiClient
|--------------------------------------------------------------------------
| Tujuan class:
| Membungkus package http agar semua request memakai format header, base URL,
| token, dan parsing error yang sama.
|
| Data yang dikelola:
| Tidak menyimpan response. Hanya menyimpan referensi LocalStorageService untuk
| membaca token sebelum request.
|--------------------------------------------------------------------------
*/
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

  /*
  | _getToken()
  | Dipanggil sebelum request GET/POST/multipart. Return token dari secure
  | storage atau null untuk endpoint publik seperti login/register.
  */
  Future<String?> _getToken() async {
    return _storageService?.getToken();
  }

  /*
  | _buildHeaders()
  | Dipanggil oleh get() dan post(). Parameter token menjadi Bearer token jika
  | tersedia. Return header JSON yang diterima backend Laravel.
  */
  Map<String, String> _buildHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /*
  |--------------------------------------------------------------------------
  | get()
  |--------------------------------------------------------------------------
  | Dipanggil repository/provider untuk request baca data.
  |
  | Parameter:
  | - endpoint: path API.
  | - unwrapData: true untuk mengambil field data, false untuk response penuh.
  |
  | Return:
  | JSON decoded hasil _processResponse().
  |--------------------------------------------------------------------------
  */
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

  /*
  |--------------------------------------------------------------------------
  | post()
  |--------------------------------------------------------------------------
  | Dipanggil AuthRepository untuk login/register/privacy/logout dan repository
  | lain untuk operasi tulis.
  |
  | Parameter:
  | - endpoint: path API.
  | - body: payload JSON.
  | - unwrapData: kontrol pembacaan field data.
  |
  | Return:
  | JSON decoded atau error Exception dari backend.
  |--------------------------------------------------------------------------
  */
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool unwrapData = true,
  }) async {
    final token = await _getToken();

    http.Response response;

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

    return _processResponse(response, unwrapData: unwrapData);
  }

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool unwrapData = true,
  }) async {
    final token = await _getToken();

    http.Response response;
    try {
      response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(token),
        body: json.encode(body),
      );
    } catch (e) {
      throw Exception(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    }

    return _processResponse(response, unwrapData: unwrapData);
  }

  Future<dynamic> delete(String endpoint, {bool unwrapData = true}) async {
    final token = await _getToken();

    http.Response response;
    try {
      response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _buildHeaders(token),
      );
    } catch (e) {
      throw Exception(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    }

    return _processResponse(response, unwrapData: unwrapData);
  }

  /*
  |--------------------------------------------------------------------------
  | postMultipart()
  |--------------------------------------------------------------------------
  | Dipanggil AuthRepository.updateProfile() untuk upload foto profil beserta
  | field teks profile.
  |
  | Parameter:
  | - endpoint: path API tujuan.
  | - fields: form fields teks.
  | - file: file opsional yang akan di-upload.
  | - fileField: nama field file backend, default user_image.
  | - unwrapData: kontrol parsing response.
  |
  | Return:
  | JSON decoded hasil _processResponse().
  |--------------------------------------------------------------------------
  */
  Future<dynamic> postMultipart(
    String endpoint,
    Map<String, String> fields, {
    File? file,
    String fileField = 'user_image',
    bool unwrapData = true,
  }) async {
    final token = await _getToken();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );

      // Header untuk autentikasi (tanpa Content-Type karena diatur otomatis).
      request.headers.addAll({
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.fields.addAll(fields);

      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(fileField, file.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response, unwrapData: unwrapData);
    } catch (e) {
      throw Exception('Gagal mengirim data. Periksa koneksi internet Anda.');
    }
  }

  /*
  |--------------------------------------------------------------------------
  | postMultipartMultiple()
  |--------------------------------------------------------------------------
  | Dipakai fitur lain yang mengunggah lebih dari satu file. Tetap memakai
  | token/header yang sama dengan profile.
  |
  | Return:
  | JSON decoded dari backend.
  |--------------------------------------------------------------------------
  */
  Future<dynamic> postMultipartMultiple(
    String endpoint,
    Map<String, String> fields, {
    List<File>? files,
    String fileField = 'media[]',
    bool unwrapData = true,
  }) async {
    final token = await _getToken();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.fields.addAll(fields);

      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          request.files.add(
            await http.MultipartFile.fromPath(fileField, file.path),
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

  Future<dynamic> putMultipartMultiple(
    String endpoint,
    Map<String, String> fields, {
    List<File>? files,
    String fileField = 'media[]',
    bool unwrapData = true,
  }) async {
    final token = await _getToken();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.fields.addAll({...fields, '_method': 'PUT'});

      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          request.files.add(
            await http.MultipartFile.fromPath(fileField, file.path),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response, unwrapData: unwrapData);
    } catch (e) {
      throw Exception('Gagal mengupdate review: $e');
    }
  }

  /*
  |--------------------------------------------------------------------------
  | _processResponse()
  |--------------------------------------------------------------------------
  | Dipanggil oleh semua method request setelah http.Response diterima.
  |
  | Parameter:
  | - response: response HTTP mentah.
  | - unwrapData: true untuk mengembalikan decodedJson['data'] bila ada.
  |
  | Return:
  | JSON decoded untuk status 2xx.
  |
  | Efek state:
  | Tidak ada. Method ini hanya normalisasi response dan melempar Exception
  | berisi message backend untuk status error.
  |--------------------------------------------------------------------------
  */
  dynamic _processResponse(http.Response response, {required bool unwrapData}) {
    if (response.body.isEmpty) return null;

    final contentType = response.headers['content-type'] ?? '';
    final isJson = contentType.contains('application/json');

    if (!isJson) {
      throw Exception(
        'Server merespons dengan format yang tidak valid (bukan JSON). Status Code: ${response.statusCode}',
      );
    }

    final decodedJson = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (unwrapData && decodedJson is Map<String, dynamic>) {
        return decodedJson['data'] ?? decodedJson;
      }
      return decodedJson;
    } else {
      final errorMessage = decodedJson is Map<String, dynamic>
          ? decodedJson['message'] ?? 'Terjadi kesalahan tidak diketahui'
          : 'Terjadi kesalahan tidak diketahui';
      throw Exception(errorMessage);
    }
  }
}
