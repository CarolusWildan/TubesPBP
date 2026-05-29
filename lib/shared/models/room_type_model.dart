class RoomTypeModel {
  final String idRoomType;
  final String namaType;
  final int kapasitas;
  final double hargaPerMalam;
  final String? deskripsi;

  RoomTypeModel({
    required this.idRoomType,
    required this.namaType,
    required this.kapasitas,
    required this.hargaPerMalam,
    this.deskripsi,
  });

  factory RoomTypeModel.fromJson(Map<String, dynamic> json) {
    return RoomTypeModel(
      idRoomType: (json['id_room_type'] ?? json['id'])?.toString() ?? '',
      namaType: (json['nama_type'] ?? json['name'] ?? '').toString(),
      kapasitas: _toInt(json['kapasitas'] ?? json['capacity']),
      hargaPerMalam: _toDouble(json['harga_per_malam'] ?? json['price_per_night']),
      deskripsi: (json['deskripsi'] ?? json['description'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idRoomType.isNotEmpty) 'id_room_type': idRoomType,
      'nama_type': namaType,
      'kapasitas': kapasitas,
      'harga_per_malam': hargaPerMalam,
      if (deskripsi != null) 'deskripsi': deskripsi,
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
