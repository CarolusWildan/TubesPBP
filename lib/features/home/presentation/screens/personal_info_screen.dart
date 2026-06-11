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
  bool _isLoading = false; // Untuk menangani state saat menyimpan data ke DB

  static const Color _primaryGreen = Color(0xFF0EA554);
  static const Color _inputBackground = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    
    // Mengambil data user saat ini dari AuthProvider tanpa merender ulang (listen: false / context.read)
    // Aman digunakan di dalam initState
    final currentUser = context.read<AuthProvider>().user;

    // Inisialisasi controller dengan data asli dari database/provider
    _nameController = TextEditingController(text: currentUser?.fullName ?? '');
    
    // Asumsi properti di model user Anda adalah 'phone' atau 'callNumber'
    _phoneController = TextEditingController(text: currentUser?.noHp ?? ''); 
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    // Validasi dasar sebelum menembak ke database
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua bidang harus diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Panggil fungsi update dari AuthProvider Anda
      // Asumsi di AuthProvider ada fungsi untuk update data ke database/API
      await context.read<AuthProvider>().updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
      Navigator.pop(context); // Kembali ke halaman profil setelah sukses
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
    // Gunakan context.watch jika Anda ingin UI ini responsif terhadap perubahan data user secara real-time
    final user = context.watch<AuthProvider>().user;
    
    // Fallback URL jika user belum memiliki foto profil di database
    final profilePicture = user?.userImage != null && user!.userImage!.isNotEmpty
        ? NetworkImage(user.userImage!)
        : const NetworkImage('https://i.pravatar.cc/200?img=12') as ImageProvider;

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
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profilePicture,
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
            
            // --- Tombol Simpan dengan State Loading ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    // Jika loading, warna tombol berubah otomatis menjadi abu-abu bawaan disabled
                    backgroundColor: _primaryGreen, 
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
                            color: Colors.white,
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