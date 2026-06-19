/*
|--------------------------------------------------------------------------
| User Model
|--------------------------------------------------------------------------
| Tujuan file:
| Mendefinisikan struktur data user yang dipakai oleh Authentication, Profile,
| Personal Information, Privacy Policy, dan fitur lain yang membutuhkan user.
|
| Peran dalam arsitektur:
| Backend JSON -> AuthRepository -> UserModel -> AuthProvider -> UI Layer.
| Model ini juga diserialisasi ke LocalStorageService agar sesi login dapat
| dipulihkan saat aplikasi dibuka ulang.
|
| Hubungan dengan Authentication/Profile:
| Login/register/update profile/update privacy semuanya mengembalikan atau
| menyimpan data user melalui model ini.
|
| Kapan digunakan:
| Saat parsing response backend, menyimpan user cache, membaca user cache, dan
| menampilkan data profile di UI.
|--------------------------------------------------------------------------
*/

/*
|--------------------------------------------------------------------------
| UserModel
|--------------------------------------------------------------------------
| Tujuan class:
| Menjadi representasi domain untuk data user aplikasi.
|
| Tanggung jawab:
| - Menormalisasi variasi nama field backend seperti id_user/id, nama/name,
|   dan no_hp/phone_number.
| - Menyediakan alias getter agar UI lama dan baru tetap bisa memakai data.
| - Mengubah JSON backend menjadi object dan object menjadi JSON cache.
|
| Data yang dikelola:
| idUser, nama, email, noHp, alamat, userImage, dan createdAt.
|--------------------------------------------------------------------------
*/
class UserModel {
  final String idUser;
  final String nama;
  final String email;
  final String? noHp;
  final String? alamat;
  final String? userImage;
  final DateTime? createdAt;

  /*
  |--------------------------------------------------------------------------
  | UserModel()
  |--------------------------------------------------------------------------
  | Dipanggil saat repository membuat fallback user atau fromJson membangun
  | object dari response backend.
  |
  | Parameter:
  | Mendukung nama field utama dan alias agar kompatibel dengan beberapa layer.
  |
  | Return:
  | Instance UserModel.
  |--------------------------------------------------------------------------
  */
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

  /*
  |--------------------------------------------------------------------------
  | copyWith()
  |--------------------------------------------------------------------------
  | Dipanggil ketika kode perlu membuat variasi UserModel tanpa mengubah object
  | lama.
  |
  | Return:
  | UserModel baru dengan field yang diberikan menggantikan nilai lama.
  |--------------------------------------------------------------------------
  */
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

  /*
  |--------------------------------------------------------------------------
  | fromJson()
  |--------------------------------------------------------------------------
  | Dipanggil AuthRepository saat response backend diterima dan AuthProvider
  | saat membaca cache user dari secure storage.
  |
  | Parameter:
  | - json: Map dari backend/cache.
  |
  | Return:
  | UserModel yang sudah menormalisasi alias field.
  |--------------------------------------------------------------------------
  */
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

  /*
  |--------------------------------------------------------------------------
  | toJson()
  |--------------------------------------------------------------------------
  | Dipanggil AuthProvider sebelum menyimpan user ke LocalStorageService.
  |
  | Return:
  | Map JSON dengan field yang sesuai kontrak backend/cache.
  |--------------------------------------------------------------------------
  */
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

  /*
  |--------------------------------------------------------------------------
  | _parseDate()
  |--------------------------------------------------------------------------
  | Dipanggil fromJson() untuk membaca created_at jika backend mengirimkannya.
  |
  | Return:
  | DateTime jika valid, null jika kosong/tidak valid.
  |--------------------------------------------------------------------------
  */
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
