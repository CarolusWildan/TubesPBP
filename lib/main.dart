import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- CORE & SHARED IMPORTS ---
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

// --- BOOKING IMPORTS ---
import 'features/home/presentation/screens/booking_summary_screen.dart';
import 'features/home/presentation/providers/booking_summary_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final localStorageService = LocalStorageService();
  final apiClient = ApiClient(storageService: localStorageService);
  final authRepository = AuthRepository(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            authRepository: authRepository,
            storageService: localStorageService,
          )..checkLoginStatus(),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeProvider(apiClient: apiClient),
        ),
        // Tambahkan BookingSummaryProvider
        ChangeNotifierProvider(
          create: (context) => BookingSummaryProvider(apiClient: apiClient),
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
      title: 'Pitulungan Inn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0EA554)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),

      // TODO: Ganti ke MainScreen() / AuthWrapper() setelah selesai preview
      // home: const BookingSummaryScreen(), // ← sementara untuk preview
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
        // SKENARIO 1: APLIKASI BARU DIBUKA
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

        // SKENARIO 2: SUDAH LOGIN
        if (authProvider.isAuthenticated) {
          return const MainScreen();
        }

        // SKENARIO 3: BELUM LOGIN
        return const GetStartedScreen();
      },
    );
  }
}
