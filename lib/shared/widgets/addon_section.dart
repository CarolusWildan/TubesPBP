import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/home/presentation/providers/booking_summary_provider.dart';
import 'section_card.dart';

const double _addonControlMaxWidth = 88;
const double _addonControlMinWidth = 76;
const double _addonControlHeight = 34;

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
            onIncrease: () => provider.increaseAddonQuantity(index),
            onDecrease: () => provider.decreaseAddonQuantity(index),
          ),
        ),
      ),
    );
  }
}

class _AddonItem extends StatelessWidget {
  final AddonItem addon;
  final VoidCallback onToggle;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _AddonItem({
    required this.addon,
    required this.onToggle,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final controlWidth = constraints.maxWidth < 300
            ? _addonControlMinWidth
            : _addonControlMaxWidth;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _AddonIcon(icon: addon.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      addon.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatAddonPrice(addon),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: controlWidth,
                child: addon.isPerPax
                    ? _QuantityStepper(
                        quantity: addon.quantity,
                        onIncrease: onIncrease,
                        onDecrease: onDecrease,
                      )
                    : _CompactSwitch(
                        value: addon.isSelected,
                        onChanged: onToggle,
                      ),
              ),
            ],
          ),
        );
      },
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

  String _formatAddonPrice(AddonItem addon) {
    final price = '+ Rp ${_formatRupiah(addon.pricePerNight)}';
    return addon.isPerPax ? '$price / pax / night' : price;
  }
}

class _AddonIcon extends StatelessWidget {
  final IconData icon;

  const _AddonIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 21, color: const Color(0xFF2E7D32)),
    );
  }
}

class _CompactSwitch extends StatelessWidget {
  final bool value;
  final VoidCallback onChanged;

  const _CompactSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: value,
      child: GestureDetector(
        onTap: onChanged,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: _addonControlHeight,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(_addonControlHeight / 2),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _QuantityStepper({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrease = quantity > 0;

    return Container(
      width: double.infinity,
      height: _addonControlHeight,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _StepperButton(
            icon: Icons.remove,
            enabled: canDecrease,
            onPressed: onDecrease,
          ),
          SizedBox(
            width: 24,
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          _StepperButton(icon: Icons.add, onPressed: onIncrease),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _StepperButton({
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: enabled ? const Color(0xFF2E7D32) : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
