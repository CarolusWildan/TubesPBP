import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  
  // State untuk menyimpan data asli pembanding
  late String _initialName;
  late String _initialPhone;
  late String _initialAddress;
  
  // State manajemen gambar
  File? _selectedImageFile;
  bool _isPhotoRemoved = false;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _hasChanges = false; 

  static const Color _primaryGreen = Color(0xFF0EA554);
  static const Color _inputBackground = Color(0xFFF8F9FA);

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

  void _checkForChanges() {
    final currentName = _nameController.text.trim();
    final currentPhone = _phoneController.text.trim();
    final currentAddress = _addressController.text.trim();
    
    final isTextChanged = currentName != _initialName || 
                          currentPhone != _initialPhone || 
                          currentAddress != _initialAddress;
    
    final isPhotoChanged = _selectedImageFile != null || _isPhotoRemoved;
    final isChanged = isTextChanged || isPhotoChanged;
    
    if (_hasChanges != isChanged) {
      setState(() => _hasChanges = isChanged);
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    List<String> words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  Future<void> _showPhotoActionDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
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
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
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
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
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
                  'Your profile details have been changed successfully',
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
                      Navigator.of(dialogContext).pop(); 
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
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Call Number must be filled!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        imageFile: _selectedImageFile,
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    final String fullName = user?.fullName ?? 'Guest';
    final String initials = _getInitials(fullName);
    
    final bool hasDatabaseImage = user?.userImage != null && user!.userImage!.trim().isNotEmpty;
    
    ImageProvider? profileImageProvider;
    if (_selectedImageFile != null) {
      profileImageProvider = FileImage(_selectedImageFile!);
    } else if (hasDatabaseImage && !_isPhotoRemoved) {
      // 🟢 PEMBARUAN URL DINAMIS STORAGE NGROK
      // Tambahkan ?v= (timestamp) agar Flutter mengabaikan cache lama jika ada pembaruan
final String fullImageUrl = 'https://mortality-emote-creasing.ngrok-free.dev/storage/${user!.userImage!}?v=${DateTime.now().millisecondsSinceEpoch}';
      profileImageProvider = NetworkImage(fullImageUrl);
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- Avatar ---
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200, width: 2),
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
                        style: TextStyle(color: _primaryGreen, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- Form Input ---
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
            
            // --- Tombol Simpan ---
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
    int maxLines = 1,
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
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: _inputBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
          style: const TextStyle(color: Color(0xFF202124), fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: _inputBackground, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('+62', style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              Container(width: 1, height: 24, color: Colors.grey.shade400),
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