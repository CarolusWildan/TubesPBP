/*
|--------------------------------------------------------------------------
| Auth Provider
|--------------------------------------------------------------------------
| Tujuan file:
| Menjadi state manager utama untuk Authentication dan data user Profile.
|
| Peran dalam arsitektur:
| UI Layer -> AuthProvider -> AuthRepository -> ApiClient -> Backend API.
| Provider ini menerima event dari Widget, memanggil repository, menyimpan
| token/user ke secure storage, lalu memanggil notifyListeners() agar UI yang
| menggunakan context.watch/Consumer ikut berubah.
|
| Hubungan dengan fitur:
| - Login/Register memakai provider untuk validasi sederhana, request API,
|   penyimpanan token, dan error message.
| - Profile Page membaca user, status loading, dan status autentikasi.
| - Personal Information memperbarui user aktif setelah update profile.
| - Privacy Policy memperbarui email/password dan user aktif.
| - Logout membersihkan token, user cache, dan state provider.
|
| Kapan digunakan:
| Dibuat di main() melalui ChangeNotifierProvider dan tersedia secara global
| untuk screen yang berada di bawah widget tree aplikasi.
|--------------------------------------------------------------------------
*/

// Parser JSON untuk menyimpan dan membaca UserModel dari secure storage.
import 'dart:convert';

// Tipe File untuk foto profil yang dikirim dari PersonalInfoScreen.
import 'dart:io';

// Fondasi Flutter untuk ChangeNotifier dan integrasi dengan Provider.
import 'package:flutter/material.dart';

// Service lokal untuk menyimpan token dan user secara aman di device.
import 'package:tubes_hotel/core/services/local_storage_service.dart';

// Repository yang bertanggung jawab melakukan request Authentication/Profile.
import 'package:tubes_hotel/features/auth/data/auth_repository.dart';

// Model user yang menjadi sumber data Profile di seluruh aplikasi.
import '../../../../shared/models/user_model.dart';

// SDK Google Sign-In untuk mengambil idToken sebelum diverifikasi backend.
import 'package:google_sign_in/google_sign_in.dart' as g_auth;

/*
|--------------------------------------------------------------------------
| AuthProvider
|--------------------------------------------------------------------------
| Tujuan class:
| Menjembatani event UI dengan repository dan menyimpan state autentikasi.
|
| Tanggung jawab:
| - Menyimpan user aktif, loading state, error message, dan status pengecekan
|   login awal.
| - Menjalankan login, Google login, register, update profile, update privacy,
|   dan logout.
| - Menyimpan/menghapus token serta data user di LocalStorageService.
|
| Hubungan dengan class lain:
| - Dipakai LoginScreen, RegisterScreen, ProfileScreen, PersonalInfoScreen,
|   PrivacyPolicyScreen, AuthWrapper, dan screen lain yang membutuhkan user.
| - Memanggil AuthRepository untuk request backend.
| - Memakai LocalStorageService untuk cache token dan user.
|
| Data yang dikelola:
| - _user: UserModel aktif.
| - _isLoading: indikator proses async pada tombol/form.
| - _errorMessage: pesan gagal yang ditampilkan UI.
| - _isCheckingAuth: status bootstrap ketika aplikasi membaca cache login.
|--------------------------------------------------------------------------
*/
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final LocalStorageService _storageService;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  bool _isCheckingAuth = true;

  /*
  |--------------------------------------------------------------------------
  | AuthProvider()
  |--------------------------------------------------------------------------
  | Dipanggil oleh ChangeNotifierProvider di main().
  |
  | Parameter:
  | - authRepository: sumber request backend.
  | - storageService: penyimpanan secure untuk token dan user.
  |
  | Return:
  | Instance AuthProvider.
  |
  | Efek state:
  | State awal belum authenticated sampai checkLoginStatus() selesai membaca
  | token dan cache user.
  |--------------------------------------------------------------------------
  */
  AuthProvider({
    required AuthRepository authRepository,
    required LocalStorageService storageService,
  }) : _authRepository = authRepository,
        _storageService = storageService;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isCheckingAuth => _isCheckingAuth;

  /*
  |--------------------------------------------------------------------------
  | checkLoginStatus()
  |--------------------------------------------------------------------------
  | Dipanggil otomatis dari main() saat AuthProvider dibuat.
  |
  | Alur:
  | 1. Menandai proses pengecekan auth sedang berjalan.
  | 2. Membaca token dari LocalStorageService.
  | 3. Jika token ada, membaca cache user.
  | 4. Mengubah JSON user menjadi UserModel.
  | 5. Jika cache rusak, menghapus token/user lokal.
  | 6. Mengakhiri status checking dan memberi notifikasi UI.
  |
  | Return:
  | Future<void>.
  |
  | Efek state:
  | Mengubah _isCheckingAuth dan mungkin _user. AuthWrapper memakai state ini
  | untuk menentukan apakah menampilkan loading, MainScreen, atau GetStarted.
  |--------------------------------------------------------------------------
  */
  Future<void> checkLoginStatus() async {
    _isCheckingAuth = true;
    notifyListeners();

    try {
      final token = await _storageService.getToken();

      if (token != null && token.isNotEmpty) {
        final userJson = await _storageService.getUser();
        if (userJson != null && userJson.isNotEmpty) {
          final decodedUser = jsonDecode(userJson);
          if (decodedUser is Map<String, dynamic>) {
            _user = UserModel.fromJson(decodedUser);
          }
        }
      }
    } catch (e) {
      await _storageService.deleteToken();
      await _storageService.deleteUser();
      _user = null;
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  /*
  |--------------------------------------------------------------------------
  | updateProfile()
  |--------------------------------------------------------------------------
  | Dipanggil oleh PersonalInfoScreen._handleSave().
  |
  | Parameter:
  | - fullName: nama dari form Personal Information.
  | - phone: nomor HP dari form.
  | - address: alamat dari form.
  | - imageFile: foto baru opsional.
  | - removeImage: true jika user memilih menghapus foto.
  |
  | Request API:
  | Melalui AuthRepository.updateProfile() -> POST multipart /profile.
  |
  | Return:
  | true jika update berhasil, false jika repository melempar error.
  |
  | Efek state:
  | Mengaktifkan loading, mengganti _user dengan data terbaru, menyimpan user
  | ke secure storage, dan memicu notifyListeners().
  |--------------------------------------------------------------------------
  */
  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String address,
    File? imageFile,
    bool removeImage = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _authRepository.updateProfile(
        fullName: fullName,
        phoneNumber: phone,
        address: address,
        imageFile: imageFile,
        removeImage: removeImage,
      );

      _user = updatedUser;
      await _storageService.saveUser(jsonEncode(_user!.toJson()));

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /*
  |--------------------------------------------------------------------------
  | loginWithGoogle()
  |--------------------------------------------------------------------------
  | Dipanggil oleh tombol "Sign in with Google" di LoginScreen.
  |
  | Alur:
  | 1. Membuka Google Sign-In.
  | 2. Mengambil idToken dari akun Google.
  | 3. Mengirim idToken ke AuthRepository.loginWithGoogle().
  | 4. Menerima token aplikasi dan UserModel dari backend.
  | 5. Menyimpan token serta user ke secure storage.
  | 6. Mengisi _user agar aplikasi dianggap authenticated.
  |
  | Request API:
  | Melalui AuthRepository.loginWithGoogle() -> POST /auth/google.
  |
  | Return:
  | true jika login Google berhasil, false jika dibatalkan/gagal.
  |
  | Efek state:
  | Mengubah loading, errorMessage, _user, token cache, dan user cache.
  |--------------------------------------------------------------------------
  */
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final g_auth.GoogleSignIn googleSignIn = g_auth.GoogleSignIn(
        serverClientId: '925221113448-vo8as72u6jcf256c0rgq43ah8v0i92il.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      await googleSignIn.signOut();

      final g_auth.GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final g_auth.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Gagal mendapatkan ID Token dari Google.');
      }

      final result = await _authRepository.loginWithGoogle(idToken);

      final String token = result['token'];
      await _storageService.saveToken(token);

      _user = result['user'] as UserModel;
      await _storageService.saveUser(jsonEncode(_user!.toJson()));

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /*
  |--------------------------------------------------------------------------
  | updatePrivacy()
  |--------------------------------------------------------------------------
  | Dipanggil oleh PrivacyPolicyScreen._handleSave().
  |
  | Parameter:
  | - email: email baru atau email aktif.
  | - password: password baru opsional.
  |
  | Request API:
  | Melalui AuthRepository.updatePrivacy() -> POST /privacy.
  |
  | Return:
  | true jika backend mengembalikan user terbaru, false jika gagal.
  |
  | Efek state:
  | Mengganti _user, menyimpan user terbaru, mengatur loading/error, dan
  | memberi notifikasi ke ProfileScreen serta screen lain yang watch provider.
  |--------------------------------------------------------------------------
  */
  Future<bool> updatePrivacy({
    required String email,
    String? password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _authRepository.updatePrivacy(
        email: email,
        password: password,
      );

      _user = updatedUser;
      await _storageService.saveUser(jsonEncode(_user!.toJson()));

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /*
  |--------------------------------------------------------------------------
  | login()
  |--------------------------------------------------------------------------
  | Dipanggil oleh tombol Login di LoginScreen.
  |
  | Alur:
  | 1. Menyalakan loading dan membersihkan error lama.
  | 2. Validasi email/password kosong.
  | 3. Validasi format email.
  | 4. Memanggil AuthRepository.login().
  | 5. Menyimpan token ke LocalStorageService.
  | 6. Menyimpan user ke _user dan secure storage.
  | 7. Mengembalikan true agar LoginScreen redirect ke MainScreen.
  |
  | Parameter:
  | - email: nilai dari _emailController.
  | - password: nilai dari _passwordController.
  |
  | Request API:
  | AuthRepository.login() -> ApiClient.post('/login') -> Backend.
  |
  | Return:
  | true jika login berhasil, false jika validasi/API gagal.
  |
  | Efek state:
  | Mengubah _isLoading, _errorMessage, _user, token cache, dan user cache.
  |--------------------------------------------------------------------------
  */
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    if (email.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = "Email and password cannot be empty.";
      _setLoading(false);
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _errorMessage = "Invalid email format.";
      _setLoading(false);
      return false;
    }

    try {
      final result = await _authRepository.login(email, password);

      final String token = result['token'];
      await _storageService.saveToken(token);

      _user = result['user'] as UserModel;
      await _storageService.saveUser(jsonEncode(_user!.toJson()));

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | register()
  |--------------------------------------------------------------------------
  | Dipanggil oleh tombol Register di RegisterScreen.
  |
  | Parameter:
  | - fullName: nama dari form.
  | - email: email dari form.
  | - phoneNumber: nomor HP dari form.
  | - password: password dari form.
  |
  | Request API:
  | AuthRepository.register() -> ApiClient.post('/register') -> Backend.
  |
  | Return:
  | true jika register berhasil, false jika backend mengembalikan error.
  |
  | Efek state:
  | Setelah register sukses, token/user lokal dihapus dan _user dibuat null
  | agar user tetap diarahkan ke login sesuai flow aplikasi.
  |--------------------------------------------------------------------------
  */
  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.register(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );

      await _storageService.deleteToken();
      await _storageService.deleteUser();
      _user = null;

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | logout()
  |--------------------------------------------------------------------------
  | Dipanggil oleh ProfileScreen setelah user menekan "Yes, Log Out" pada
  | dialog konfirmasi.
  |
  | Alur:
  | 1. Menyalakan loading.
  | 2. Memanggil AuthRepository.logout() untuk POST /logout.
  | 3. Menghapus token dan user dari secure storage.
  | 4. Mengosongkan _user.
  | 5. Mematikan loading dan memberi notifikasi UI.
  |
  | Return:
  | Future<void>.
  |
  | Efek state:
  | isAuthenticated menjadi false. ProfileScreen kemudian melakukan redirect
  | ke LoginScreen dan menghapus navigation stack.
  |--------------------------------------------------------------------------
  */
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authRepository.logout();
    } finally {
      await _storageService.deleteToken();
      await _storageService.deleteUser();
      _user = null;
      _setLoading(false);
    }
  }

  /*
  |--------------------------------------------------------------------------
  | _setLoading()
  |--------------------------------------------------------------------------
  | Dipanggil oleh method async provider untuk mengatur indikator proses.
  |
  | Parameter:
  | - value: true saat request berjalan, false saat selesai.
  |
  | Efek state:
  | Mengubah _isLoading dan memanggil notifyListeners().
  |--------------------------------------------------------------------------
  */
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /*
  |--------------------------------------------------------------------------
  | _clearError()
  |--------------------------------------------------------------------------
  | Dipanggil sebelum operasi auth/profile baru dimulai.
  |
  | Return:
  | void.
  |
  | Efek state:
  | Menghapus pesan error lama. Notifikasi UI terjadi lewat _setLoading()
  | di awal operasi yang sama.
  |--------------------------------------------------------------------------
  */
  void _clearError() {
    _errorMessage = null;
  }
}
