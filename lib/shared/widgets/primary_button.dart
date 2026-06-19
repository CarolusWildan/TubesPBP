/*
|--------------------------------------------------------------------------
| Primary Button
|--------------------------------------------------------------------------
| Tujuan file:
| Menyediakan tombol aksi utama reusable dengan loading state.
|
| Peran dalam arsitektur:
| UI Layer widget. Button ini tidak mengetahui provider/repository; event
| onPressed diberikan oleh screen seperti LoginScreen dan RegisterScreen.
|
| Hubungan dengan Authentication/Profile:
| Dipakai untuk memicu login/register dan menampilkan spinner ketika
| AuthProvider.isLoading true.
|
| Kapan digunakan:
| Saat screen membutuhkan tombol submit utama.
|--------------------------------------------------------------------------
*/

// Komponen Flutter untuk ElevatedButton, progress indicator, dan layout.
import 'package:flutter/material.dart';

/*
|--------------------------------------------------------------------------
| PrimaryButton
|--------------------------------------------------------------------------
| Tujuan class:
| Tombol submit reusable yang otomatis disabled ketika loading.
|
| Tanggung jawab:
| Menampilkan label normal atau CircularProgressIndicator dan meneruskan event
| klik ke callback screen.
|
| Data yang dikelola:
| text, onPressed, dan isLoading diterima dari screen.
|--------------------------------------------------------------------------
*/
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  /*
  | build()
  | Dipanggil Flutter saat tombol dirender. Return SizedBox berisi
  | ElevatedButton. Efek state terjadi di callback onPressed milik screen.
  */
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0EA554),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
