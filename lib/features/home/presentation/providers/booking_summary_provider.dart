import 'package:flutter/material.dart';

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
    PaymentMethodItem(id: 'qris', name: 'Qris', icon: Icons.qr_code),
    PaymentMethodItem(id: 'transfer', name: 'Transfer', icon: Icons.account_balance),
    PaymentMethodItem(id: 'ewallet', name: 'E-Wallet', icon: Icons.wallet),
  ];

  String selectedPaymentMethodId = 'qris';

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
}