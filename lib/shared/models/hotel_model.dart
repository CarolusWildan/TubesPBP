import 'facility_model.dart';

class HotelModel {
  final String idHotel;
  final String namaHotel;
  final String alamat;
  final String kota;
  final String? deskripsi;
  final double? rating;
  final String? email;
  final String? noHp;
  final String? hotelImage;
  final double? minPrice;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<FacilityModel> facilities;

  HotelModel({
    required this.idHotel,
    required this.namaHotel,
    required this.alamat,
    required this.kota,
    this.deskripsi,
    this.rating,
    this.email,
    this.noHp,
    this.hotelImage,
    this.minPrice,
    this.createdAt,
    this.updatedAt,
    this.facilities = const [],
  });

  String get id => idHotel;
  String get name => namaHotel;
  String get address => alamat;
  String get description => deskripsi ?? '';
  List<String> get imageUrls => hotelImage == null ? [] : [hotelImage!];
  List<String> get facilityNames =>
      facilities.map((item) => item.namaFacility).toList();

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      idHotel: (json['id_hotel'] ?? json['id'])?.toString() ?? '',
      namaHotel: (json['nama_hotel'] ?? json['name'] ?? '').toString(),
      alamat: (json['alamat'] ?? json['address'] ?? '').toString(),
      kota: json['kota']?.toString() ?? '',
      deskripsi: (json['deskripsi'] ?? json['description'])?.toString(),
      rating: _toDouble(json['rating']),
      email: json['email']?.toString(),
      noHp: json['no_hp']?.toString(),
      hotelImage: json['hotel_image']?.toString(),
      minPrice: _toDouble(json['min_price']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      facilities: _parseFacilities(json['facilities']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idHotel.isNotEmpty) 'id_hotel': idHotel,
      'nama_hotel': namaHotel,
      'alamat': alamat,
      'kota': kota,
      if (deskripsi != null) 'deskripsi': deskripsi,
      if (rating != null) 'rating': rating,
      if (email != null) 'email': email,
      if (noHp != null) 'no_hp': noHp,
      if (hotelImage != null) 'hotel_image': hotelImage,
    };
  }

  static List<FacilityModel> _parseFacilities(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(FacilityModel.fromJson)
        .toList();
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
