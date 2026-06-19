import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
// 1. UBAH IMPORT: Kita ganti GetStartedScreen dengan LoginScreen
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../shared/network/api_client.dart';
import 'personal_info_screen.dart';
import 'privacy_policy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _primaryGreen = Color(0xFF0EA554);
  static const Color _pageBackground = Color(0xFFF8F9FA);
  static const Color _dangerRed = Color(0xFFFF3B30);

  // Fungsi pembantu untuk mengambil inisial nama
  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    List<String> words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final displayName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName
        : 'User';
    final email = user?.email.trim().isNotEmpty == true
        ? user!.email
        : 'user@gmail.com';

    // --- Logika Penentuan Gambar Profile ---
    final bool hasDatabaseImage =
        user?.userImage != null && user!.userImage!.trim().isNotEmpty;
    final String initials = _getInitials(displayName);

    ImageProvider? profileImageProvider;
    if (hasDatabaseImage) {
      // 🟢 Ganti URL ini dengan URL Ngrok kamu yang sedang aktif + '/storage/'
      // Tambahkan ?v= (timestamp) agar Flutter mengabaikan cache lama jika ada pembaruan
      final String fullImageUrl =
          '${ApiClient.serverUrl}/storage/${user!.userImage!}?v=${DateTime.now().millisecondsSinceEpoch}';
      profileImageProvider = NetworkImage(
        fullImageUrl,
        headers: ApiClient.imageHeaders,
      );
    }

    return Container(
      color: _primaryGreen,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // --- Tampilan Avatar Dinamis ---
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors
                              .white, // Background putih jika gambar kosong
                          backgroundImage: profileImageProvider,
                          child: profileImageProvider == null
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    color: _primaryGreen,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Area putih dibuat fleksibel agar tetap penuh di berbagai ukuran layar.
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
                decoration: const BoxDecoration(
                  color: _pageBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Settings',
                      style: TextStyle(
                        color: Color(0xFF202124),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ProfileMenuTile(
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PersonalInfoScreen(),
                          ),
                        );
                      },
                    ),
                    _ProfileMenuTile(
                      icon: Icons.lock_outline,
                      title: 'Privacy Policy',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),
                    _ProfileMenuTile(
                      icon: Icons.logout,
                      title: 'Log Out',
                      color: _dangerRed,
                      onTap: () => _showLogoutConfirmation(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Agar tinggi dialog menyesuaikan isi
              children: [
                // 1. Ikon Logout Custom (Dibalik agar panahnya ke kiri)
                Transform.flip(
                  flipX: true,
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 64,
                    color: Color(0xFFEF4444), // Warna merah sesuai gambar
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Judul
                const Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Teks Deskripsi
                const Text(
                  'Are you sure you want to log out? You will\nneed to enter your credentials to access your\naccount again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4, // Memberikan jarak antar baris teks
                  ),
                ),
                const SizedBox(height: 32),

                // 4. Tombol Yes, Log Out (Merah)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text(
                      'Yes, Log Out',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 5. Tombol Cancel (Abu-abu)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldLogout != true || !context.mounted) return;

    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;

    // 2. UBAH NAVIGASI: Arahkan ke LoginScreen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = const Color(0xFF202124),
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 26),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}
