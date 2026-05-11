import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'section_card.dart';

class TripInfoSection extends StatelessWidget {
  final DateTime checkIn;
  final DateTime checkOut;
  final int jumlahMalam;

  const TripInfoSection({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.jumlahMalam,
  });

  String _formatTanggal(DateTime date) {
    return DateFormat('EEE, dd MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Your Trip',
      child: Row(
        children: [
          // Check-in
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHECK-IN',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTanggal(checkIn),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '14:00 PM',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Jumlah malam (tengah)
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$jumlahMalam Nights',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          // Check-out
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'CHECK-OUT',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTanggal(checkOut),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '12:00 PM',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
