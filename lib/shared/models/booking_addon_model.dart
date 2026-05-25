import 'addon_model.dart';

class BookingAddonModel {
  final String? idBookingAddon;
  final String idBooking;
  final String idAddon;
  final int quantity;
  final double subtotal;
  final String? catatan;
  final AddonModel? addon;

  BookingAddonModel({
    this.idBookingAddon,
    required this.idBooking,
    required this.idAddon,
    required this.quantity,
    required this.subtotal,
    this.catatan,
    this.addon,
  });

  factory BookingAddonModel.fromJson(Map<String, dynamic> json) {
    return BookingAddonModel(
      idBookingAddon: (json['id_booking_addon'] ?? json['id'])?.toString(),
      idBooking: json['id_booking']?.toString() ?? '',
      idAddon: json['id_addon']?.toString() ?? '',
      quantity: _toInt(json['quantity']),
      subtotal: _toDouble(json['subtotal']),
      catatan: json['catatan']?.toString(),
      addon: json['addon'] is Map<String, dynamic>
          ? AddonModel.fromJson(json['addon'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idBookingAddon != null) 'id_booking_addon': idBookingAddon,
      'id_booking': idBooking,
      'id_addon': idAddon,
      'quantity': quantity,
      'subtotal': subtotal,
      if (catatan != null) 'catatan': catatan,
    };
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
