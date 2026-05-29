enum AddonStatus { available, unavailable }

class AddonModel {
  final String? idAddon;
  final String namaAddon;
  final String deskripsi;
  final double harga;
  final AddonStatus status;

  AddonModel({
    this.idAddon,
    required this.namaAddon,
    required this.deskripsi,
    required this.harga,
    required this.status,
  });

  factory AddonModel.fromJson(Map<String, dynamic> json) {
    return AddonModel(
      idAddon: (json['id_addon'] ?? json['id'])?.toString(),
      namaAddon: (json['nama_addon'] ?? json['name'] ?? '').toString(),
      deskripsi: (json['deskripsi'] ?? json['description'] ?? '').toString(),
      harga: _toDouble(json['harga'] ?? json['price']),
      status: _statusFromJson(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idAddon != null) 'id_addon': idAddon,
      'nama_addon': namaAddon,
      'deskripsi': deskripsi,
      'harga': harga,
      'status': status.name,
    };
  }

  static AddonStatus _statusFromJson(dynamic value) {
    return AddonStatus.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => AddonStatus.available,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
