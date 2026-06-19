/*
|--------------------------------------------------------------------------
| Profile Screen
|--------------------------------------------------------------------------
| Tujuan file:
| Menampilkan ringkasan akun user, menu pengaturan akun, dan flow logout.
|
| Peran dalam arsitektur:
| ProfileScreen berada di UI Layer. Data user dibaca dari AuthProvider, yang
| sebelumnya menerima data dari AuthRepository dan LocalStorageService.
|
| Hubungan dengan Authentication/Profile:
| - Menampilkan nama, email, dan foto dari AuthProvider.user.
| - Membuka PersonalInfoScreen untuk update profil.
| - Membuka PrivacyPolicyScreen untuk update email/password.
| - Memanggil AuthProvider.logout() untuk menghapus sesi.
|
| Kapan digunakan:
| Ditampilkan sebagai salah satu tab MainScreen setelah user authenticated.
|
| Diagram logout:
| ProfileScreen
| -> _showLogoutConfirmation()
| -> AuthProvider.logout()
| -> AuthRepository.logout()
| -> ApiClient.post('/logout')
| -> LocalStorageService.deleteToken/deleteUser
| -> AuthProvider.user = null
| -> Navigator.pushAndRemoveUntil(LoginScreen)
|--------------------------------------------------------------------------
*/

// Komponen Flutter untuk layout profile, dialog, icon, dan navigasi.
import 'package:flutter/material.dart';

// Provider digunakan untuk watch/read AuthProvider.
import 'package:provider/provider.dart';

// State auth/profile yang menyimpan user aktif dan menjalankan logout.
import '../../../auth/presentation/providers/auth_provider.dart';

// Route tujuan setelah logout berhasil dan navigation stack dibersihkan.
import '../../../auth/presentation/screens/login_screen.dart';

// Dipakai untuk membentuk URL foto profil dari server storage.
import '../../../../shared/network/api_client.dart';

// Halaman detail profile untuk mengubah nama, telepon, alamat, dan foto.
import 'personal_info_screen.dart';

// Halaman privacy untuk mengubah email dan password.
import 'privacy_policy_screen.dart';

/*
|--------------------------------------------------------------------------
| ProfileScreen
|--------------------------------------------------------------------------
| Tujuan class:
| Widget halaman profil yang menampilkan data user dan menu akun.
|
| Tanggung jawab:
| - Membaca AuthProvider.user.
| - Menentukan avatar dari foto server atau inisial nama.
| - Menyediakan navigasi ke Personal Information dan Privacy Policy.
| - Mengelola konfirmasi dan eksekusi logout.
|
| Hubungan class:
| Menggunakan AuthProvider, ApiClient, LoginScreen, PersonalInfoScreen,
| PrivacyPolicyScreen, dan _ProfileMenuTile.
|
| Data yang dikelola:
| Stateless; data berasal dari AuthProvider dan computed value lokal.
|--------------------------------------------------------------------------
*/
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _primaryGreen = Color(0xFF0EA554);
  static const Color _pageBackground = Color(0xFFF8F9FA);
  static const Color _dangerRed = Color(0xFFFF3B30);

  /*
  |--------------------------------------------------------------------------
  | _getInitials()
  |--------------------------------------------------------------------------
  | Dipanggil oleh build() saat user tidak memiliki foto profil.
  |
  | Parameter:
  | - name: nama user yang akan diubah menjadi satu/dua huruf inisial.
  |
  | Return:
  | Inisial uppercase, atau '?' jika nama kosong.
  |
  | Efek state:
  | Tidak ada; helper murni untuk tampilan avatar.
  |--------------------------------------------------------------------------
  */
  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    List<String> words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  /*
  |--------------------------------------------------------------------------
  | build()
  |--------------------------------------------------------------------------
  | Dipanggil Flutter untuk menampilkan halaman profile dan rebuild saat
  | AuthProvider.notifyListeners() berjalan.
  |
  | Interaksi state:
  | context.watch<AuthProvider>() membaca UserModel aktif. Perubahan dari
  | updateProfile/updatePrivacy akan langsung memperbarui nama, email, foto.
  |
  | Event widget:
  | - Tile Personal Information -> Navigator.push(PersonalInfoScreen).
  | - Tile Privacy Policy -> Navigator.push(PrivacyPolicyScreen).
  | - Tile Log Out -> _showLogoutConfirmation().
  |
  | Navigasi:
  | Logout sukses -> pushAndRemoveUntil(LoginScreen).
  |--------------------------------------------------------------------------
  */
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

    final bool hasDatabaseImage =
        user?.userImage != null && user!.userImage!.trim().isNotEmpty;
    final String initials = _getInitials(displayName);

    ImageProvider? profileImageProvider;
    if (hasDatabaseImage) {
      final String fullImageUrl =
          '${ApiClient.serverUrl}/storage/${user.userImage!}?v=${DateTime.now().millisecondsSinceEpoch}';
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
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
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

  /*
  |--------------------------------------------------------------------------
  | _showLogoutConfirmation()
  |--------------------------------------------------------------------------
  | Dipanggil ketika user mengetuk menu Log Out.
  |
  | Parameter:
  | - context: BuildContext ProfileScreen untuk dialog, provider, dan navigasi.
  |
  | Return:
  | Future<void> setelah dialog ditutup dan logout selesai jika dikonfirmasi.
  |
  | Efek state:
  | Jika user memilih "Yes, Log Out", method ini memanggil AuthProvider.logout()
  | yang menghapus token, cache user, dan _user. Setelah itu stack navigasi
  | diganti dengan LoginScreen.
  |--------------------------------------------------------------------------
  */
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.flip(
                  flipX: true,
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 64,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to log out? You will\nneed to enter your credentials to access your\naccount again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
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

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

/*
|--------------------------------------------------------------------------
| _ProfileMenuTile
|--------------------------------------------------------------------------
| Tujuan class:
| Widget reusable untuk item menu pada ProfileScreen.
|
| Tanggung jawab:
| Menampilkan icon, label, warna status, dan chevron, lalu menjalankan onTap.
|
| Data yang dikelola:
| icon, title, onTap, dan color diterima dari ProfileScreen.
|--------------------------------------------------------------------------
*/
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

  /*
  |--------------------------------------------------------------------------
  | build()
  |--------------------------------------------------------------------------
  | Dipanggil Flutter saat menu tile dirender.
  |
  | Event widget:
  | InkWell.onTap menjalankan callback dari ProfileScreen untuk navigasi atau
  | logout confirmation.
  |--------------------------------------------------------------------------
  */
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
