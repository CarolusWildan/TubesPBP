/*
|--------------------------------------------------------------------------
| Confirmation Dialog
|--------------------------------------------------------------------------
| Tujuan file:
| Menyediakan dialog konfirmasi/sukses reusable untuk flow Authentication dan
| Profile.
|
| Peran dalam arsitektur:
| UI Layer helper. Dialog ini tidak mengakses provider; screen pemanggil
| menentukan callback dan navigasi setelah tombol ditekan.
|
| Hubungan dengan Authentication/Profile:
| RegisterScreen dan PersonalInfoScreen memakai dialog sukses. Helper action
| confirmation tersedia untuk flow yang membutuhkan persetujuan user.
|
| Kapan digunakan:
| Saat screen perlu menampilkan pesan sukses atau meminta keputusan user.
|--------------------------------------------------------------------------
*/

// Komponen Flutter untuk Dialog, Icon, Button, dan Navigator.
import 'package:flutter/material.dart';

/*
|--------------------------------------------------------------------------
| ConfirmationDialog
|--------------------------------------------------------------------------
| Tujuan class:
| Widget dialog reusable dengan icon, title, message, tombol utama, dan tombol
| sekunder opsional.
|
| Tanggung jawab:
| Menampilkan dialog terstruktur dan menjalankan callback tombol.
|
| Data yang dikelola:
| Stateless; seluruh konten dan callback diterima dari constructor.
|--------------------------------------------------------------------------
*/
class ConfirmationDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String primaryText;
  final VoidCallback onPrimaryPressed;
  final String? secondaryText;
  final VoidCallback? onSecondaryPressed;

  const ConfirmationDialog({
    super.key,
    this.icon = Icons.fact_check_outlined,
    required this.title,
    required this.message,
    required this.primaryText,
    required this.onPrimaryPressed,
    this.secondaryText,
    this.onSecondaryPressed,
  });

  static const Color primaryGreen = Color(0xFF0EA554);

  /*
  | build()
  | Dipanggil Flutter saat dialog dirender. Return Dialog. Efek state/navigasi
  | terjadi melalui callback onPrimaryPressed atau onSecondaryPressed.
  */
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primaryGreen, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF202124),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPrimaryPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  primaryText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (secondaryText != null && onSecondaryPressed != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onSecondaryPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    secondaryText!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| showSuccessConfirmationDialog()
|--------------------------------------------------------------------------
| Dipanggil screen setelah operasi berhasil, misalnya register atau update
| profile.
|
| Parameter:
| context, title, message, buttonText, icon, dan onPressed menentukan isi dialog
| dan aksi tombol.
|
| Return:
| Future<void> dari showDialog.
|--------------------------------------------------------------------------
*/
Future<void> showSuccessConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'Got it',
  IconData icon = Icons.fact_check_outlined,
  required VoidCallback onPressed,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return ConfirmationDialog(
        icon: icon,
        title: title,
        message: message,
        primaryText: buttonText,
        onPrimaryPressed: onPressed,
      );
    },
  );
}

/*
|--------------------------------------------------------------------------
| showActionConfirmationDialog()
|--------------------------------------------------------------------------
| Dipanggil screen yang membutuhkan keputusan user sebelum aksi berisiko.
|
| Return:
| true jika user menekan tombol confirm, false jika cancel/dismiss.
|--------------------------------------------------------------------------
*/
Future<bool> showActionConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Continue',
  String cancelText = 'Cancel',
  IconData icon = Icons.fact_check_outlined,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return ConfirmationDialog(
        icon: icon,
        title: title,
        message: message,
        primaryText: confirmText,
        onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
        secondaryText: cancelText,
        onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
      );
    },
  );

  return result ?? false;
}
