import '../../../../shared/models/user_model.dart';
import '../../../../shared/network/api_client.dart';

// --- 2. AUTH REPOSITORY ---
// Idealnya diletakkan di: lib/features/auth/data/auth_repository.dart
class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  // Asumsi Request Body: { "email": "...", "password": "..." }
  // Asumsi Response JSON: { "status": "success", "data": { "token": "1|abc...", "user": { ... } } }
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await apiClient.post('/login', {
        'email': email,
        'password': password,
      });

      // Mengembalikan Map berisi token dan UserModel mentah
      return {
        'token': response['token'], // Tergantung struktur Laravel Anda nanti
        'user': UserModel.fromJson(response['user']),
      };
    } catch (e) {
      // Menangkap error dari ApiClient (misal: "Error 401: Email/Password salah")
      rethrow;
    }
  }

  // Asumsi Request Body sesuai field UserModel ditambah password
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await apiClient.post('/register', {
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
        'password_confirmation': password, // Laravel biasanya butuh field ini
      });

      return {
        'token': response['token'],
        'user': UserModel.fromJson(response['user']),
      };
    } catch (e) {
      rethrow;
    }
  }
}