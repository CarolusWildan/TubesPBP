class BookingModel {
  final String? id;
  final String userId;
  final String hotelId;
  final String roomId;
  final String guestName;
  final String guestPhone;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final bool hasBreakfast;
  final double totalPrice;
  final String paymentMethod;
  final String status;

  BookingModel({
    this.id,
    required this.userId,
    required this.hotelId,
    required this.roomId,
    required this.guestName,
    required this.guestPhone,
    required this.checkInDate,
    required this.checkOutDate,
    this.hasBreakfast = false,
    required this.totalPrice,
    required this.paymentMethod,
    required this.status,
  });

  BookingModel copyWith({
    String? id,
    String? userId,
    String? hotelId,
    String? roomId,
    String? guestName,
    String? guestPhone,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    bool? hasBreakfast,
    double? totalPrice,
    String? paymentMethod,
    String? status,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      hotelId: hotelId ?? this.hotelId,
      roomId: roomId ?? this.roomId,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      hasBreakfast: hasBreakfast ?? this.hasBreakfast,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
    );
  }

  // Digunakan HANYA jika ingin membaca riwayat transaksi dari API
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      hotelId: json['hotel_id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      guestName: json['guest_name'] ?? '',
      guestPhone: json['guest_phone'] ?? '',
      // Parsing String ISO8601 ke DateTime Dart
      checkInDate:
          DateTime.tryParse(json['check_in_date'] ?? '') ?? DateTime.now(),
      checkOutDate:
          DateTime.tryParse(json['check_out_date'] ?? '') ?? DateTime.now(),
      hasBreakfast: json['has_breakfast'] ?? false,
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }

  // Digunakan saat checkout/membayar untuk dikirim ke Laravel
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id, // Jangan kirim ID jika pesanan baru
      'user_id': userId,
      'hotel_id': hotelId,
      'room_id': roomId,
      'guest_name': guestName,
      'guest_phone': guestPhone,
      // API Laravel biasanya meminta format YYYY-MM-DD
      'check_in_date': checkInDate.toIso8601String().split('T').first,
      'check_out_date': checkOutDate.toIso8601String().split('T').first,
      'has_breakfast': hasBreakfast,
      'total_price': totalPrice,
      'payment_method': paymentMethod,
      'status': status,
    };
  }
}