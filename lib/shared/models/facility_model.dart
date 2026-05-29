class FacilityModel {
  final String idFacility;
  final String namaFacility;

  FacilityModel({
    required this.idFacility,
    required this.namaFacility,
  });

  factory FacilityModel.fromJson(Map<String, dynamic> json) {
    return FacilityModel(
      idFacility: (json['id_facility'] ?? json['id'])?.toString() ?? '',
      namaFacility: (json['nama_facility'] ?? json['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idFacility.isNotEmpty) 'id_facility': idFacility,
      'nama_facility': namaFacility,
    };
  }
}
