/*
|--------------------------------------------------------------------------
| Auth Repository
|--------------------------------------------------------------------------
| Tujuan file:
| Menjadi layer data untuk seluruh fitur Authentication dan bagian Profile
| yang membutuhkan komunikasi ke backend Laravel.
|
| Peran dalam arsitektur:
| UI Layer -> AuthProvider -> AuthRepository -> ApiClient -> Backend API.
| File ini tidak menyimpan state UI. Tugasnya adalah membentuk payload,
| memanggil endpoint, membaca response, lalu mengubah data JSON menjadi
| struktur yang bisa dipakai provider.
|
| Hubungan dengan fitur:
| - Login dan Google Login mengambil token serta data user.
| - Register mengirim data akun baru.
| - Profile dan Personal Information memperbarui nama, nomor HP, alamat,
|   serta foto profil.
| - Privacy Policy memperbarui email dan password.
| - Logout memberi tahu backend bahwa sesi/token ingin diakhiri.
|
| Kapan digunakan:
| Dipanggil oleh AuthProvider ketika user menekan tombol login, register,
| save profile, save privacy, atau logout pada halaman terkait.
|--------------------------------------------------------------------------
*/

// Digunakan untuk debugPrint saat logout backend gagal tetapi cleanup lokal tetap dilanjutkan.
import 'package:flutter/foundation.dart';

// Digunakan untuk tipe File ketika Personal Information mengunggah foto profil.
import 'dart:io';

// Model domain user yang dibentuk dari response backend authentication/profile.
import '../../../../shared/models/user_model.dart';

// Client HTTP bersama yang menambahkan base URL, header, token, dan parsing response.
import '../../../../shared/network/api_client.dart';

/*
|--------------------------------------------------------------------------
| AuthRepository
|--------------------------------------------------------------------------
| Tujuan class:
| Mengisolasi detail endpoint Authentication dan Profile dari UI/provider.
|
| Tanggung jawab:
| - Menentukan endpoint yang dipanggil.
| - Menyusun body request sesuai kontrak backend Laravel.
| - Mengubah response JSON menjadi UserModel atau Map auth berisi token+user.
|
| Hubungan dengan class lain:
| - Dipakai oleh AuthProvider sebagai sumber data remote.
| - Bergantung pada ApiClient untuk HTTP request.
| - Menghasilkan UserModel untuk disimpan AuthProvider dan LocalStorageService.
|
| Data yang dikelola:
| Tidak menyimpan data permanen. Semua data hanya lewat sebagai parameter,
| response, atau return value.
|--------------------------------------------------------------------------
*/
class AuthRepository {
  final ApiClient apiClient;

  /*
  |--------------------------------------------------------------------------
  | AuthRepository()
  |--------------------------------------------------------------------------
  | Dipanggil saat dependency graph dibuat di main().
  |
  | Parameter:
  | - apiClient: client HTTP yang sudah terhubung dengan LocalStorageService.
  |
  | Return:
  | Instance AuthRepository siap dipakai AuthProvider.
  |
  | Efek state:
  | Tidak mengubah state aplikasi.
  |--------------------------------------------------------------------------
  */
  AuthRepository({required this.apiClient});

  /*
  |--------------------------------------------------------------------------
  | login()
  |--------------------------------------------------------------------------
  | Dipanggil oleh AuthProvider.login() setelah UI Login mengirim email dan
  | password dari form.
  |
  | Parameter:
  | - email: alamat email user.
  | - password: password user.
  |
  | Request API:
  | POST /login dengan body { email, password }.
  |
  | Return:
  | Map berisi token dan UserModel hasil _parseAuthResponse().
  |
  | Efek state:
  | Tidak menyimpan token. Penyimpanan dilakukan AuthProvider agar perubahan
  | state autentikasi tetap terpusat.
  |--------------------------------------------------------------------------
  */
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

  /*
  |--------------------------------------------------------------------------
  | loginWithGoogle()
  |--------------------------------------------------------------------------
  | Dipanggil oleh AuthProvider.loginWithGoogle() setelah Google Sign-In
  | menghasilkan idToken.
  |
  | Parameter:
  | - idToken: token identitas Google yang akan diverifikasi backend.
  |
  | Request API:
  | POST /auth/google dengan body { id_token }.
  |
  | Return:
  | Map berisi token aplikasi dan UserModel.
  |
  | Efek state:
  | Tidak mengubah state langsung. AuthProvider yang menyimpan token/user dan
  | memberi notifikasi UI.
  |--------------------------------------------------------------------------
  */
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await apiClient.post('/auth/google', {
        'id_token': idToken,
      }, unwrapData: false);

      return _parseAuthResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | updateProfile()
  |--------------------------------------------------------------------------
  | Dipanggil oleh AuthProvider.updateProfile() dari PersonalInfoScreen saat
  | tombol Save ditekan.
  |
  | Parameter:
  | - fullName: nama user untuk field backend "nama".
  | - phoneNumber: nomor HP untuk field backend "no_hp".
  | - address: alamat untuk field backend "alamat".
  | - imageFile: file foto baru, opsional.
  | - removeImage: penanda bahwa foto lama ingin dihapus.
  |
  | Request API:
  | POST multipart /profile dengan fields teks dan file user_image jika ada.
  |
  | Return:
  | UserModel terbaru dari response backend.
  |
  | Efek state:
  | Tidak mengubah state langsung. AuthProvider mengganti user aktif dan cache
  | lokal setelah method ini berhasil.
  |--------------------------------------------------------------------------
  */
  Future<UserModel> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String address,
    File? imageFile,
    bool removeImage = false,
  }) async {
    try {
      final fields = <String, String>{
        'nama': fullName,
        'no_hp': phoneNumber,
        'alamat': address,
      };

      if (removeImage) {
        fields['remove_image'] = 'true';
      }

      final response = await apiClient.postMultipart(
        '/profile',
        fields,
        file: removeImage ? null : imageFile,
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

  /*
  |--------------------------------------------------------------------------
  | updatePrivacy()
  |--------------------------------------------------------------------------
  | Dipanggil oleh AuthProvider.updatePrivacy() dari PrivacyPolicyScreen saat
  | user menyimpan perubahan email atau password.
  |
  | Parameter:
  | - email: email baru atau email lama yang tetap dikirim sebagai identitas.
  | - password: password baru, opsional; tidak dikirim bila kosong.
  |
  | Request API:
  | POST /privacy dengan body { email, password? }.
  |
  | Return:
  | UserModel terbaru agar AuthProvider dapat memperbarui state dan cache.
  |
  | Efek state:
  | Tidak mengubah state langsung.
  |--------------------------------------------------------------------------
  */
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

  /*
  |--------------------------------------------------------------------------
  | logout()
  |--------------------------------------------------------------------------
  | Dipanggil oleh AuthProvider.logout() setelah user mengonfirmasi logout dari
  | ProfileScreen.
  |
  | Parameter:
  | Tidak ada.
  |
  | Request API:
  | POST /logout dengan body kosong. ApiClient akan menyertakan Bearer token
  | jika token masih tersedia di secure storage.
  |
  | Return:
  | Future<void>.
  |
  | Efek state:
  | Tidak menghapus cache lokal. AuthProvider tetap melakukan cleanup lokal di
  | finally agar user keluar meski request logout backend gagal.
  |--------------------------------------------------------------------------
  */
  Future<void> logout() async {
    try {
      await apiClient.post('/logout', {}, unwrapData: false);
    } catch (e) {
      debugPrint('Warning: Gagal menghapus token di server: $e');
    }
  }

  /*
  |--------------------------------------------------------------------------
  | register()
  |--------------------------------------------------------------------------
  | Dipanggil oleh AuthProvider.register() ketika RegisterScreen mengirim form
  | pendaftaran.
  |
  | Parameter:
  | - fullName: nama user baru.
  | - email: email user baru.
  | - phoneNumber: nomor HP user baru.
  | - password: password dan password_confirmation.
  |
  | Request API:
  | POST /register.
  |
  | Return:
  | Map auth. Token tidak wajib karena alur aplikasi mengarahkan user kembali
  | ke login setelah register berhasil.
  |
  | Efek state:
  | Tidak mengubah state langsung.
  |--------------------------------------------------------------------------
  */
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

  /*
  |--------------------------------------------------------------------------
  | _parseAuthResponse()
  |--------------------------------------------------------------------------
  | Dipanggil internal oleh login(), loginWithGoogle(), dan register().
  |
  | Parameter:
  | - response: JSON decoded dari ApiClient.
  | - fallbackUser: UserModel cadangan untuk register bila response tidak
  |   mengembalikan object user lengkap.
  | - requireToken: true untuk login, false untuk register.
  |
  | Return:
  | Map { token, user }.
  |
  | Efek state:
  | Tidak ada. Method ini hanya validasi dan normalisasi response backend.
  |--------------------------------------------------------------------------
  */
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

  /*
  |--------------------------------------------------------------------------
  | _readString()
  |--------------------------------------------------------------------------
  | Dipanggil internal untuk membaca nilai string dari beberapa kemungkinan
  | path response backend, misalnya token atau access_token.
  |
  | Return:
  | String pertama yang ditemukan, atau null.
  |--------------------------------------------------------------------------
  */
  String? _readString(Map<String, dynamic> source, List<String> paths) {
    for (final path in paths) {
      final value = _readPath(source, path);
      if (value != null) return value.toString();
    }
    return null;
  }

  /*
  |--------------------------------------------------------------------------
  | _readMap()
  |--------------------------------------------------------------------------
  | Dipanggil internal untuk membaca object user dari variasi struktur response
  | seperti user, data.user, atau data.
  |
  | Return:
  | Map<String, dynamic> pertama yang valid, atau null.
  |--------------------------------------------------------------------------
  */
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

  /*
  |--------------------------------------------------------------------------
  | _readPath()
  |--------------------------------------------------------------------------
  | Dipanggil internal oleh parser response untuk membaca nested key dengan
  | format dot-path.
  |
  | Parameter:
  | - source: response JSON utama.
  | - path: path seperti "data.user".
  |
  | Return:
  | Nilai pada path tersebut, atau null jika struktur tidak cocok.
  |--------------------------------------------------------------------------
  */
  dynamic _readPath(Map<String, dynamic> source, String path) {
    dynamic current = source;

    for (final key in path.split('.')) {
      if (current is! Map<String, dynamic>) return null;
      current = current[key];
    }

    return current;
  }
}
