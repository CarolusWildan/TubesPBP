enum MetodePembayaran { transfer, ewallet, credit_card, virtual_account, qris }
enum StatusPembayaran { success, pending, cancel }

class PaymentModel {
  final String idPayment;
  final String idBooking;
  final MetodePembayaran metodePembayaran;
  final double jumlahBayar;
  final StatusPembayaran statusPembayaran;
  final DateTime createdAt;
  final DateTime expiredAt;
  final DateTime? paidAt;

  PaymentModel({
    required this.idPayment,
    required this.idBooking,
    required this.metodePembayaran,
    required this.jumlahBayar,
    required this.statusPembayaran,
    required this.createdAt,
    required this.expiredAt,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      idPayment: json['id_payment']?.toString() ?? '',
      idBooking: json['id_booking']?.toString() ?? '',
      metodePembayaran: MetodePembayaran.values.firstWhere(
        (e) => e.name == json['metode_pembayaran'],
        orElse: () => MetodePembayaran.qris,
      ),
      jumlahBayar: (json['jumlah_bayar'] ?? 0.0).toDouble(),
      statusPembayaran: StatusPembayaran.values.firstWhere(
        (e) => e.name == json['status_pembayaran'],
        orElse: () => StatusPembayaran.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      expiredAt: DateTime.parse(json['expired_at'] ?? DateTime.now().toIso8601String()),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
    );
  }
}