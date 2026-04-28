import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- CORE & SHARED IMPORTS ---
// Sesuaikan nama 'tubes_hotel' dengan nama package di pubspec.yaml Anda jika berbeda.
import 'core/services/local_storage_service.dart';
import 'shared/network/api_client.dart';

// --- AUTH IMPORTS ---
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

// --- SPLASH IMPORTS ---
import 'features/splash/presentation/screens/get_started_screen.dart';

// --- HOME IMPORTS ---
import 'features/home/presentation/providers/home_provider.dart';
import 'features/home/presentation/screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. DEPENDENCY INJECTION (Inisialisasi Service & Network)
  final apiClient = ApiClient();
  final localStorageService = LocalStorageService();

  // 2. INISIALISASI REPOSITORY
  final authRepository = AuthRepository(apiClient: apiClient);

  // 3. JALANKAN APLIKASI
  runApp(
    MultiProvider(
      providers: [
        // Daftarkan AuthProvider (Ditambah perintah cek sesi login awal)
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            authRepository: authRepository,
            storageService: localStorageService,
          )..checkLoginStatus(), 
        ),
        
        // Daftarkan HomeProvider
        ChangeNotifierProvider(
          create: (context) => HomeProvider(),
        ),
      ],
      child: const HotelApp(),
    ),
  );
}

class HotelApp extends StatelessWidget {
  const HotelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pitulungan Inn', // Ganti judul aplikasi sesuai nama proyek Anda
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Menyelaraskan warna dasar aplikasi dengan hijau utama Figma Anda
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0EA554)),
        useMaterial3: true,
        fontFamily: 'Roboto', // Pastikan Anda menambahkan font yang sesuai di pubspec.yaml jika perlu
      ),
      
      // --- DEV BYPASS: SEMENTARA LANGSUNG KE MAIN SCREEN UNTUK CEK UI ---
      // TODO: Jika ingin mengetes alur Login/Register lagi, hapus baris MainScreen() 
      // dan aktifkan kembali baris AuthWrapper().
      home: const MainScreen(),
      // home: const AuthWrapper(),
    );
  }
}

/// AUTH WRAPPER: "Satpam Navigasi Dinamis"
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        
        // SKENARIO 1: APLIKASI BARU DIBUKA (Membaca Token dari Storage)
        if (authProvider.isCheckingAuth) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Progress Bar bergaris (simulasi pixel-perfect)
                  SizedBox(
                    width: 200,
                    height: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        backgroundColor: Color(0xFFE8F5E9), 
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0EA554)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Verifying Credentials',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // SKENARIO 2: SUKSES LOGIN (Token Valid -> Masuk ke Home)
        if (authProvider.isAuthenticated) {
          return const MainScreen(); // <--- KOREKSI: Sekarang langsung memanggil UI Home!
        }

        // SKENARIO 3: BELUM LOGIN / TOKEN EXPIRED (Arahkan ke Onboarding)
        return const GetStartedScreen(); 
      },
    );
  }
}