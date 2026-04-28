class HotelModel {
  final String id;
  final String name;
  final String address;
  final String description;
  final double rating;
  final List<String> facilities;
  final List<String> imageUrls;

  HotelModel({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.rating,
    required this.facilities,
    required this.imageUrls,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Nama Hotel Tidak Tersedia',
      address: json['address'] ?? '',
      description: json['description'] ?? '',
      // Konversi aman ke double. Terkadang backend mengirim angka bulat tanpa desimal (misal: 4)
      rating: (json['rating'] ?? 0.0).toDouble(),
      // Mencegah error jika facilities/image_urls dari API bernilai null
      facilities: List<String>.from(json['facilities'] ?? []),
      imageUrls: List<String>.from(json['image_urls'] ?? []),
    );
  }
}