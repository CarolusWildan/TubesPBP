import '../network/api_client.dart';

class BookingHistoryModel {
  final String? idPayment; 
  final String? bookingId;
  final String hotelName;
  final String location;
  final String imageUrl;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalPayment;
  final String paymentStatus;
  final String paymentMethod;
  final String reviewStatus;
  final String? userId;

  const BookingHistoryModel({
    required this.idPayment, 
    this.bookingId,
    required this.hotelName,
    required this.location,
    required this.imageUrl,
    required this.checkIn,
    required this.checkOut,
    required this.totalPayment,
    this.paymentStatus = 'Payment Pending',
    this.paymentMethod = 'QRIS',
    this.reviewStatus = 'Not Reviewed',
    this.userId,
  });

  factory BookingHistoryModel.fromJson(Map<String, dynamic> json) {
    // 🟢 PERBAIKAN 1: Ekstrak booking_details sebagai List dan ambil element pertama
    final bookingDetails = _asList(json['booking_details'] ?? json['bookingDetails']);
    final firstDetail = bookingDetails.isNotEmpty ? _asMap(bookingDetails.first) : null;
    
    final room = _asMap(firstDetail?['room']);
    final hotel =
        _asMap(room?['hotel']) ??
        _asMap(firstDetail?['hotel']) ??
        _asMap(json['hotel']);

    // 🟢 PERBAIKAN 2: Karena di Laravel 'payments' adalah array/list, ambil data pertamanya
    final paymentsList = _asList(json['payments'] ?? json['payment']);
    final payment = paymentsList.isNotEmpty 
        ? _asMap(paymentsList.first) 
        : _asMap(json['payments'] ?? json['payment']); // fallback jika berupa Map mentah

    final reviews = _asList(json['reviews']);

    final checkIn =
        _parseDate(json['check_in'] ?? json['checkIn']) ?? DateTime.now();
    final checkOut =
        _parseDate(json['check_out'] ?? json['checkOut']) ??
        checkIn.add(const Duration(days: 1));

    return BookingHistoryModel(
      idPayment: _firstNullableText([
        payment?['id_payment'],
        payment?['id'],
        json['id_payment'],
        json['id_booking'],
        json['id'],
      ]),
      bookingId: _firstNullableText([json['id_booking'], json['id']]),
      hotelName: _firstText([
        hotel?['nama_hotel'],
        hotel?['hotel_name'],
        hotel?['name'],
        json['nama_hotel'],
        json['hotel_name'],
      ], fallback: 'Hotel booking'),
      location: _firstText([
        hotel?['kota'],
        hotel?['alamat'],
        json['kota'],
        json['alamat'],
      ], fallback: 'Booking'),
      imageUrl: _resolveImageUrl(
        _firstNullableText([
          hotel?['hotel_image'],
          hotel?['image_url'],
          hotel?['image'],
          json['hotel_image'],
          json['image_url'],
          json['image'],
        ]),
      ),
      checkIn: checkIn,
      checkOut: checkOut,
      totalPayment: _toDouble(
        payment?['jumlah_bayar'] ??
            payment?['total_payment'] ??
            json['total_harga'] ??
            json['total_payment'],
      ),
      paymentStatus: _formatPaymentStatus(
        payment?['status_pembayaran'] ?? payment?['status'] ?? json['status'],
      ),
      paymentMethod: _formatPaymentMethod(
        payment?['metode_pembayaran'] ?? json['metode_pembayaran'],
      ),
      reviewStatus: reviews.isNotEmpty ? 'Reviewed' : 'Not Reviewed',
      userId: _firstNullableText([json['id_user'], json['user_id']]),
    );
  }

  factory BookingHistoryModel.fromPaymentJson(Map<String, dynamic> json) {
    final booking = _asMap(json['booking']);
    if (booking == null) return BookingHistoryModel.fromJson(json);

    // Jika datang dari endpoint payment, bungkus objek payment ke dalam array agar seragam
    return BookingHistoryModel.fromJson({...booking, 'payments': [json]});
  }

  bool get isPending => paymentStatus.toLowerCase().contains('pending');
  bool get isSuccess => paymentStatus.toLowerCase().contains('success');
  bool get needsReview => isSuccess && reviewStatus != 'Reviewed';

  bool belongsToUser(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty || userId == null) {
      return true;
    }
    return userId == currentUserId;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  static String? _firstNullableText(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }

  static String _firstText(List<dynamic> values, {required String fallback}) {
    return _firstNullableText(values) ?? fallback;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatPaymentStatus(dynamic value) {
    final status = value?.toString().toLowerCase() ?? 'pending';
    if (status.contains('success') ||
        status.contains('paid') ||
        status.contains('settlement')) {
      return 'Payment Success';
    }
    if (status.contains('cancel') ||
        status.contains('failed') ||
        status.contains('expire')) {
      return 'Payment Cancel';
    }
    return 'Payment Pending';
  }

  static String _formatPaymentMethod(dynamic value) {
    final method = value?.toString().trim();
    if (method == null || method.isEmpty || method == 'null') return 'QRIS';
    return method
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.toLowerCase() == 'qris'
              ? 'QRIS'
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static String _resolveImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400';
    }

    final imagePath = value.trim().replaceAll('\\', '/');
    final uri = Uri.tryParse(imagePath);
    if (uri != null && uri.hasScheme) return imagePath;

    final serverUrl = ApiClient.serverUrl;
    if (imagePath.startsWith('/')) return '$serverUrl$imagePath';
    
    // Hilangkan prefix storage/ jika di database sudah tersimpan dengan kata 'storage/'
    if (imagePath.startsWith('storage/')) return '$serverUrl/$imagePath';
    return '$serverUrl/storage/$imagePath';
  }
}