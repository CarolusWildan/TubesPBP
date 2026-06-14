import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrTicketWidget extends StatelessWidget {
  final String bookingId; // Data yang akan diubah jadi QR (misal ID Pesanan)

  const QrTicketWidget({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: bookingId, // Ini isi dari QR Code-nya
            version: QrVersions.auto,
            size: 200.0,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            'Scan at Receptionist',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}