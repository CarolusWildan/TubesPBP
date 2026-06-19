/*
|--------------------------------------------------------------------------
| Personal Information Screen
|--------------------------------------------------------------------------
| Tujuan file:
| Menampilkan dan memperbarui data profil personal user: nama, nomor telepon,
| alamat, serta foto profil.
|
| Peran dalam arsitektur:
| PersonalInfoScreen -> AuthProvider.updateProfile()
| -> AuthRepository.updateProfile() -> ApiClient.postMultipart('/profile')
| -> Backend API -> UserModel terbaru -> AuthProvider/secure storage.
|
| Hubungan dengan Authentication dan Profile:
| Screen ini memakai AuthProvider.user sebagai sumber data awal dan menulis
| perubahan kembali ke AuthProvider agar ProfileScreen langsung menampilkan
| data terbaru setelah update berhasil.
|
| Kapan digunakan:
| Dibuka dari menu "Personal Information" di ProfileScreen.
|--------------------------------------------------------------------------
*/

// Tipe File untuk menyimpan foto dari kamera/galeri sebelum upload.
import 'dart:io';

// Komponen Flutter untuk form, avatar, dialog, snackbar, dan navigasi.
import 'package:flutter/material.dart';

// Provider digunakan untuk read/watch AuthProvider.
import 'package:provider/provider.dart';

// ImagePicker membuka kamera atau galeri untuk memilih foto profil.
import 'package:image_picker/image_picker.dart';

// State manager profile/auth yang menjalankan update profile.
import '../../../auth/presentation/providers/auth_provider.dart';

// Dipakai untuk membentuk URL foto profil yang tersimpan di server.
import '../../../../shared/network/api_client.dart';

// Dialog sukses reusable setelah profile berhasil diperbarui.
import '../../../../shared/widgets/confirmation_dialog.dart';

/*
|--------------------------------------------------------------------------
| PersonalInfoScreen
|--------------------------------------------------------------------------
| Tujuan class:
| Widget route untuk mengedit informasi personal user.
|
| Tanggung jawab:
| Menyerahkan lifecycle form dan perubahan foto ke _PersonalInfoScreenState.
|
| Data yang dikelola:
| Tidak ada data langsung di class ini.
|--------------------------------------------------------------------------
*/
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  /*
  |--------------------------------------------------------------------------
  | createState()
  |--------------------------------------------------------------------------
  | Dipanggil Flutter saat screen dimasukkan ke widget tree.
  |
  | Return:
  | _PersonalInfoScreenState yang menyimpan controller form, foto, dan status
  | perubahan.
  |--------------------------------------------------------------------------
  */
  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

/*
|--------------------------------------------------------------------------
| _PersonalInfoScreenState
|--------------------------------------------------------------------------
| Tujuan class:
| Mengelola data awal profile, perubahan form, pemilihan foto, dan proses save.
|
| Tanggung jawab:
| - Membaca user aktif dari AuthProvider saat initState().
| - Membandingkan input terkini dengan data awal.
| - Membuka dialog pilihan foto.
| - Memanggil AuthProvider.updateProfile() saat Save.
|
| Data yang dikelola:
| Controller nama/telepon/alamat, nilai awal pembanding, foto lokal terpilih,
| flag hapus foto, loading lokal, dan flag _hasChanges.
|--------------------------------------------------------------------------
*/
class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  late String _initialName;
  late String _initialPhone;
  late String _initialAddress;

  File? _selectedImageFile;
  bool _isPhotoRemoved = false;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _hasChanges = false;

  static const Color _primaryGreen = Color(0xFF0EA554);
  static const Color _inputBackground = Color(0xFFF8F9FA);

  /*
  |--------------------------------------------------------------------------
  | initState()
  |--------------------------------------------------------------------------
  | Dipanggil sekali oleh Flutter ketika state dibuat.
  |
  | Alur:
  | 1. Membaca AuthProvider.user tanpa subscribe rebuild.
  | 2. Menyimpan nilai awal sebagai pembanding perubahan.
  | 3. Membuat controller dengan nilai profile saat ini.
  | 4. Memasang listener untuk mengaktifkan tombol Save ketika ada perubahan.
  |
  | Efek state:
  | Mengisi controller dan nilai awal profile.
  |--------------------------------------------------------------------------
  */
  @override
  void initState() {
    super.initState();
    final currentUser = context.read<AuthProvider>().user;

    _initialName = currentUser?.fullName ?? '';
    _initialPhone = currentUser?.noHp ?? '';
    _initialAddress = currentUser?.alamat ?? '';

    _nameController = TextEditingController(text: _initialName);
    _phoneController = TextEditingController(text: _initialPhone);
    _addressController = TextEditingController(text: _initialAddress);

    _nameController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    _addressController.addListener(_checkForChanges);
  }

  /*
  |--------------------------------------------------------------------------
  | dispose()
  |--------------------------------------------------------------------------
  | Dipanggil saat user keluar dari screen.
  |
  | Efek state:
  | Melepas listener dan membersihkan controller form.
  |--------------------------------------------------------------------------
  */
  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _phoneController.removeListener(_checkForChanges);
    _addressController.removeListener(_checkForChanges);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | _checkForChanges()
  |--------------------------------------------------------------------------
  | Dipanggil oleh listener controller dan setelah user memilih/menghapus foto.
  |
  | Return:
  | void.
  |
  | Efek state:
  | Mengubah _hasChanges agar tombol Save aktif hanya saat ada perubahan teks
  | atau perubahan foto.
  |--------------------------------------------------------------------------
  */
  void _checkForChanges() {
    final currentName = _nameController.text.trim();
    final currentPhone = _phoneController.text.trim();
    final currentAddress = _addressController.text.trim();

    final isTextChanged =
        currentName != _initialName ||
        currentPhone != _initialPhone ||
        currentAddress != _initialAddress;

    final isPhotoChanged = _selectedImageFile != null || _isPhotoRemoved;
    final isChanged = isTextChanged || isPhotoChanged;

    if (_hasChanges != isChanged) {
      setState(() => _hasChanges = isChanged);
    }
  }

  /*
  |--------------------------------------------------------------------------
  | _getInitials()
  |--------------------------------------------------------------------------
  | Dipanggil build() saat avatar tidak memiliki foto lokal/server.
  |
  | Parameter:
  | - name: nama user.
  |
  | Return:
  | Inisial uppercase atau '?'.
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
  | _showPhotoActionDialog()
  |--------------------------------------------------------------------------
  | Dipanggil ketika user menekan teks "Edit Photo Profile".
  |
  | Event widget:
  | - Take a Photo membuka kamera.
  | - Choose from gallery membuka galeri.
  | - Remove Current Photo menandai foto untuk dihapus di backend.
  |
  | Efek state:
  | Mengubah _selectedImageFile, _isPhotoRemoved, dan _hasChanges.
  |--------------------------------------------------------------------------
  */
  Future<void> _showPhotoActionDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                _buildPhotoActionButton(
                  icon: Icons.camera_alt,
                  label: 'Take a Photo',
                  color: const Color(0xFFE8F5E9),
                  textColor: const Color(0xFF0EA554),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      setState(() {
                        _selectedImageFile = File(image.path);
                        _isPhotoRemoved = false;
                        _checkForChanges();
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildPhotoActionButton(
                  icon: Icons.photo_library,
                  label: 'Choose from gallery',
                  color: const Color(0xFFE3F2FD),
                  textColor: const Color(0xFF1976D2),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() {
                        _selectedImageFile = File(image.path);
                        _isPhotoRemoved = false;
                        _checkForChanges();
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildPhotoActionButton(
                  icon: Icons.delete_outline,
                  label: 'Remove Current Photo',
                  color: const Color(0xFFFFEBEE),
                  textColor: const Color(0xFFD32F2F),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    setState(() {
                      _selectedImageFile = null;
                      _isPhotoRemoved = true;
                      _checkForChanges();
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /*
  |--------------------------------------------------------------------------
  | _buildPhotoActionButton()
  |--------------------------------------------------------------------------
  | Dipanggil oleh _showPhotoActionDialog() untuk membuat opsi aksi foto.
  |
  | Parameter:
  | icon, label, color, textColor, dan onTap menentukan tampilan serta event.
  |
  | Return:
  | Widget InkWell untuk satu aksi foto.
  |--------------------------------------------------------------------------
  */
  Widget _buildPhotoActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | _showSuccessDialog()
  |--------------------------------------------------------------------------
  | Dipanggil setelah AuthProvider.updateProfile() berhasil.
  |
  | Efek state/navigasi:
  | Menampilkan dialog sukses. Tombol "Got it" menutup dialog dan kembali ke
  | ProfileScreen, yang akan membaca AuthProvider.user terbaru.
  |--------------------------------------------------------------------------
  */
  void _showSuccessDialog() {
    final changedPhotoOnly =
        (_selectedImageFile != null || _isPhotoRemoved) &&
        _nameController.text.trim() == _initialName &&
        _phoneController.text.trim() == _initialPhone &&
        _addressController.text.trim() == _initialAddress;

    showSuccessConfirmationDialog(
      context: context,
      title: 'Success',
      message: changedPhotoOnly
          ? 'Your photo profile have been changed successfully'
          : 'Your profile details have been changed successfully',
      buttonText: 'Got it',
      onPressed: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
    );
  }

  /*
  |--------------------------------------------------------------------------
  | _handleSave()
  |--------------------------------------------------------------------------
  | Dipanggil oleh tombol Save ketika _hasChanges true dan _isLoading false.
  |
  | Alur:
  | 1. Validasi nama dan nomor telepon tidak kosong.
  | 2. Menyalakan loading lokal.
  | 3. Memanggil AuthProvider.updateProfile().
  | 4. Provider mengirim POST multipart /profile lewat repository.
  | 5. Jika berhasil, provider memperbarui user dan cache lokal.
  | 6. Menampilkan dialog sukses atau snackbar error.
  |
  | Request API:
  | AuthProvider.updateProfile() -> AuthRepository.updateProfile()
  | -> ApiClient.postMultipart('/profile').
  |
  | Efek state:
  | Mengubah _isLoading lokal dan AuthProvider.user melalui provider.
  |--------------------------------------------------------------------------
  */
  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Call Number must be filled!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        imageFile: _selectedImageFile,
        removeImage: _isPhotoRemoved,
      );

      if (!success) {
        throw Exception(
          authProvider.errorMessage ?? 'Failed to update profile.',
        );
      }

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /*
  |--------------------------------------------------------------------------
  | build()
  |--------------------------------------------------------------------------
  | Dipanggil Flutter untuk merender halaman dan rebuild ketika AuthProvider
  | user berubah.
  |
  | Interaksi state:
  | context.watch<AuthProvider>().user menyediakan data foto/nama terbaru.
  |
  | Event widget:
  | - Back button menutup screen.
  | - Edit Photo Profile membuka dialog foto.
  | - Save memanggil _handleSave().
  |--------------------------------------------------------------------------
  */
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    final String fullName = user?.fullName ?? 'Guest';
    final String initials = _getInitials(fullName);

    final userImage = user?.userImage?.trim();
    final bool hasDatabaseImage = userImage != null && userImage.isNotEmpty;

    ImageProvider? profileImageProvider;
    if (_selectedImageFile != null) {
      profileImageProvider = FileImage(_selectedImageFile!);
    } else if (hasDatabaseImage && !_isPhotoRemoved) {
      // Query timestamp memastikan avatar terbaru dimuat setelah update foto.
      final String fullImageUrl =
          '${ApiClient.serverUrl}/storage/$userImage?v=${DateTime.now().millisecondsSinceEpoch}';
      profileImageProvider = NetworkImage(
        fullImageUrl,
        headers: ApiClient.imageHeaders,
      );
    }

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
          'Personal Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: profileImageProvider,
                        child: profileImageProvider == null
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  color: _primaryGreen,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _isLoading ? null : _showPhotoActionDialog,
                      child: const Text(
                        'Edit Photo Profile',
                        style: TextStyle(
                          color: _primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    _buildCustomTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 24),
                    _buildPhoneTextField(
                      label: 'Call Number',
                      controller: _phoneController,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 24),
                    _buildCustomTextField(
                      label: 'Address',
                      controller: _addressController,
                      enabled: !_isLoading,
                      maxLines: 3, // Fleksibel untuk alamat panjang
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_hasChanges && !_isLoading) ? _handleSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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
  | _buildCustomTextField()
  |--------------------------------------------------------------------------
  | Dipanggil build() untuk field Full Name dan Address.
  |
  | Parameter:
  | - label: teks label field.
  | - controller: controller field.
  | - enabled: false saat proses save berjalan.
  | - maxLines: jumlah baris, dipakai untuk alamat.
  |
  | Return:
  | Widget field teks terlabel.
  |--------------------------------------------------------------------------
  */
  Widget _buildCustomTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF202124),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  /*
  |--------------------------------------------------------------------------
  | _buildPhoneTextField()
  |--------------------------------------------------------------------------
  | Dipanggil build() untuk field Call Number dengan prefix +62.
  |
  | Parameter:
  | - label: teks label field.
  | - controller: controller nomor telepon.
  | - enabled: false saat proses save berjalan.
  |
  | Return:
  | Widget field telepon terlabel.
  |--------------------------------------------------------------------------
  */
  Widget _buildPhoneTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF202124),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _inputBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '+62',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey.shade400),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
