/*
|--------------------------------------------------------------------------
| Local Storage Service
|--------------------------------------------------------------------------
| Tujuan file:
| Menyediakan akses secure storage untuk token authentication dan cache user.
|
| Peran dalam arsitektur:
| AuthProvider -> LocalStorageService -> FlutterSecureStorage.
| Service ini tidak memanggil backend; tugasnya hanya menyimpan, membaca, dan
| menghapus data sesi lokal.
|
| Hubungan dengan Authentication/Profile:
| - Login menyimpan token dan UserModel JSON.
| - AuthWrapper/checkLoginStatus membaca token dan user saat aplikasi dibuka.
| - Update Profile/Privacy menyimpan UserModel terbaru.
| - Logout menghapus token dan user.
|
| Kapan digunakan:
| Dibuat di main() dan diberikan ke ApiClient serta AuthProvider.
|--------------------------------------------------------------------------
*/

// Secure storage platform untuk menyimpan token/user dengan proteksi OS.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/*
|--------------------------------------------------------------------------
| LocalStorageService
|--------------------------------------------------------------------------
| Tujuan class:
| Membungkus FlutterSecureStorage agar key token dan user terpusat.
|
| Data yang dikelola:
| - auth_token: Bearer token backend.
| - auth_user: JSON UserModel yang dipakai untuk restore sesi.
|--------------------------------------------------------------------------
*/
class LocalStorageService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  /*
  | saveToken()
  | Dipanggil AuthProvider.login/loginWithGoogle setelah backend mengirim token.
  | Parameter token disimpan sebagai auth_token. Return Future<void>.
  */
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /*
  | getToken()
  | Dipanggil ApiClient sebelum request dan AuthProvider.checkLoginStatus saat
  | bootstrap. Return token atau null jika belum login.
  */
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /*
  | saveUser()
  | Dipanggil AuthProvider setelah login/update profile/update privacy.
  | Parameter userJson adalah hasil jsonEncode(UserModel.toJson()).
  */
  Future<void> saveUser(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  /*
  | getUser()
  | Dipanggil AuthProvider.checkLoginStatus untuk membangun ulang UserModel.
  | Return JSON string user atau null.
  */
  Future<String?> getUser() async {
    return await _storage.read(key: _userKey);
  }

  /*
  | deleteToken()
  | Dipanggil saat register sukses membersihkan sesi sementara, saat cache
  | rusak, dan saat logout. Menghapus auth_token.
  */
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /*
  | deleteUser()
  | Dipanggil bersama deleteToken untuk memastikan state lokal bersih.
  */
  Future<void> deleteUser() async {
    await _storage.delete(key: _userKey);
  }
}
