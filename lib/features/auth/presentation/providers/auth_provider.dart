import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tubes_hotel/core/services/local_storage_service.dart';
import 'package:tubes_hotel/features/auth/data/auth_repository.dart';
import '../../../../shared/models/user_model.dart';

// --- 3. AUTH PROVIDER (ViewModel) ---
// Lokasi: lib/features/auth/presentation/providers/auth_provider.dart
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final LocalStorageService _storageService;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // --- 1. TAMBAHAN: Variabel status awal (default true) ---
  bool _isCheckingAuth = true;

  AuthProvider({
    required AuthRepository authRepository,
    required LocalStorageService storageService,
  }) : _authRepository = authRepository,
       _storageService = storageService;

  // Getters untuk dibaca oleh UI
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Memeriksa apakah user sudah login (berguna untuk logic UI/Splash Screen)
  bool get isAuthenticated => _user != null;

  // --- 2. TAMBAHAN: Getter untuk status awal ---
  bool get isCheckingAuth => _isCheckingAuth;

  // --- 3. TAMBAHAN: Fungsi Cek Sesi (Dipanggil di main.dart) ---
  Future<void> checkLoginStatus() async {
    _isCheckingAuth = true;
    notifyListeners(); // UI menampilkan Loading (AuthWrapper)

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
      notifyListeners(); // Selesai loading, UI lompat ke Home/Login
    }
  }

  // Tambahkan di dalam AuthProvider
  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String address,
    File? imageFile,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // 1. Panggil API Laravel melalui Repository
      // Pastikan _authRepository.updateProfile mengembalikan object UserModel terbaru
      final updatedUser = await _authRepository.updateProfile(
        fullName: fullName,
        phoneNumber: phone,
        address: address,
        imageFile: imageFile,
      );

      // 2. Perbarui state lokal
      _user = updatedUser;

      // 3. Timpa data lama di Local Storage
      await _storageService.saveUser(jsonEncode(_user!.toJson()));

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false); // Otomatis memanggil notifyListeners()
    }
  }

  // Fungsi Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    // --- 1. CLIENT-SIDE VALIDATION ---
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

    // --- 2. PANGGIL API LARAVEL ---
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

  // Fungsi Register
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

  // Fungsi Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      // 1. Beritahu server untuk mencabut token
      await _authRepository.logout();
    } finally {
      // 2. Blok 'finally' menjamin bahwa APAPUN yang terjadi pada server (sukses/gagal/timeout),
      // data lokal user di HP akan tetap dihapus. Ini krusial untuk UX.
      await _storageService.deleteToken();
      await _storageService.deleteUser();
      _user = null;
      _setLoading(
        false,
      ); // notifyListeners() sudah dipanggil di dalam _setLoading
    }
  }

  // Helpers internal
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    // Tidak panggil notifyListeners() karena _setLoading sudah memanggilnya
  }
}
