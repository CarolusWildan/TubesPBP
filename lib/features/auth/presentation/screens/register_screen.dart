/*
|--------------------------------------------------------------------------
| Register Screen
|--------------------------------------------------------------------------
| Tujuan file:
| Menampilkan form pendaftaran akun dan mengirim data registrasi ke
| AuthProvider tanpa menyimpan sesi login baru.
|
| Peran dalam arsitektur:
| RegisterScreen -> AuthProvider.register() -> AuthRepository.register()
| -> ApiClient.post('/register') -> Backend API.
|
| Hubungan dengan Authentication/Profile:
| Data nama, email, nomor HP, dan password yang dibuat di sini menjadi sumber
| awal UserModel ketika user login setelah registrasi berhasil.
|
| Kapan digunakan:
| Dibuka dari LoginScreen melalui link Sign up.
|--------------------------------------------------------------------------
*/

// Komponen dasar Flutter untuk layout, input, button, dialog, dan navigasi.
import 'package:flutter/material.dart';

// Provider dipakai untuk membaca AuthProvider dan menampilkan loading/error.
import 'package:provider/provider.dart';

// State manager auth yang menjalankan request register ke backend.
import '../providers/auth_provider.dart';

// Widget input reusable untuk nama, email, telepon, dan password.
import '../../../../shared/widgets/custom_text_field.dart';

// Tombol utama reusable dengan loading state.
import '../../../../shared/widgets/primary_button.dart';

// Dialog sukses yang ditampilkan setelah register berhasil.
import '../../../../shared/widgets/confirmation_dialog.dart';

/*
|--------------------------------------------------------------------------
| RegisterScreen
|--------------------------------------------------------------------------
| Tujuan class:
| Widget route pendaftaran akun baru.
|
| Tanggung jawab:
| Menyerahkan lifecycle form ke _RegisterScreenState.
|
| Data yang dikelola:
| Tidak ada data langsung.
|--------------------------------------------------------------------------
*/
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  /*
  |--------------------------------------------------------------------------
  | createState()
  |--------------------------------------------------------------------------
  | Dipanggil Flutter saat RegisterScreen dimasukkan ke widget tree.
  |
  | Return:
  | _RegisterScreenState yang menyimpan TextEditingController form.
  |--------------------------------------------------------------------------
  */
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

/*
|--------------------------------------------------------------------------
| _RegisterScreenState
|--------------------------------------------------------------------------
| Tujuan class:
| Mengelola input registrasi, event tombol Register, dan navigasi balik login.
|
| Tanggung jawab:
| - Menyimpan controller nama, email, nomor HP, dan password.
| - Membaca loading/error dari AuthProvider.
| - Memanggil AuthProvider.register().
| - Menampilkan dialog sukses dan kembali ke LoginScreen.
|
| Data yang dikelola:
| Empat TextEditingController sesuai field form register.
|--------------------------------------------------------------------------
*/
class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  /*
  |--------------------------------------------------------------------------
  | dispose()
  |--------------------------------------------------------------------------
  | Dipanggil Flutter saat route register ditutup.
  |
  | Efek state:
  | Membersihkan seluruh controller form.
  |--------------------------------------------------------------------------
  */
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | build()
  |--------------------------------------------------------------------------
  | Dipanggil Flutter untuk merender halaman register dan rebuild ketika
  | AuthProvider.notifyListeners() berjalan.
  |
  | Interaksi state:
  | context.watch<AuthProvider>() membaca isLoading dan errorMessage.
  |
  | Event widget:
  | - PrimaryButton Register memanggil AuthProvider.register().
  | - Link Sign in melakukan Navigator.pop() kembali ke LoginScreen.
  |
  | Navigasi:
  | Register berhasil -> dialog sukses -> pop dialog -> pop RegisterScreen.
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
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use proper information to continue',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _nameController,
                hintText: 'Full Name',
                prefixIcon: Icons.person_outline,
              ),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email Address',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              CustomTextField(
                controller: _phoneController,
                hintText: 'Phone Number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
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
                ),
                const SizedBox(height: 12),
              ],
              PrimaryButton(
                text: 'Register',
                isLoading: authProvider.isLoading,
                onPressed: () async {
                  final success = await authProvider.register(
                    fullName: _nameController.text,
                    email: _emailController.text,
                    phoneNumber: _phoneController.text,
                    password: _passwordController.text,
                  );
                  if (!context.mounted) return;

                  if (success) {
                    showSuccessConfirmationDialog(
                      context: context,
                      title: 'Success',
                      message: 'Register berhasil. Silakan sign in.',
                      buttonText: 'Got it',
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Have an account? ',
                    style: TextStyle(color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Sign in',
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
