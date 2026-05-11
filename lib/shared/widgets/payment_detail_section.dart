import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/home/presentation/providers/booking_summary_provider.dart';
import 'section_card.dart';

class PaymentDetailSection extends StatelessWidget {
  const PaymentDetailSection({super.key});

  static String formatRupiah(double amount) {
    if (amount == 0) return 'Rp -';
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingSummaryProvider>();

    return Column(
      children: [
        SectionCard(
          title: 'Payment Detail',
          child: Column(
            children: [
              _DetailRow(label: 'Subtotal Order', amount: provider.subtotalOrder),
              const SizedBox(height: 8),
              _DetailRow(label: 'Service Fee', amount: provider.serviceFee),
              const SizedBox(height: 8),
              _DetailRow(label: 'Discount', amount: provider.discount, isDiscount: true),
              if (provider.totalAddons > 0) ...[
                const SizedBox(height: 8),
                _DetailRow(label: 'Add-ons', amount: provider.totalAddons),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Payment',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    formatRupiah(provider.totalPayment),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'By clicking "Pay Now", I have read the Transaction Policy and agree to the Terms & Conditions of this application.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isDiscount;

  const _DetailRow({
    required this.label,
    required this.amount,
    this.isDiscount = false,
  });

  String _formatRupiah(double amount) {
    if (amount == 0) return 'Rp -';
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        Text(
          _formatRupiah(amount),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDiscount && amount > 0 ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }
}