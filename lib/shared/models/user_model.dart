class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Menggunakan .toString() agar aman meskipun Laravel mengirim integer (misal: id: 1)
      id: json['id']?.toString() ?? '',
      // Menangkap format snake_case dari Laravel
      fullName: json['full_name'] ?? 'Guest',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
    };
  }
}