class RoomModel {
  final String id;
  final String hotelId;
  final String name;
  final double pricePerNight;
  final int capacity;
  final int availableRooms;
  final List<String> imageUrls;

  RoomModel({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.pricePerNight,
    required this.capacity,
    required this.availableRooms,
    required this.imageUrls,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id']?.toString() ?? '',
      hotelId: json['hotel_id']?.toString() ?? '',
      name: json['name'] ?? 'Tipe Kamar',
      pricePerNight: (json['price_per_night'] ?? 0.0).toDouble(),
      capacity: json['capacity'] ?? 1,
      availableRooms: json['available_rooms'] ?? 0,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
    );
  }
}