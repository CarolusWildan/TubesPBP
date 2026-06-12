import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  
  // Variabel untuk menyimpan data asli
  late String _initialName;
  late String _initialPhone;
  
  bool _isLoading = false;
  bool _hasChanges = false; // Status untuk memantau apakah ada perubahan ketikan

  static const Color _primaryGreen = Color(0xFF0EA554);
  static const Color _inputBackground = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    
    final currentUser = context.read<AuthProvider>().user;

    // Simpan data asli sebagai titik perbandingan
    _initialName = currentUser?.fullName ?? '';
    _initialPhone = currentUser?.noHp ?? '';

    _nameController = TextEditingController(text: _initialName);
    _phoneController = TextEditingController(text: _initialPhone);

    // Pasang listener untuk mengecek perubahan setiap kali user mengetik
    _nameController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _phoneController.removeListener(_checkForChanges);
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Fungsi untuk membandingkan input saat ini dengan data awal
  void _checkForChanges() {
    final currentName = _nameController.text.trim();
    final currentPhone = _phoneController.text.trim();
    
    final isChanged = currentName != _initialName || currentPhone != _initialPhone;
    
    // Update state hanya jika status perubahannya berbeda untuk menghindari render berlebih
    if (_hasChanges != isChanged) {
      setState(() {
        _hasChanges = isChanged;
      });
    }
  }

  // Fungsi untuk mengekstrak inisial nama (Maksimal 2 huruf)
  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    
    List<String> words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua bidang harus diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui profil: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    final bool hasProfilePic = user?.userImage != null && user!.userImage!.trim().isNotEmpty;
    final String fullName = user?.fullName ?? 'Guest';
    final String initials = _getInitials(fullName);

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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- Bagian Foto Profil Dinamis ---
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200, width: 2), // Garis tepi agar tidak menyatu dengan background putih
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: hasProfilePic ? NetworkImage(user.userImage!) : null, //NetworkImage(user!.userImage!)
                        child: !hasProfilePic
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
                      onTap: _isLoading ? null : () {
                        // Logika untuk upload/ganti foto ke storage & DB
                      },
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

                    // --- Bagian Form Input ---
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
                  ],
                ),
              ),
            ),
            
            // --- Tombol Simpan ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  // Logika Utama: Tombol menyala JIKA ada perubahan DAN sedang tidak loading
                  onPressed: (_hasChanges && !_isLoading) ? _handleSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen, 
                    // Konfigurasi warna saat tombol didisable (null onPressed)
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

  Widget _buildCustomTextField({
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
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

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
              Container(
                width: 1,
                height: 24,
                color: Colors.grey.shade400,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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