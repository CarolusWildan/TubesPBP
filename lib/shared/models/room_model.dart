import 'hotel_model.dart';
import 'room_type_model.dart';

enum RoomStatus { available, booked, maintenance }

class RoomModel {
  final String idRoom;
  final String idHotel;
  final String idRoomType;
  final String? roomImage;
  final String nomorKamar;
  final RoomStatus status;
  final HotelModel? hotel;
  final RoomTypeModel? roomType;

  RoomModel({
    required this.idRoom,
    required this.idHotel,
    required this.idRoomType,
    this.roomImage,
    required this.nomorKamar,
    required this.status,
    this.hotel,
    this.roomType,
  });

  String get id => idRoom;
  String get hotelId => idHotel;
  String get name => roomType?.namaType ?? nomorKamar;
  double get pricePerNight => roomType?.hargaPerMalam ?? 0;
  int get capacity => roomType?.kapasitas ?? 1;
  int get availableRooms => status == RoomStatus.available ? 1 : 0;
  List<String> get imageUrls => roomImage == null ? [] : [roomImage!];

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      idRoom: (json['id_room'] ?? json['id'])?.toString() ?? '',
      idHotel: (json['id_hotel'] ?? json['hotel_id'])?.toString() ?? '',
      idRoomType:
          (json['id_room_type'] ?? json['room_type_id'])?.toString() ?? '',
      roomImage:
          (json['room_image'] ??
                  json['image_url'] ??
                  json['image'] ??
                  json['foto'] ??
                  json['photo'])
              ?.toString(),
      nomorKamar: (json['nomor_kamar'] ?? json['room_number'] ?? '').toString(),
      status: _statusFromJson(json['status']),
      hotel: json['hotel'] is Map<String, dynamic>
          ? HotelModel.fromJson(json['hotel'] as Map<String, dynamic>)
          : null,
      roomType: json['room_type'] is Map<String, dynamic>
          ? RoomTypeModel.fromJson(json['room_type'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idRoom.isNotEmpty) 'id_room': idRoom,
      'id_hotel': idHotel,
      'id_room_type': idRoomType,
      if (roomImage != null) 'room_image': roomImage,
      'nomor_kamar': nomorKamar,
      'status': status.name,
    };
  }

  static RoomStatus _statusFromJson(dynamic value) {
    return RoomStatus.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => RoomStatus.available,
    );
  }
}
