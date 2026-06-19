import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';

// Sesuaikan path import ini jika letak file model & api client Anda berbeda
import '../../../../shared/models/booking_history_model.dart';
import '../../../../shared/network/api_client.dart';

class ReviewScreen extends StatefulWidget {
  final BookingHistoryModel booking;

  const ReviewScreen({super.key, required this.booking});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final List<File> _selectedMedias = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => widget.booking.reviewId?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    _rating = widget.booking.reviewRating;
    _reviewController.text = widget.booking.reviewComment ?? '';
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final dateFormat = DateFormat('d MMM');
    final yearFormat = DateFormat('yyyy');

    if (start.year == end.year) {
      return '${dateFormat.format(start)} - ${dateFormat.format(end)} ${yearFormat.format(start)}';
    }
    return '${DateFormat('d MMM yyyy').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
  }

  Future<void> _pickMedia(ImageSource source) async {
    Navigator.pop(context); // Tutup bottom sheet

    try {
      if (source == ImageSource.gallery) {
        // Ambil banyak foto sekaligus
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() {
            _selectedMedias.addAll(images.map((img) => File(img.path)));
          });
        }
      } else {
        // Ambil 1 foto dari kamera
        final XFile? photo = await _picker.pickImage(source: source);
        if (photo != null) {
          setState(() {
            _selectedMedias.add(File(photo.path));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
      }
    }
  }

  void _showMediaPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Photo or Video',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MediaOptionBtn(
                    icon: Icons.camera_alt,
                    title: 'Take a Photo',
                    bgColor: const Color(0xFFE5F5EC),
                    iconColor: const Color(0xFF0EA554),
                    onTap: () => _pickMedia(ImageSource.camera),
                  ),
                  _MediaOptionBtn(
                    icon: Icons.photo_library,
                    title: 'Gallery',
                    bgColor: const Color(0xFFEAF4FF),
                    iconColor: Colors.blue,
                    onTap: () => _pickMedia(ImageSource.gallery),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating first.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final storageService = LocalStorageService();
      final apiClient = ApiClient(storageService: storageService);

      final fields = {
        'id_user': widget.booking.userId ?? '',
        'id_booking': widget.booking.bookingId ?? '',
        'id_hotel': widget.booking.hotelId ?? 'HTL001',
        'rating': _rating.toString(),
        'komentar': _reviewController.text,
      };

      if (_isEditing) {
        await apiClient.putMultipartMultiple(
          '/reviews/${widget.booking.reviewId}',
          fields,
          files: _selectedMedias,
        );
      } else {
        await apiClient.postMultipartMultiple(
          '/reviews',
          fields,
          files: _selectedMedias,
        );
      }

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showSuccessConfirmationDialog(
      context: context,
      title: 'Success',
      message: _isEditing
          ? 'Your review has been updated successfully'
          : 'Your review has been saved successfully',
      buttonText: 'Continue',
      onPressed: () {
        Navigator.pop(context);
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isButtonActive = _rating > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Column(
        children: [
          // Header Hijau
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 84),
            decoration: const BoxDecoration(
              color: const Color(0xFF0EA554),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.22),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isEditing ? 'Update Review' : widget.booking.hotelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -56),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Hotel Info
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.booking.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.booking.hotelName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.booking.location,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stayed on ${_formatDateRange(widget.booking.checkIn, widget.booking.checkOut)}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Rating Section
                      const Text(
                        'HOW WAS YOUR EXPERIENCE?',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () => setState(() => _rating = index + 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Icon(
                                index < _rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: index < _rating
                                    ? const Color(0xFFFFB800)
                                    : Colors.grey.shade300,
                                size: 42,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a rating',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Text Review Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            text: 'Review Details ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: '(Optional)',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reviewController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Share your stay experience...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: const Color(0xFF0EA554),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Upload Media Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            text: 'Photo or Video ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: '(Optional)',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Grid Selected Images + Tombol Add
                      if (_selectedMedias.isNotEmpty)
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedMedias.length + 1,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              // Tombol Add (+) di akhir list
                              if (index == _selectedMedias.length) {
                                return GestureDetector(
                                  onTap: _showMediaPickerBottomSheet,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5F5EC),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Color(0xFF0EA554),
                                      size: 30,
                                    ),
                                  ),
                                );
                              }

                              // Item Gambar
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedMedias[index],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedMedias.removeAt(index),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        )
                      else
                        // Tampilan Awal (Belum ada gambar)
                        GestureDetector(
                          onTap: _showMediaPickerBottomSheet,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5F5EC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  color: const Color(0xFF0EA554),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add a photo or video',
                                  style: TextStyle(
                                    color: Color(0xFF0EA554),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),

                      // Tombol Submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isButtonActive && !_isLoading
                              ? _submitReview
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA554),
                            disabledBackgroundColor: Colors.grey.shade300,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isEditing
                                      ? 'Update Review'
                                      : 'Submit Review',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: isButtonActive
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaOptionBtn extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _MediaOptionBtn({
    required this.icon,
    required this.title,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
