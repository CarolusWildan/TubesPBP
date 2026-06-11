import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/booking_history_model.dart';
import '../network/api_client.dart';

class HistoryBookingCard extends StatelessWidget {
  final BookingHistoryModel booking;
  final VoidCallback? onTap;

  const HistoryBookingCard({super.key, required this.booking, this.onTap});

  String get _safeImageUrl {
    final cleanedUrl = booking.imageUrl.trim().replaceAll('\\', '/');
    if (cleanedUrl.isEmpty) {
      return 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400';
    }
    return Uri.encodeFull(cleanedUrl);
  }

  bool get _isPending =>
      booking.paymentStatus.toLowerCase().contains('pending');

  bool get _isCancel => booking.paymentStatus.toLowerCase().contains('cancel');

  String _formatDateRange() {
    final start = DateFormat('d').format(booking.checkIn);
    final end = DateFormat('d MMM yyyy').format(booking.checkOut);
    return '$start - $end';
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final statusBackground = _isPending
        ? const Color(0xFFFFF0DF)
        : _isCancel
        ? const Color(0xFFFFE9E6)
        : const Color(0xFFE7F8EE);
    final statusColor = _isPending
        ? const Color(0xFFFF8A00)
        : _isCancel
        ? const Color(0xFFE53935)
        : const Color(0xFF0EA554);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ID: ${booking.idPayment}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  StatusPill(
                    label: booking.paymentStatus,
                    backgroundColor: statusBackground,
                    textColor: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: HistoryHotelImage(
                      imageUrl: _safeImageUrl,
                      width: 56,
                      height: 56,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.hotelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatDateRange(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatRupiah(booking.totalPayment),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0EA554),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 36),
                      child: StatusPill(
                        label: booking.reviewStatus,
                        backgroundColor: const Color(0xFFFFF0DF),
                        textColor: const Color(0xFFFF6B3A),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryHotelImage extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;

  const HistoryHotelImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  @override
  State<HistoryHotelImage> createState() => _HistoryHotelImageState();
}

class _HistoryHotelImageState extends State<HistoryHotelImage> {
  late Future<Uint8List?> _imageBytesFuture;

  @override
  void initState() {
    super.initState();
    _imageBytesFuture = _loadImageBytes();
  }

  @override
  void didUpdateWidget(covariant HistoryHotelImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageBytesFuture = _loadImageBytes();
    }
  }

  Future<Uint8List?> _loadImageBytes() async {
    final uri = Uri.tryParse(widget.imageUrl);
    if (uri == null || !uri.hasScheme) return null;

    try {
      final response = await http.get(uri, headers: ApiClient.imageHeaders);
      final contentType = response.headers['content-type'] ?? '';
      final isImage = contentType.startsWith('image/');

      if (response.statusCode >= 200 && response.statusCode < 300 && isImage) {
        return response.bodyBytes;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _imageBytesFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null) {
          return Image.memory(
            bytes,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey.shade100,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          );
        }

        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.hotel, color: Colors.grey, size: 22),
        );
      },
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const StatusPill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
