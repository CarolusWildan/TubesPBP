/*
|--------------------------------------------------------------------------
| Login Screen
|--------------------------------------------------------------------------
| Tujuan file:
| Menampilkan halaman sign in dan menghubungkan input user ke AuthProvider.
|
| Peran dalam arsitektur:
| File ini berada di UI Layer. Data bergerak dengan alur:
| LoginScreen -> AuthProvider.login()/loginWithGoogle() -> AuthRepository
| -> ApiClient -> Backend API -> token/user -> LocalStorageService
| -> AuthProvider state -> Navigate MainScreen.
|
| Hubungan dengan Authentication/Profile:
| Login yang berhasil membuat AuthProvider.user terisi. Data user tersebut
| kemudian dipakai ProfileScreen, PersonalInfoScreen, booking summary, dan
| screen lain yang membutuhkan identitas user.
|
| Kapan digunakan:
| Dibuka dari GetStartedScreen, dari redirect logout ProfileScreen, atau
| saat user belum memiliki sesi login aktif.
|--------------------------------------------------------------------------
*/

// Komponen dasar Flutter untuk Scaffold, form input, button, dan navigasi.
import 'package:flutter/material.dart';

// Provider dipakai untuk membaca AuthProvider dan merender loading/error.
import 'package:provider/provider.dart';

// Halaman utama yang dituju setelah login manual atau Google berhasil.
import 'package:tubes_hotel/features/home/presentation/screens/main_screen.dart';

// State manager authentication yang menjalankan login dan Google login.
import '../providers/auth_provider.dart';

// Widget input reusable untuk field email dan password.
import '../../../../shared/widgets/custom_text_field.dart';

// Tombol utama reusable yang mendukung loading state.
import '../../../../shared/widgets/primary_button.dart';

// Halaman pendaftaran yang dibuka dari link Sign up.
import 'register_screen.dart';

/*
|--------------------------------------------------------------------------
| LoginScreen
|--------------------------------------------------------------------------
| Tujuan class:
| Widget halaman login yang menampung state controller melalui State object.
|
| Tanggung jawab:
| Membuat route UI login dan menyerahkan lifecycle ke _LoginScreenState.
|
| Hubungan class:
| LoginScreen dibuat oleh navigator dan akan memakai _LoginScreenState untuk
| membaca AuthProvider.
|
| Data yang dikelola:
| Tidak ada data langsung di class ini.
|--------------------------------------------------------------------------
*/
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  /*
  |--------------------------------------------------------------------------
  | createState()
  |--------------------------------------------------------------------------
  | Dipanggil Flutter framework saat LoginScreen dimasukkan ke widget tree.
  |
  | Return:
  | _LoginScreenState yang menyimpan TextEditingController email/password.
  |--------------------------------------------------------------------------
  */
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/*
|--------------------------------------------------------------------------
| _LoginScreenState
|--------------------------------------------------------------------------
| Tujuan class:
| Mengelola input login, event tombol, dan navigasi setelah autentikasi.
|
| Tanggung jawab:
| - Menyimpan controller email/password.
| - Membaca loading/error dari AuthProvider.
| - Memanggil login manual atau Google login.
| - Mengarahkan user ke MainScreen jika login berhasil.
|
| Data yang dikelola:
| - _emailController: nilai email form.
| - _passwordController: nilai password form.
|--------------------------------------------------------------------------
*/
class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /*
  |--------------------------------------------------------------------------
  | dispose()
  |--------------------------------------------------------------------------
  | Dipanggil Flutter saat LoginScreen dihapus dari widget tree.
  |
  | Efek state:
  | Membersihkan TextEditingController agar resource input tidak bocor.
  |--------------------------------------------------------------------------
  */
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | build()
  |--------------------------------------------------------------------------
  | Dipanggil Flutter setiap kali UI perlu dirender ulang, termasuk ketika
  | AuthProvider.notifyListeners() dipanggil.
  |
  | Interaksi state:
  | context.watch<AuthProvider>() membuat widget rebuild saat isLoading atau
  | errorMessage berubah.
  |
  | Event widget:
  | - PrimaryButton Login memanggil AuthProvider.login().
  | - OutlinedButton Google memanggil AuthProvider.loginWithGoogle().
  | - Link Sign up melakukan Navigator.push ke RegisterScreen.
  |
  | Navigasi:
  | Login berhasil -> pushAndRemoveUntil(MainScreen) agar halaman auth tidak
  | tersisa di back stack.
  |--------------------------------------------------------------------------
  */
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                height: 200,
                width: 150,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.hotel,
                      size: 80,
                      color: Color(0xFF0EA554),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email and password to continue',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Password',
                prefixIcon: Icons.lock_outline,
                isObscure: true,
              ),
              const SizedBox(height: 24),
              if (authProvider.errorMessage != null) ...[
                Text(
                  authProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              PrimaryButton(
                text: 'Login',
                isLoading: authProvider.isLoading,
                onPressed: () async {
                  final success = await authProvider.login(
                    _emailController.text,
                    _passwordController.text,
                  );

                  if (success && mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Or Continue With',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        final success = await authProvider.loginWithGoogle();

                        if (success && mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                  height: 20,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.g_mobiledata,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
                label: const Text(
                  'Sign in with Google',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.black12),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Haven't any account? ",
                    style: TextStyle(color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Sign up',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
