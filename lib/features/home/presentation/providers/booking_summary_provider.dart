import 'package:flutter/material.dart';

import '../../../../shared/models/user_model.dart';
import '../../../../shared/network/api_client.dart';

class AddonItem {
  final String id;
  final String name;
  final double pricePerNight;
  final String emoji;
  bool isSelected;

  AddonItem({
    required this.id,
    required this.name,
    required this.pricePerNight,
    required this.emoji,
    this.isSelected = false,
  });
}

class PaymentMethodItem {
  final String id;
  final String name;
  final IconData icon;

  PaymentMethodItem({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class BookingSummaryProvider extends ChangeNotifier {
  BookingSummaryProvider({
    ApiClient? apiClient,
    DateTime? checkIn,
    DateTime? checkOut,
    UserModel? guestUser,
    String? hotelId,
  })  : _apiClient = apiClient ?? ApiClient(),
        checkInDate = checkIn ?? _dateOnly(DateTime.now()),
        checkOutDate =
            checkOut ?? _dateOnly(DateTime.now()).add(const Duration(days: 1)),
        _guestUser = guestUser,
        hotelId = hotelId ?? '';

  final ApiClient _apiClient;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String hotelId;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _lastPaymentId;
  String? get lastPaymentId => _lastPaymentId;

  UserModel? _guestUser;
  UserModel? get guestUser => _guestUser;

  String? get guestErrorMessage {
    if (_guestUser != null) return null;
    return 'Silakan login terlebih dahulu.';
  }

  // Addon list
  final List<AddonItem> addons = [
    AddonItem(
      id: '1',
      name: 'Breakfast',
      pricePerNight: 125000,
      emoji: '🍳',
    ),
    AddonItem(
      id: '2',
      name: 'Massage',
      pricePerNight: 125000,
      emoji: '💆',
    ),
    AddonItem(
      id: '3',
      name: 'Late Checkout (16:00)',
      pricePerNight: 125000,
      emoji: '🕓',
    ),
  ];

  // Payment methods
  final List<PaymentMethodItem> paymentMethods = [
    PaymentMethodItem(id: 'virtual_account', name: 'QRIS', icon: Icons.qr_code),
    PaymentMethodItem(
      id: 'credit_card',
      name: 'Credit Card',
      icon: Icons.credit_card,
    ),
    PaymentMethodItem(id: 'ewallet', name: 'E-Wallet', icon: Icons.wallet),
  ];

  String selectedPaymentMethodId = 'virtual_account';

  // Base booking data (bisa di-inject dari navigasi)
  final double subtotalOrder = 20970134;
  final double serviceFee = 10000;
  final double discount = 0;
  int get jumlahMalam {
    final nights = checkOutDate.difference(checkInDate).inDays;
    return nights <= 0 ? 1 : nights;
  }

  // Hitung total addon
  double get totalAddons => addons
      .where((a) => a.isSelected)
      .fold(0.0, (sum, a) => sum + (a.pricePerNight * jumlahMalam));

  // Hitung total bayar
  double get totalPayment => subtotalOrder + serviceFee - discount + totalAddons;

  // Getter payment method terpilih
  PaymentMethodItem get selectedPaymentMethod => paymentMethods.firstWhere(
        (m) => m.id == selectedPaymentMethodId,
        orElse: () => paymentMethods.first,
      );

  void toggleAddon(int index) {
    addons[index].isSelected = !addons[index].isSelected;
    notifyListeners();
  }

  void selectPaymentMethod(String id) {
    selectedPaymentMethodId = id;
    notifyListeners();
  }

  void updateGuest(UserModel? user) {
    if (_guestUser?.idUser == user?.idUser &&
        _guestUser?.email == user?.email &&
        _guestUser?.noHp == user?.noHp) {
      return;
    }

    _guestUser = user;
    notifyListeners();
  }

  Future<void> submitBookingPayment() async {
    if (_isSubmitting) return;

    _isSubmitting = true;
    notifyListeners();

    try {
      final user = _guestUser;
      if (user == null || user.idUser.isEmpty) {
        throw Exception('Silakan login terlebih dahulu sebelum booking.');
      }

      final booking = await _apiClient.post('/bookings', {
        'id_user': user.idUser,
        if (hotelId.isNotEmpty) 'id_hotel': hotelId,
        'tanggal_booking': _formatDate(DateTime.now()),
        'check_in': _formatDate(checkInDate),
        'check_out': _formatDate(checkOutDate),
        'total_harga': totalPayment,
        'status': 'pending',
      });

      final bookingId = booking['id_booking']?.toString();
      if (bookingId == null || bookingId.isEmpty) {
        throw Exception('ID booking tidak ditemukan dari response Laravel.');
      }

      final payment = await _apiClient.post('/payments', {
        'id_booking': bookingId,
        'metode_pembayaran': selectedPaymentMethodId,
        'jumlah_bayar': totalPayment,
      });

      _lastPaymentId = payment['id_payment']?.toString();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
