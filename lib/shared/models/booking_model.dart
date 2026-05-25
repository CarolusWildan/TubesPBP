import 'booking_addon_model.dart';
import 'user_model.dart';

enum BookingStatus { success, pending, cancel }

class BookingModel {
  final String? idBooking;
  final String idUser;
  final DateTime tanggalBooking;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalHarga;
  final BookingStatus status;
  final UserModel? user;
  final List<BookingAddonModel> bookingAddons;

  BookingModel({
    this.idBooking,
    required this.idUser,
    required this.tanggalBooking,
    required this.checkIn,
    required this.checkOut,
    required this.totalHarga,
    required this.status,
    this.user,
    this.bookingAddons = const [],
  });

  String? get id => idBooking;
  String get userId => idUser;
  DateTime get checkInDate => checkIn;
  DateTime get checkOutDate => checkOut;
  double get totalPrice => totalHarga;

  BookingModel copyWith({
    String? idBooking,
    String? idUser,
    DateTime? tanggalBooking,
    DateTime? checkIn,
    DateTime? checkOut,
    double? totalHarga,
    BookingStatus? status,
    UserModel? user,
    List<BookingAddonModel>? bookingAddons,
  }) {
    return BookingModel(
      idBooking: idBooking ?? this.idBooking,
      idUser: idUser ?? this.idUser,
      tanggalBooking: tanggalBooking ?? this.tanggalBooking,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      totalHarga: totalHarga ?? this.totalHarga,
      status: status ?? this.status,
      user: user ?? this.user,
      bookingAddons: bookingAddons ?? this.bookingAddons,
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      idBooking: (json['id_booking'] ?? json['id'])?.toString(),
      idUser: (json['id_user'] ?? json['user_id'])?.toString() ?? '',
      tanggalBooking: _parseDate(json['tanggal_booking']) ?? DateTime.now(),
      checkIn: _parseDate(json['check_in']) ?? DateTime.now(),
      checkOut: _parseDate(json['check_out']) ?? DateTime.now(),
      totalHarga: _toDouble(json['total_harga'] ?? json['total_price']),
      status: _statusFromJson(json['status']),
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      bookingAddons: _parseBookingAddons(json['booking_addons']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idBooking != null) 'id_booking': idBooking,
      'id_user': idUser,
      'tanggal_booking': _formatDate(tanggalBooking),
      'check_in': _formatDate(checkIn),
      'check_out': _formatDate(checkOut),
      'total_harga': totalHarga,
      'status': status.name,
    };
  }

  static List<BookingAddonModel> _parseBookingAddons(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(BookingAddonModel.fromJson)
        .toList();
  }

  static BookingStatus _statusFromJson(dynamic value) {
    return BookingStatus.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => BookingStatus.pending,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
