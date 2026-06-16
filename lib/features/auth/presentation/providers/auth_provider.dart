import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tubes_hotel/core/services/local_storage_service.dart';
import 'package:tubes_hotel/features/auth/data/auth_repository.dart';
import '../../../../shared/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart' as g_auth;

// --- 3. AUTH PROVIDER (ViewModel) ---
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final LocalStorageService _storageService;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  bool _isCheckingAuth = true;

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

  // PERBAIKAN: Logika penyimpanan token ditangani di sini
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

      // Repository sekarang mengembalikan Map (Token & User)
      final result = await _authRepository.loginWithGoogle(idToken);

      // Simpan Token
      final String token = result['token'];
      await _storageService.saveToken(token);

      // Simpan User
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
