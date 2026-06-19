/*
|--------------------------------------------------------------------------
| Custom Text Field
|--------------------------------------------------------------------------
| Tujuan file:
| Menyediakan input teks reusable untuk form Authentication.
|
| Peran dalam arsitektur:
| UI Layer widget. Tidak memanggil provider atau repository; nilai input dibaca
| oleh screen melalui TextEditingController.
|
| Hubungan dengan Authentication/Profile:
| Dipakai LoginScreen untuk email/password dan RegisterScreen untuk nama,
| email, telepon, serta password.
|
| Kapan digunakan:
| Saat screen membutuhkan field teks dengan style yang konsisten.
|--------------------------------------------------------------------------
*/

// Komponen Flutter untuk TextFormField, IconData, dan styling input.
import 'package:flutter/material.dart';

/*
|--------------------------------------------------------------------------
| CustomTextField
|--------------------------------------------------------------------------
| Tujuan class:
| Widget input reusable dengan icon prefix, hint, mode password, dan keyboard.
|
| Tanggung jawab:
| Menampilkan TextFormField terstyling dan meneruskan perubahan nilai ke
| TextEditingController milik screen pemanggil.
|
| Data yang dikelola:
| Stateless; semua data berasal dari constructor.
|--------------------------------------------------------------------------
*/
class CustomTextField extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;
  final bool isObscure;
  final TextEditingController? controller;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.isObscure = false,
    this.controller,
    this.keyboardType = TextInputType.text,
  });

  /*
  | build()
  | Dipanggil Flutter saat field dirender. Return Padding berisi TextFormField.
  | Efek state: tidak ada; controller eksternal menyimpan nilai input.
  */
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
          prefixIcon: Icon(prefixIcon, color: Colors.black54, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: const BorderSide(color: Colors.black45, width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: const BorderSide(color: Color(0xFF0EA554), width: 1.5),
          ),
        ),
      ),
    );
  }
}
