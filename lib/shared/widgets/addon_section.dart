import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/home/presentation/providers/booking_summary_provider.dart';
import 'section_card.dart';

class AddonSection extends StatelessWidget {
  const AddonSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingSummaryProvider>();

    return SectionCard(
      title: 'Enhance Your Stay',
      child: Column(
        children: List.generate(
          provider.addons.length,
          (index) => _AddonItem(
            addon: provider.addons[index],
            onToggle: () => provider.toggleAddon(index),
          ),
        ),
      ),
    );
  }
}

class _AddonItem extends StatelessWidget {
  final AddonItem addon;
  final VoidCallback onToggle;

  const _AddonItem({required this.addon, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(addon.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addon.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '+ Rp ${_formatRupiah(addon.pricePerNight)} / pax / night',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: addon.isSelected,
            onChanged: (_) => onToggle(),
            activeColor: const Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}
