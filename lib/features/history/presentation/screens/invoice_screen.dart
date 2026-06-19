import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void downloadPdf(String bookingId) async {
  print('==== MENGUNDUH PDF UNTUK ID: $bookingId ====');

  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';
  final Uri url = Uri.parse('$baseUrl/api/bookings/$bookingId/download-pdf');
  
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Gagal membuka $url');
  }
}