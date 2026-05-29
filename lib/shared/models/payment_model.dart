import 'booking_model.dart';

enum MetodePembayaran {
  ewallet('ewallet'),
  creditCard('credit_card'),
  virtualAccount('virtual_account');

  const MetodePembayaran(this.value);
  final String value;
}

enum StatusPembayaran { success, pending, cancel }

class PaymentModel {
  final String? idPayment;
  final String idBooking;
  final MetodePembayaran metodePembayaran;
  final double jumlahBayar;
  final StatusPembayaran statusPembayaran;
  final DateTime? expiredAt;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final BookingModel? booking;

  PaymentModel({
    this.idPayment,
    required this.idBooking,
    required this.metodePembayaran,
    required this.jumlahBayar,
    required this.statusPembayaran,
    this.expiredAt,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
    this.booking,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      idPayment: (json['id_payment'] ?? json['id'])?.toString(),
      idBooking: json['id_booking']?.toString() ?? '',
      metodePembayaran: _metodeFromJson(json['metode_pembayaran']),
      jumlahBayar: _toDouble(json['jumlah_bayar']),
      statusPembayaran: _statusFromJson(json['status_pembayaran']),
      expiredAt: _parseDate(json['expired_at']),
      paidAt: _parseDate(json['paid_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      booking: json['booking'] is Map<String, dynamic>
          ? BookingModel.fromJson(json['booking'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idPayment != null) 'id_payment': idPayment,
      'id_booking': idBooking,
      'metode_pembayaran': metodePembayaran.value,
      'jumlah_bayar': jumlahBayar,
      'status_pembayaran': statusPembayaran.name,
      if (expiredAt != null) 'expired_at': expiredAt!.toIso8601String(),
      if (paidAt != null) 'paid_at': paidAt!.toIso8601String(),
    };
  }

  static MetodePembayaran _metodeFromJson(dynamic value) {
    final raw = value?.toString();
    return MetodePembayaran.values.firstWhere(
      (item) => item.value == raw || item.name == raw,
      orElse: () => MetodePembayaran.virtualAccount,
    );
  }

  static StatusPembayaran _statusFromJson(dynamic value) {
    return StatusPembayaran.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => StatusPembayaran.pending,
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
}
