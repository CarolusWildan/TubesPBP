import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GeolocationResult {
  const GeolocationResult({
    this.city,
    this.message,
    this.permissionDenied = false,
  });

  final String? city;
  final String? message;
  final bool permissionDenied;

  bool get hasCity => city != null && city!.trim().isNotEmpty;
}

class GeolocationService {
  Future<GeolocationResult> resolveCurrentCity() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const GeolocationResult(
        message: 'Aktifkan GPS untuk melihat hotel terdekat berdasarkan kota.',
      );
    }

    var permission = await Permission.locationWhenInUse.status;
    if (permission.isDenied || permission.isRestricted) {
      permission = await Permission.locationWhenInUse.request();
    }

    if (permission.isPermanentlyDenied) {
      return const GeolocationResult(
        permissionDenied: true,
        message: 'Izin lokasi diblokir. Aktifkan izin lokasi dari pengaturan aplikasi.',
      );
    }

    if (!permission.isGranted) {
      return const GeolocationResult(
        permissionDenied: true,
        message: 'Izin lokasi diperlukan untuk menampilkan hotel sesuai kota Anda.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final city = _cityFromPlacemarks(placemarks);
      if (city == null) {
        return const GeolocationResult(
          message: 'Kota dari lokasi Anda belum bisa dikenali.',
        );
      }

      return GeolocationResult(city: city);
    } catch (_) {
      return const GeolocationResult(
        message: 'Gagal mengambil lokasi saat ini.',
      );
    }
  }

  String? _cityFromPlacemarks(List<Placemark> placemarks) {
    for (final placemark in placemarks) {
      final candidates = [
        placemark.locality,
        placemark.subAdministrativeArea,
        placemark.administrativeArea,
      ];

      for (final value in candidates) {
        final city = _cleanCityName(value);
        if (city != null) return city;
      }
    }

    return null;
  }

  String? _cleanCityName(String? value) {
    if (value == null) return null;

    final cleaned = value
        .replaceAll(RegExp(r'^(Kota|Kabupaten)\s+', caseSensitive: false), '')
        .trim();

    if (cleaned.isEmpty) return null;
    return cleaned;
  }
}
