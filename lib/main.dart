/*
|--------------------------------------------------------------------------
| Application Entry Point
|--------------------------------------------------------------------------
| Tujuan file:
| Menyiapkan dependency utama aplikasi dan menentukan route awal berdasarkan
| status autentikasi user.
|
| Peran dalam arsitektur:
| main() membuat LocalStorageService, ApiClient, AuthRepository, AuthProvider,
| dan HomeProvider. AuthWrapper kemudian membaca AuthProvider untuk menentukan
| apakah user masuk ke MainScreen atau GetStartedScreen.
|
| Hubungan dengan Authentication/Profile:
| AuthProvider yang dibuat di sini menjadi sumber state untuk Login, Register,
| Profile Page, Personal Information, Privacy Policy, dan Logout.
|
| Kapan digunakan:
| Dipanggil pertama kali saat aplikasi Flutter dijalankan.
|--------------------------------------------------------------------------
*/

// Komponen dasar Flutter untuk runApp, MaterialApp, dan widget tree.
import 'package:flutter/material.dart';

// Membaca konfigurasi .env seperti API_BASE_URL sebelum ApiClient dibuat.
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Provider dipakai untuk dependency injection dan ChangeNotifier state.
import 'package:provider/provider.dart';

// Secure storage service untuk token dan cache user.
import 'core/services/local_storage_service.dart';

// Repository authentication/profile yang memakai ApiClient.
import 'features/auth/data/auth_repository.dart';

// Provider auth global untuk login/register/profile/privacy/logout.
import 'features/auth/presentation/providers/auth_provider.dart';

// Provider home yang juga membutuhkan ApiClient.
import 'features/home/presentation/providers/home_provider.dart';

// Halaman utama setelah user authenticated.
import 'features/home/presentation/screens/main_screen.dart';

// Halaman awal untuk user yang belum authenticated.
import 'features/splash/presentation/screens/get_started_screen.dart';

// HTTP client bersama untuk request backend.
import 'shared/network/api_client.dart';

/*
|--------------------------------------------------------------------------
| main()
|--------------------------------------------------------------------------
| Dipanggil runtime Flutter saat aplikasi dimulai.
|
| Alur:
| 1. Memastikan binding Flutter siap.
| 2. Memuat file .env.
| 3. Membuat LocalStorageService, ApiClient, dan AuthRepository.
| 4. Mendaftarkan provider global.
| 5. Memanggil AuthProvider.checkLoginStatus() untuk restore sesi.
|
| Efek state:
| AuthProvider akan mengisi user dari cache jika token/user tersimpan.
|--------------------------------------------------------------------------
*/
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final localStorageService = LocalStorageService();
  final apiClient = ApiClient(storageService: localStorageService);
  final authRepository = AuthRepository(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            authRepository: authRepository,
            storageService: localStorageService,
          )..checkLoginStatus(),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeProvider(apiClient: apiClient),
        ),
      ],
      child: const HotelApp(),
    ),
  );
}

/*
|--------------------------------------------------------------------------
| HotelApp
|--------------------------------------------------------------------------
| Tujuan class:
| Root widget MaterialApp untuk konfigurasi tema dan halaman awal.
|
| Hubungan class:
| Menampilkan AuthWrapper sebagai home agar route awal bergantung pada status
| AuthProvider.
|--------------------------------------------------------------------------
*/
class HotelApp extends StatelessWidget {
  const HotelApp({super.key});

  /*
  | build()
  | Dipanggil Flutter untuk membuat MaterialApp. Return MaterialApp dengan
  | theme dan AuthWrapper sebagai home.
  */
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pitulungan Inn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0EA554)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthWrapper(),
    );
  }
}

/*
|--------------------------------------------------------------------------
| AuthWrapper
|--------------------------------------------------------------------------
| Tujuan class:
| Menentukan tampilan awal berdasarkan state Authentication.
|
| Tanggung jawab:
| - Menampilkan loading saat AuthProvider.checkLoginStatus() berjalan.
| - Menampilkan MainScreen jika user authenticated.
| - Menampilkan GetStartedScreen jika belum authenticated.
|
| Data yang dikelola:
| Stateless; seluruh keputusan berasal dari AuthProvider.
|--------------------------------------------------------------------------
*/
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  /*
  | build()
  | Dipanggil Flutter dan rebuild saat AuthProvider.notifyListeners() berjalan.
  | Return screen sesuai isCheckingAuth/isAuthenticated.
  */
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isCheckingAuth) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        backgroundColor: Color(0xFFE8F5E9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0EA554),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Verifying Credentials',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          return const MainScreen();
        }

        return const GetStartedScreen();
      },
    );
  }
}
