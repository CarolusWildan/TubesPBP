import 'package:flutter/material.dart';

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
  BookingSummaryProvider({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _lastPaymentId;
  String? get lastPaymentId => _lastPaymentId;

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
    PaymentMethodItem(id: 'virtual_account', name: 'Qris', icon: Icons.qr_code),
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
  final int jumlahMalam = 2;

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

  Future<void> submitBookingPayment() async {
    if (_isSubmitting) return;

    _isSubmitting = true;
    notifyListeners();

    try {
      final userId = await _getOrCreateDemoUserId();
      final booking = await _apiClient.post('/bookings', {
        'id_user': userId,
        'tanggal_booking': _formatDate(DateTime.now()),
        'check_in': '2024-11-15',
        'check_out': '2024-11-17',
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

  Future<String> _getOrCreateDemoUserId() async {
    final usersResponse = await _apiClient.get('/users');
    final List users;
    if (usersResponse is List) {
      users = usersResponse;
    } else if (usersResponse is Map<String, dynamic> &&
        usersResponse['data'] is List) {
      users = usersResponse['data'] as List;
    } else {
      users = const [];
    }

    if (users.isEmpty) {
      final user = await _apiClient.post('/users', {
        'nama': 'Vinsensius Devando Febrilian',
        'email': 'devangaming@gmail.com',
        'password': 'Password123',
        'no_hp': '08123456789',
        'alamat': 'Yogyakarta',
      });

      final userId = user['id_user']?.toString();
      if (userId == null || userId.isEmpty) {
        throw Exception('Gagal membuat user demo untuk booking.');
      }

      return userId;
    }

    final firstUser = users.first;
    if (firstUser is! Map<String, dynamic>) {
      throw Exception('Format data user dari Laravel tidak sesuai.');
    }

    final userId = firstUser['id_user']?.toString();
    if (userId == null || userId.isEmpty) {
      throw Exception('Field id_user tidak ditemukan dari data user Laravel.');
    }

    return userId;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
