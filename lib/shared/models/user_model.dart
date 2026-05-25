class UserModel {
  final String idUser;
  final String nama;
  final String email;
  final String? noHp;
  final String? alamat;
  final String? userImage;
  final DateTime? createdAt;

  UserModel({
    String? idUser,
    String? nama,
    required this.email,
    String? noHp,
    this.alamat,
    this.userImage,
    this.createdAt,
    String? id,
    String? fullName,
    String? phoneNumber,
  })  : idUser = idUser ?? id ?? '',
        nama = nama ?? fullName ?? 'Guest',
        noHp = noHp ?? phoneNumber;

  String get id => idUser;
  String get fullName => nama;
  String get phoneNumber => noHp ?? '';

  UserModel copyWith({
    String? idUser,
    String? nama,
    String? email,
    String? noHp,
    String? alamat,
    String? userImage,
    DateTime? createdAt,
    String? id,
    String? fullName,
    String? phoneNumber,
  }) {
    return UserModel(
      idUser: idUser ?? id ?? this.idUser,
      nama: nama ?? fullName ?? this.nama,
      email: email ?? this.email,
      noHp: noHp ?? phoneNumber ?? this.noHp,
      alamat: alamat ?? this.alamat,
      userImage: userImage ?? this.userImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUser: (json['id_user'] ?? json['id'])?.toString() ?? '',
      nama: (json['nama'] ?? json['full_name'] ?? json['name'] ?? 'Guest')
          .toString(),
      email: json['email']?.toString() ?? '',
      noHp: (json['no_hp'] ?? json['phone_number'])?.toString(),
      alamat: json['alamat']?.toString(),
      userImage: json['user_image']?.toString(),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idUser.isNotEmpty) 'id_user': idUser,
      'nama': nama,
      'email': email,
      if (noHp != null) 'no_hp': noHp,
      if (alamat != null) 'alamat': alamat,
      if (userImage != null) 'user_image': userImage,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
