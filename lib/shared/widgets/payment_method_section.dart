import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/home/presentation/providers/booking_summary_provider.dart';
import 'section_card.dart';

class PaymentMethodSection extends StatelessWidget {
  const PaymentMethodSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingSummaryProvider>();

    return SectionCard(
      title: 'Payment Method',
      trailing: GestureDetector(
        onTap: () => _showPaymentMethodSheet(context, provider),
        child: const Text(
          'See all',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              provider.selectedPaymentMethod.icon,
              size: 24,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            provider.selectedPaymentMethod.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 22),
        ],
      ),
    );
  }

  void _showPaymentMethodSheet(BuildContext context, BookingSummaryProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Metode Pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...provider.paymentMethods.map(
                (method) => ListTile(
                  leading: Icon(method.icon),
                  title: Text(method.name),
                  trailing: provider.selectedPaymentMethodId == method.id
                      ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32))
                      : null,
                  onTap: () {
                    provider.selectPaymentMethod(method.id);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}