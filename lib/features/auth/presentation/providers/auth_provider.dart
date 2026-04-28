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
  })  : _authRepository = authRepository,
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
        // SEMENTARA KITA MOCK DATA USER-NYA:
        // Idealnya ini melakukan fetch ke API Laravel (/api/profile) menggunakan token
        _user = UserModel(
          id: '1', 
          fullName: 'Tamu Terdaftar', 
          email: 'user@hotel.com', 
          phoneNumber: '08123456789'
        );
      }
    } catch (e) {
      await _storageService.deleteToken();
      _user = null;
    } finally {
      _isCheckingAuth = false;
      notifyListeners(); // Selesai loading, UI lompat ke Home/Login
    }
  }

  // Fungsi Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // 1. Panggil API melalui Repository
      final result = await _authRepository.login(email, password);
      
      // 2. Simpan token ke local storage
      final String token = result['token'];
      await _storageService.saveToken(token);

      // 3. Simpan data user ke memory state Provider
      _user = result['user'] as UserModel;
      
      _setLoading(false);
      return true; // Beri tahu UI bahwa login sukses
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString().replaceAll('Exception: ', ''); // Bersihkan pesan error
      notifyListeners();
      return false; // Beri tahu UI bahwa login gagal
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
      final result = await _authRepository.register(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );

      final String token = result['token'];
      await _storageService.saveToken(token);
      
      _user = result['user'] as UserModel;

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
    // Idealnya panggil _authRepository.logout() juga jika Laravel butuh mencabut token (revoke)
    await _storageService.deleteToken();
    _user = null;
    notifyListeners();
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