import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
              // --- AREA LOGO ---
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

              // --- AREA TEKS ---
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

              // --- AREA FORM ---
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

              // --- TOMBOL REGISTER ---
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

              // --- LINK KEMBALI KE LOGIN ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Have an account? ',
                    style: TextStyle(color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Kembali ke layar Sign In
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
