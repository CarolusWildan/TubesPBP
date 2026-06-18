import 'package:flutter/material.dart';

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
