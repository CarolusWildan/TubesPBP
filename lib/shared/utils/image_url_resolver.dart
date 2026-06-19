import '../network/api_client.dart';

String? resolveImageUrl(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final imagePath = value.trim().replaceAll('\\', '/');
  final uri = Uri.tryParse(imagePath);
  if (uri != null && uri.hasScheme) return Uri.encodeFull(imagePath);

  final serverUrl = ApiClient.serverUrl;
  if (imagePath.startsWith('/')) {
    return Uri.encodeFull('$serverUrl$imagePath');
  }
  if (imagePath.startsWith('storage/')) {
    return Uri.encodeFull('$serverUrl/$imagePath');
  }
  return Uri.encodeFull('$serverUrl/storage/$imagePath');
}

String fallbackHotelImageUrl() {
  return 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400';
}
