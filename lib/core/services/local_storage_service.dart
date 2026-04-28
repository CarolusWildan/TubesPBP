import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- 1. LOCAL STORAGE SERVICE ---
// Idealnya diletakkan di: lib/core/services/local_storage_service.dart
class LocalStorageService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}



