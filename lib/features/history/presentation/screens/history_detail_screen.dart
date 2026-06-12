import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'review_screen.dart';

import '../../../../shared/models/booking_history_model.dart';
import '../../../booking/presentation/screens/payment_instruction_screen.dart';
import '../widgets/history_booking_card.dart';


class HistoryDetailScreen extends StatelessWidget {
  final BookingHistoryModel booking;

  const HistoryDetailScreen({super.key, required this.booking});

  String get _title => booking.hotelName;

  Color get _statusColor =>
      booking.isSuccess ? const Color(0xFF0EA554) : const Color(0xFFFF8A00);

  IconData get _statusIcon =>
      booking.isSuccess ? Icons.check_circle : Icons.pending_actions;

  String get _statusLabel => booking.isSuccess ? 'Success' : 'Pending';

  String _formatDate(DateTime date) {
    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _roomSummary() {
    final nights = booking.checkOut.difference(booking.checkIn).inDays;
    final safeNights = nights <= 0 ? 1 : nights;
    return '$safeNights Night${safeNights == 1 ? '' : 's'}';
  }

  String _paymentMethodId() {
    final method = booking.paymentMethod.toLowerCase();
    if (method.contains('credit')) return 'credit_card';
    if (method.contains('wallet')) return 'ewallet';
    if (method.contains('virtual')) return 'virtual_account';
    return 'qris';
  }

  void _openPayment(BuildContext context) {
    final nights = booking.checkOut.difference(booking.checkIn).inDays;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentInstructionScreen(
          hotelName: booking.hotelName,
          roomType: booking.location,
          rating: 0,
          imageUrl: booking.imageUrl,
          checkIn: booking.checkIn,
          checkOut: booking.checkOut,
          jumlahMalam: nights <= 0 ? 1 : nights,
          paymentMethodId: _paymentMethodId(),
          paymentMethodName: booking.paymentMethod,
          paymentId: booking.idPayment, // 🔴 Menggunakan idPayment berformat PAY00X dari DB
          totalPayment: booking.totalPayment,
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature belum tersedia.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 84),
            decoration: const BoxDecoration(
              color: Color(0xFF0EA554),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.22), // Standarisasi opacity lawas/baru
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _title,
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
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(_statusIcon, color: _statusColor, size: 34),
                      const SizedBox(height: 4),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        booking.isSuccess
                            ? 'Your payment has been completed'
                            : 'Pay now to complete transaction',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 22),
                      
                      // 🔴 BAGIAN UTAMA CARD: Menampilkan id_payment berformat PAY002
                      _DetailRow(
                        label: 'ID Order', 
                        value: booking.idPayment ?? "-", // Menampilkan PAY00X dari database Anda
                      ),
                      
                      _DetailRow(
                        label: 'Paid',
                        value: _formatDate(booking.checkIn),
                      ),
                      _DetailRow(
                        label: 'Payment Method',
                        value: booking.paymentMethod,
                      ),
                      _DetailRow(
                        label: 'Price',
                        value: _formatRupiah(booking.totalPayment),
                        isBold: true,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: HistoryHotelImage(
                              imageUrl: booking.imageUrl,
                              width: 54,
                              height: 54,
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
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _roomSummary(),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            '1x',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      if (booking.isPending) ...[
                        _DetailButton(
                          label: 'Cancel Booking',
                          backgroundColor: const Color(0xFFFFCDD2),
                          foregroundColor: Colors.red,
                          onPressed: () =>
                              _showComingSoon(context, 'Cancel booking'),
                        ),
                        const SizedBox(height: 10),
                        _DetailButton(
                          label: 'Pay Now',
                          backgroundColor: const Color(0xFF0EA554),
                          foregroundColor: Colors.white,
                          onPressed: () => _openPayment(context),
                        ),
                      ] else ...[
                        _DetailButton(
                          label: 'Invoice PDF',
                          backgroundColor: const Color(0xFFCDEFE0),
                          foregroundColor: const Color(0xFF0EA554),
                          onPressed: () =>
                              _showComingSoon(context, 'Invoice PDF'),
                        ),
                        if (booking.needsReview) ...[
                          const SizedBox(height: 10),
                          // 🟢 PERUBAHAN NAVIGASI KE REVIEW SCREEN DI SINI 🟢
                          _DetailButton(
                            label: 'Review',
                            backgroundColor: const Color(0xFF0EA554),
                            foregroundColor: Colors.white,
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReviewScreen(booking: booking),
                                ),
                              );

                              // Jika user selesai review (kembali dengan nilai true)
                              // Otomatis refresh data di halaman History
                              if (result == true && context.mounted) {
                                Navigator.pop(context, true);
                              }
                            },
                          ),
                        ],
                      ],
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.black87,
                fontSize: isBold ? 13 : 11,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  const _DetailButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}