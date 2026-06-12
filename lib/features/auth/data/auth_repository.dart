import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/network/api_client.dart';

// --- 2. AUTH REPOSITORY ---
class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await apiClient.post('/login', {
        'email': email,
        'password': password,
      }, unwrapData: false);

      return _parseAuthResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // PERBAIKAN: Mengembalikan Map (berisi token dan user) agar sama dengan login biasa
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await apiClient.post('/auth/google', {
        'id_token': idToken,
      }, unwrapData: false);

      // Gunakan parser bawaanmu untuk mengekstrak token dan user dengan aman
      return _parseAuthResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String address,
    File? imageFile,
  }) async {
    try {
      final fields = {
        'nama': fullName,
        'no_hp': phoneNumber,
        'alamat': address,
        'remove_image': 'true', // Kirim flag ini ke Laravel
      };

      final response = await apiClient.postMultipart(
        '/profile',
        fields,
        file: null, // Jangan kirim file
        fileField: 'user_image',
        unwrapData: false,
      );

      final userJson = _readMap(response, ['user', 'data.user', 'data']);

      if (userJson == null) {
        throw Exception('Gagal membaca data profil terbaru dari server.');
      }

      return UserModel.fromJson(userJson);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> updatePrivacy({
    required String email,
    String? password,
  }) async {
    try {
      final Map<String, dynamic> body = {'email': email};

      if (password != null && password.trim().isNotEmpty) {
        body['password'] = password;
      }

      final response = await apiClient.post(
        '/privacy',
        body,
        unwrapData: false,
      );

      final userJson = _readMap(response, ['user', 'data.user', 'data']);
      if (userJson == null) throw Exception('Gagal membaca data dari server.');

      return UserModel.fromJson(userJson);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.post('/logout', {}, unwrapData: false);
    } catch (e) {
      debugPrint('Warning: Gagal menghapus token di server: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await apiClient.post('/register', {
        'nama': fullName,
        'email': email,
        'no_hp': phoneNumber,
        'password': password,
        'password_confirmation': password,
      }, unwrapData: false);

      return _parseAuthResponse(
        response,
        fallbackUser: UserModel(
          nama: fullName,
          email: email,
          noHp: phoneNumber,
        ),
        requireToken: false,
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _parseAuthResponse(
    dynamic response, {
    UserModel? fallbackUser,
    bool requireToken = true,
  }) {
    if (response is! Map<String, dynamic>) {
      throw Exception('Format response auth dari Laravel tidak sesuai.');
    }

    final token = _readString(response, ['token', 'access_token']);
    if (requireToken && (token == null || token.isEmpty)) {
      throw Exception('Token auth tidak ditemukan dari response Laravel.');
    }

    final userJson = _readMap(response, ['user', 'data.user', 'data']);
    final user = userJson == null ? fallbackUser : UserModel.fromJson(userJson);

    if (user == null) {
      throw Exception('Data user tidak ditemukan dari response Laravel.');
    }

    return {'token': token ?? '', 'user': user};
  }

  String? _readString(Map<String, dynamic> source, List<String> paths) {
    for (final path in paths) {
      final value = _readPath(source, path);
      if (value != null) return value.toString();
    }
    return null;
  }

  Map<String, dynamic>? _readMap(
    Map<String, dynamic> source,
    List<String> paths,
  ) {
    for (final path in paths) {
      final value = _readPath(source, path);
      if (value is Map<String, dynamic>) return value;
    }
    return null;
  }

  dynamic _readPath(Map<String, dynamic> source, String path) {
    dynamic current = source;

    for (final key in path.split('.')) {
      if (current is! Map<String, dynamic>) return null;
      current = current[key];
    }

    return current;
  }
}
