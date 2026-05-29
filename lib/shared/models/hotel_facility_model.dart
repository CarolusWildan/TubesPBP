class HotelFacilityModel {
  final String idHotel;
  final String idFacility;

  HotelFacilityModel({
    required this.idHotel,
    required this.idFacility,
  });

  factory HotelFacilityModel.fromJson(Map<String, dynamic> json) {
    return HotelFacilityModel(
      idHotel: json['id_hotel']?.toString() ?? '',
      idFacility: json['id_facility']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_hotel': idHotel,
      'id_facility': idFacility,
    };
  }
}
