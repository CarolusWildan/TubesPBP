import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/qr_ticket_widget.dart'; // Sesuaikan path widget QR Anda

class TicketScreen extends StatelessWidget {
  final String bookingId;

  const TicketScreen({Key? key, required this.bookingId}) : super(key: key);

  // Fungsi dinamis: parameter 'type' bisa berisi 'preview-pdf' atau 'download-pdf'
  Future<void> _handlePdfAction(String type) async {
    // Ganti dengan NGROK Anda yang aktif
    final Uri url = Uri.parse('https://mortality-emote-creasing.ngrok-free.dev/api/bookings/$bookingId/$type');
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Gagal memproses tautan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('E-Ticket', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Tampilkan Widget QR Code
              QrTicketWidget(bookingId: bookingId),
              
              const SizedBox(height: 40),
              
              // 2. Tombol Preview (Stream)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.remove_red_eye, color: Color(0xFF0F9D58)),
                  label: const Text(
                    'Preview Invoice',
                    style: TextStyle(color: Color(0xFF0F9D58), fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0F9D58)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _handlePdfAction('preview-pdf'),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 3. Tombol Download Langsung
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text(
                    'Download Invoice',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F9D58), // Warna hijau Pitulungan
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _handlePdfAction('download-pdf'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}