import 'package:url_launcher/url_launcher.dart';

void downloadPdf(String bookingId) async {
  print('==== MENGUNDUH PDF UNTUK ID: $bookingId ====');
  // 1. Ganti ngrok-nya dengan ngrok Anda yang aktif
  // 2. Perhatikan penambahan '/api/bookings/'
  final Uri url = Uri.parse('https://mortality-emote-creasing.ngrok-free.dev/api/bookings/$bookingId/download-pdf');
  
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Gagal membuka $url');
  }
}