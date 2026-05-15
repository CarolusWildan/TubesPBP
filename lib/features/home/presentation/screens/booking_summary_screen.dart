import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/booking_summary_provider.dart';
import '../../../../shared/widgets/addon_section.dart';
import '../../../../shared/widgets/guest_info.dart';
import '../../../../shared/widgets/payment_detail_section.dart';
import '../../../../shared/widgets/payment_method_section.dart';
import '../../../../shared/widgets/room_info_card.dart';
import '../../../../shared/widgets/trip_info.dart';

class BookingSummaryScreen extends StatelessWidget {
  const BookingSummaryScreen({super.key});

  String _formatRupiah(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingSummaryProvider(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          title: const Text(
            'Booking Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 1. Info kamar
              RoomInfoCard(
                hotelName: 'Capella Ubud, Bali',
                roomType: '1 Bedroom Villa • 1 King Bed',
                rating: 4.9,
                imageUrl:
                    'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400',
              ),
              const SizedBox(height: 12),

              // 2. Info trip
              TripInfoSection(
                checkIn: DateTime(2024, 11, 15),
                checkOut: DateTime(2024, 11, 17),
                jumlahMalam: 2,
              ),
              const SizedBox(height: 12),

              // 3. Addon / Enhance Your Stay
              const AddonSection(),
              const SizedBox(height: 12),

              // 4. Guest information
              const GuestInfoSection(
                name: 'Vinsensius Devando Febrilian',
                email: 'devangaming@gmail.com',
                phone: '08123456789',
              ),
              const SizedBox(height: 12),

              // 5. Payment method
              const PaymentMethodSection(),
              const SizedBox(height: 12),

              // 6. Payment detail
              const PaymentDetailSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Bottom bar: total + tombol Pay Now
        bottomNavigationBar: Consumer<BookingSummaryProvider>(
          builder: (context, provider, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Row mengikuti ukuran isi
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Total
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              'Rp ${_formatRupiah(provider.totalPayment)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        // Tombol Pay Now
                        SizedBox(
                          width: 180,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: navigasi ke halaman pembayaran
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Pay Now',
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}