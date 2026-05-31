import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/booking_summary_provider.dart';
import '../../../../shared/models/hotel_model.dart';
import '../../../../shared/network/api_client.dart';
import '../../../../shared/widgets/addon_section.dart';
import '../../../../shared/widgets/guest_info.dart';
import '../../../../shared/widgets/payment_detail_section.dart';
import '../../../../shared/widgets/payment_method_section.dart';
import '../../../../shared/widgets/room_info_card.dart';
import '../../../../shared/widgets/trip_info.dart';

class BookingSummaryScreen extends StatelessWidget {
  final HotelModel? hotel;
  final DateTime? checkIn;
  final DateTime? checkOut;

  const BookingSummaryScreen({
    super.key,
    this.hotel,
    this.checkIn,
    this.checkOut,
  });

  String _formatRupiah(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  String _resolveImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400';
    }

    final imagePath = value.trim();
    final uri = Uri.tryParse(imagePath);
    if (uri != null && uri.hasScheme) return imagePath;

    final serverUrl = ApiClient.baseUrl.replaceFirst('/api', '');
    if (imagePath.startsWith('/')) return '$serverUrl$imagePath';
    return '$serverUrl/storage/$imagePath';
  }

  String _roomSubtitle(HotelModel? hotel) {
    if (hotel == null) return 'Room details belum tersedia';
    if (hotel.facilityNames.isNotEmpty) {
      return hotel.facilityNames.take(2).join(' - ');
    }
    if (hotel.kota.trim().isNotEmpty) return hotel.kota;
    return 'Room details belum tersedia';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingSummaryProvider(
        apiClient: context.read<ApiClient>(),
        checkIn: checkIn,
        checkOut: checkOut,
        guestUser: context.read<AuthProvider>().user,
        hotelId: hotel?.idHotel,
      ),
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
              RoomInfoCard(
                hotelName: hotel?.namaHotel ?? 'Hotel belum dipilih',
                roomType: _roomSubtitle(hotel),
                rating: hotel?.rating ?? 0,
                imageUrl: _resolveImageUrl(hotel?.hotelImage),
              ),
              const SizedBox(height: 12),
              Consumer<BookingSummaryProvider>(
                builder: (context, provider, _) {
                  return TripInfoSection(
                    checkIn: provider.checkInDate,
                    checkOut: provider.checkOutDate,
                    jumlahMalam: provider.jumlahMalam,
                  );
                },
              ),
              const SizedBox(height: 12),
              const AddonSection(),
              const SizedBox(height: 12),
              Consumer<BookingSummaryProvider>(
                builder: (context, provider, _) {
                  final guest = provider.guestUser;

                  if (guest == null) {
                    return GuestInfoSection(
                      name: 'Data tamu belum tersedia',
                      email: provider.guestErrorMessage ?? '-',
                      phone: '-',
                    );
                  }

                  return GuestInfoSection(
                    name: guest.nama,
                    email: guest.email,
                    phone: guest.noHp ?? '-',
                  );
                },
              ),
              const SizedBox(height: 12),
              const PaymentMethodSection(),
              const SizedBox(height: 12),
              const PaymentDetailSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
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
                        SizedBox(
                          width: 180,
                          child: ElevatedButton(
                            onPressed: provider.isSubmitting
                                ? null
                                : () => _handlePayNow(context, provider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: provider.isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
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

  Future<void> _handlePayNow(
    BuildContext context,
    BookingSummaryProvider provider,
  ) async {
    try {
      await provider.submitBookingPayment();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.lastPaymentId == null
                ? 'Booking berhasil dibuat.'
                : 'Booking dan pembayaran berhasil dibuat.',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}
