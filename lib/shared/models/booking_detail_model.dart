import 'booking_model.dart';
import 'room_model.dart';

class BookingDetailModel {
  final String? idBookingDetail;
  final String idBooking;
  final String idRoom;
  final double harga;
  final int jumlahMalam;
  final double subtotal;
  final BookingStatus status;
  final BookingModel? booking;
  final RoomModel? room;

  BookingDetailModel({
    this.idBookingDetail,
    required this.idBooking,
    required this.idRoom,
    required this.harga,
    required this.jumlahMalam,
    required this.subtotal,
    required this.status,
    this.booking,
    this.room,
  });

  factory BookingDetailModel.fromJson(Map<String, dynamic> json) {
    return BookingDetailModel(
      idBookingDetail: (json['id_booking_detail'] ?? json['id'])?.toString(),
      idBooking: json['id_booking']?.toString() ?? '',
      idRoom: json['id_room']?.toString() ?? '',
      harga: _toDouble(json['harga']),
      jumlahMalam: _toInt(json['jumlah_malam']),
      subtotal: _toDouble(json['subtotal']),
      status: _statusFromJson(json['status']),
      booking: json['booking'] is Map<String, dynamic>
          ? BookingModel.fromJson(json['booking'] as Map<String, dynamic>)
          : null,
      room: json['room'] is Map<String, dynamic>
          ? RoomModel.fromJson(json['room'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idBookingDetail != null) 'id_booking_detail': idBookingDetail,
      'id_booking': idBooking,
      'id_room': idRoom,
      'harga': harga,
      'jumlah_malam': jumlahMalam,
      'subtotal': subtotal,
      'status': status.name,
    };
  }

  static BookingStatus _statusFromJson(dynamic value) {
    return BookingStatus.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => BookingStatus.pending,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
