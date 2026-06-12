import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  late String _initialEmail;
  
  bool _isEditing = false;
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _obscurePassword = true;

  static const Color _primaryGreen = Color(0xFF0EA554);
  static const Color _inputBackground = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    final currentUser = context.read<AuthProvider>().user;

    _initialEmail = currentUser?.email ?? '';

    _emailController = TextEditingController(text: _initialEmail);
    _passwordController = TextEditingController(); 

    _emailController.addListener(_checkForChanges);
    _passwordController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _emailController.removeListener(_checkForChanges);
    _passwordController.removeListener(_checkForChanges);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final currentEmail = _emailController.text.trim();
    final currentPassword = _passwordController.text.trim();

    final isChanged = (currentEmail != _initialEmail && currentEmail.isNotEmpty) || currentPassword.isNotEmpty;

    if (_hasChanges != isChanged) {
      setState(() => _hasChanges = isChanged);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_box, color: _primaryGreen, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Success',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your privacy policy details have been changed successfully',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87, fontSize: 14),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Directing to Home...',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE8F5E9),
                        valueColor: const AlwaysStoppedAnimation<Color>(_primaryGreen),
                      );
                    },
                    onEnd: () {
                      if (!mounted) return;
                      // Tutup dialog
                      Navigator.of(dialogContext).pop(); 
                      // Tutup layar Privacy Policy dan kembali ke Profile
                      Navigator.of(context).pop(); 
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    final newEmail = _emailController.text.trim();
    final newPassword = _passwordController.text.trim();

    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email cannot be empty!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await context.read<AuthProvider>().updatePrivacy(
        email: newEmail,
        password: newPassword.isEmpty ? null : newPassword,
      );

      if (!mounted) return;

      if (success) {
        _showSuccessDialog();
      } else {
        final error = context.read<AuthProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Failed to update privacy info')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      label: 'Email Address',
                      controller: _emailController,
                      enabled: _isEditing && !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: 'Password',
                      controller: _passwordController,
                      enabled: _isEditing && !_isLoading,
                      obscureText: _obscurePassword,
                      isPassword: true,
                      hintText: _isEditing ? 'Enter new password' : '*************', 
                    ),
                  ],
                ),
              ),
            ),
            
            // --- Bottom Action Button ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: _isEditing
                    ? ElevatedButton(
                        onPressed: (_hasChanges && !_isLoading) ? _handleSave : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          disabledBackgroundColor: Colors.grey.shade400,
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      )
                    : ElevatedButton(
                        onPressed: () => setState(() => _isEditing = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Edit Privacy Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    bool obscureText = false,
    bool isPassword = false,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF202124), fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(
            color: enabled ? Colors.black87 : Colors.black54,
            fontSize: isPassword && !enabled ? 20 : 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputBackground,
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: isPassword && enabled
                ? IconButton(
                    icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}