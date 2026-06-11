import 'package:flutter/material.dart';

import '../../../../shared/models/room_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/network/api_client.dart';

class AddonItem {
  final String id;
  final String name;
  final double pricePerNight;
  bool isSelected;
  int quantity;

  AddonItem({
    required this.id,
    required this.name,
    required this.pricePerNight,
    this.isSelected = false,
    this.quantity = 0,
  });

  bool get isPerPax => id == '1' || id == '2' || id == '4';

  IconData get icon {
    switch (id) {
      case '1':
        return Icons.local_taxi_outlined;
      case '2':
        return Icons.spa_outlined;
      case '3':
        return Icons.schedule_outlined;
      case '4':
        return Icons.map_outlined;
      default:
        return Icons.add_circle_outline;
    }
  }
}

class PaymentMethodItem {
  final String id;
  final String name;
  final IconData icon;

  PaymentMethodItem({required this.id, required this.name, required this.icon});
}

class BookingSummaryProvider extends ChangeNotifier {
  BookingSummaryProvider({
    ApiClient? apiClient,
    DateTime? checkIn,
    DateTime? checkOut,
    UserModel? guestUser,
    String? hotelId,
    String? roomId, // Menerima lemparan ID Kamar bertipe String (varchar)
  }) : _apiClient = apiClient ?? ApiClient(),
       checkInDate = checkIn ?? _dateOnly(DateTime.now()),
       checkOutDate = checkOut ?? _dateOnly(DateTime.now()).add(const Duration(days: 1)),
       _guestUser = guestUser,
       hotelId = hotelId ?? '',
       _injectedRoomId = roomId;

  final ApiClient _apiClient;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String hotelId;
  final String? _injectedRoomId; 

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
    AddonItem(id: '1', name: 'Airport Transfer', pricePerNight: 50000),
    AddonItem(id: '2', name: 'Massage', pricePerNight: 100000),
    AddonItem(id: '3', name: 'Late Checkout', pricePerNight: 125000),
    AddonItem(id: '4', name: 'Tour Domestic', pricePerNight: 80000),
  ];

  // Payment methods (ID disesuaikan dengan nilai konstanta model Laravel Anda)
  final List<PaymentMethodItem> paymentMethods = [
    PaymentMethodItem(id: 'qris', name: 'QRIS', icon: Icons.qr_code),
    PaymentMethodItem(id: 'credit_card', name: 'Credit Card', icon: Icons.credit_card),
    PaymentMethodItem(id: 'ewallet', name: 'E-Wallet', icon: Icons.wallet),
  ];

  String selectedPaymentMethodId = 'qris';

  // Base booking data
  final double subtotalOrder = 20970134;
  final double serviceFee = 10000;
  final double discount = 0;

  int get jumlahMalam {
    final nights = checkOutDate.difference(checkInDate).inDays;
    return nights <= 0 ? 1 : nights;
  }

  double get totalAddons => addons.fold(0.0, (sum, addon) {
    if (addon.isPerPax) {
      return sum + (addon.pricePerNight * jumlahMalam * addon.quantity);
    }
    if (addon.isSelected) {
      return sum + (addon.pricePerNight * jumlahMalam);
    }
    return sum;
  });

  double get totalPayment => subtotalOrder + serviceFee - discount + totalAddons;

  PaymentMethodItem get selectedPaymentMethod => paymentMethods.firstWhere(
    (m) => m.id == selectedPaymentMethodId,
    orElse: () => paymentMethods.first,
  );

  void toggleAddon(int index) {
    addons[index].isSelected = !addons[index].isSelected;
    notifyListeners();
  }

  void increaseAddonQuantity(int index) {
    final addon = addons[index];
    if (!addon.isPerPax) return;
    addon.quantity++;
    notifyListeners();
  }

  void decreaseAddonQuantity(int index) {
    final addon = addons[index];
    if (!addon.isPerPax || addon.quantity == 0) return;
    addon.quantity--;
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

      // Evaluasi data ID Room
      String finalRoomId = _injectedRoomId ?? '';
      int roomCapacity = 2;
      double roomPrice = subtotalOrder / jumlahMalam;

      if (finalRoomId.isEmpty) {
        final room = await _loadAvailableRoom();
        finalRoomId = room.idRoom;
        roomCapacity = room.capacity;
        if (room.pricePerNight > 0) {
          roomPrice = room.pricePerNight;
        }
      }

      final roomSubtotal = roomPrice * jumlahMalam;

      // 1. Hit API POST /api/bookings
      final booking = await _apiClient.post('/bookings', {
        'id_user': user.idUser,
        if (hotelId.isNotEmpty) 'id_hotel': hotelId,
        'id_room': finalRoomId,
        'tanggal_booking': _formatDate(DateTime.now()),
        'check_in': _formatDate(checkInDate),
        'check_out': _formatDate(checkOutDate),
        'harga_per_malam': roomPrice,
        'harga': roomPrice,
        'jumlah_kamar': 1,
        'jumlah_tamu': roomCapacity,
        'jumlah_malam': jumlahMalam,
        'subtotal': roomSubtotal,
        'subtotal_harga': roomSubtotal,
        'total_harga': totalPayment,
        'status': 'pending',
        'metode_pembayaran': selectedPaymentMethodId,
      });

      // Ambil String id_booking dari data root atau bungkus response Laravel
      String? bookingId;
      if (booking['data'] != null && booking['data']['id_booking'] != null) {
        bookingId = booking['data']['id_booking']?.toString();
      } else {
        bookingId = booking['id_booking']?.toString();
      }

      if (bookingId == null || bookingId.isEmpty) {
        throw Exception('ID booking tidak ditemukan dari response Laravel.');
      }

      // 2. Hit API POST /api/payments
      final payment = await _apiClient.post('/payments', {
        'id_booking': bookingId, // Dikirim berupa String murni (VARCHAR)
        'metode_pembayaran': selectedPaymentMethodId,
        'jumlah_bayar': totalPayment,
      });

      // 🔴 Solusi Ekstraksi ID: Mengambil data string 'PAY00X' dari dalam nested JSON map Laravel
      if (payment['data'] != null && payment['data']['id_payment'] != null) {
        _lastPaymentId = payment['data']['id_payment'].toString();
      } else {
        _lastPaymentId = payment['id_payment']?.toString();
      }
    } catch (e) {
      debugPrint("Gagal memproses transaksi: $e");
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<RoomModel> _loadAvailableRoom() async {
    if (hotelId.isEmpty) {
      throw Exception('Hotel belum dipilih.');
    }

    final response = await _apiClient.get('/rooms');
    final rooms = _extractList(response)
        .whereType<Map<String, dynamic>>()
        .map(RoomModel.fromJson)
        .where((room) => room.idHotel == hotelId)
        .toList();

    if (rooms.isEmpty) {
      throw Exception('Room untuk hotel ini belum tersedia.');
    }

    return rooms.firstWhere(
      (room) => room.status == RoomStatus.available,
      orElse: () => rooms.first,
    );
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      if (response['items'] is List) return response['items'] as List;
      if (response['rooms'] is List) return response['rooms'] as List;
    }
    return const [];
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