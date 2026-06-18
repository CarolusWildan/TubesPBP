import 'hotel_model.dart';
import 'user_model.dart';

class ReviewModel {
  final String? idReview;
  final String idUser;
  final String idHotel;
  final int rating;
  final String? komentar;
  final List<String> mediaPaths;
  final DateTime? createdAt;
  final UserModel? user;
  final HotelModel? hotel;

  ReviewModel({
    this.idReview,
    required this.idUser,
    required this.idHotel,
    required this.rating,
    this.komentar,
    this.mediaPaths = const [],
    this.createdAt,
    this.user,
    this.hotel,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      idReview: (json['id_review'] ?? json['id'])?.toString(),
      idUser: json['id_user']?.toString() ?? '',
      idHotel: json['id_hotel']?.toString() ?? '',
      rating: _toInt(json['rating']),
      komentar: json['komentar']?.toString(),
      mediaPaths: _parseMediaPaths(json['media'] ?? json['review_media']),
      createdAt: _parseDate(json['created_at']),
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      hotel: json['hotel'] is Map<String, dynamic>
          ? HotelModel.fromJson(json['hotel'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idReview != null) 'id_review': idReview,
      'id_user': idUser,
      'id_hotel': idHotel,
      'rating': rating,
      if (komentar != null) 'komentar': komentar,
    };
  }

  static List<String> _parseMediaPaths(dynamic value) {
    if (value is! List) return const [];

    return value
        .map((item) {
          if (item is Map<String, dynamic>) {
            return (item['media_path'] ?? item['path'] ?? item['url'])
                ?.toString();
          }
          if (item is Map) {
            return (item['media_path'] ?? item['path'] ?? item['url'])
                ?.toString();
          }
          return item?.toString();
        })
        .whereType<String>()
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty && path != 'null')
        .toList();
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
