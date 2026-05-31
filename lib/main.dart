import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/local_storage_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/home/presentation/providers/home_provider.dart';
import 'features/home/presentation/screens/main_screen.dart';
import 'features/splash/presentation/screens/get_started_screen.dart';
import 'shared/network/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
