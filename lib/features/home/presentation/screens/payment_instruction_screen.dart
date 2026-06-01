import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/room_info_card.dart';
import '../../../../shared/widgets/trip_info.dart';

class PaymentInstructionScreen extends StatelessWidget {
  final String hotelName;
  final String roomType;
  final double rating;
  final String imageUrl;
  final DateTime checkIn;
  final DateTime checkOut;
  final int jumlahMalam;
  final String paymentMethodId;
  final String paymentMethodName;
  final String? paymentId;
  final double totalPayment;

  const PaymentInstructionScreen({
    super.key,
    required this.hotelName,
    required this.roomType,
    required this.rating,
    required this.imageUrl,
    required this.checkIn,
    required this.checkOut,
    required this.jumlahMalam,
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.totalPayment,
    this.paymentId,
  });

  String get _paymentReference {
    final source = paymentId == null || paymentId!.isEmpty
        ? 'PITULUNGAN-${DateTime.now().millisecondsSinceEpoch}'
        : paymentId!;
    return source.padLeft(8, '0').toUpperCase();
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0EA554),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Payment',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            RoomInfoCard(
              hotelName: hotelName,
              roomType: roomType,
              rating: rating,
              imageUrl: imageUrl,
            ),
            const SizedBox(height: 12),
            TripInfoSection(
              checkIn: checkIn,
              checkOut: checkOut,
              jumlahMalam: jumlahMalam,
            ),
            const SizedBox(height: 16),
            _PaymentMethodBody(
              methodId: paymentMethodId,
              methodName: paymentMethodName,
              reference: _paymentReference,
              amount: _formatRupiah(totalPayment),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment status is still pending.'),
                        backgroundColor: Color(0xFF0EA554),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCDEFE0),
                    foregroundColor: const Color(0xFF0EA554),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Check Status',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA554),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodBody extends StatelessWidget {
  final String methodId;
  final String methodName;
  final String reference;
  final String amount;

  const _PaymentMethodBody({
    required this.methodId,
    required this.methodName,
    required this.reference,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    if (methodId == 'credit_card') {
      return _CreditCardPayment(reference: reference, amount: amount);
    }

    if (methodId == 'ewallet') {
      return _EWalletPayment(reference: reference, amount: amount);
    }

    return _QrisPayment(
      title: methodName.toUpperCase(),
      reference: reference,
      amount: amount,
    );
  }
}

class _QrisPayment extends StatelessWidget {
  final String title;
  final String reference;
  final String amount;

  const _QrisPayment({
    required this.title,
    required this.reference,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: CustomPaint(
              size: const Size.square(190),
              painter: _QrCodePainter(reference),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            amount,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Ref $reference',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _CreditCardPayment extends StatelessWidget {
  final String reference;
  final String amount;

  const _CreditCardPayment({
    required this.reference,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF263238),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.credit_card, color: Colors.white, size: 34),
                const SizedBox(height: 28),
                Text(
                  'PAYMENT REF',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reference,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _InstructionRow(
            icon: Icons.lock_outline,
            title: 'Credit Card',
            subtitle: 'Complete the card authorization for this transaction.',
          ),
          const SizedBox(height: 14),
          _AmountPanel(amount: amount),
        ],
      ),
    );
  }
}

class _EWalletPayment extends StatelessWidget {
  final String reference;
  final String amount;

  const _EWalletPayment({
    required this.reference,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final expiry = DateFormat('HH:mm').format(
      DateTime.now().add(const Duration(minutes: 30)),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 58,
            color: Color(0xFF0EA554),
          ),
          const SizedBox(height: 12),
          const Text(
            'E-Wallet Payment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Use this payment code before $expiry',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          _CodeBox(label: 'Payment Code', value: reference),
          const SizedBox(height: 14),
          _InstructionRow(
            icon: Icons.storefront,
            title: 'Merchant',
            subtitle: 'Pitulungan Inn',
          ),
          const SizedBox(height: 14),
          _AmountPanel(amount: amount),
        ],
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  final String label;
  final String value;

  const _CodeBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InstructionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F6EF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0EA554), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountPanel extends StatelessWidget {
  final String amount;

  const _AmountPanel({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6EF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Total Payment',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0EA554),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCodePainter extends CustomPainter {
  final String seed;

  const _QrCodePainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 29;
    final black = Paint()..color = Colors.black;

    void drawCell(int x, int y) {
      canvas.drawRect(
        Rect.fromLTWH(x * cell, y * cell, cell, cell),
        black,
      );
    }

    void drawFinder(int startX, int startY) {
      for (var y = 0; y < 7; y++) {
        for (var x = 0; x < 7; x++) {
          final isOuter = x == 0 || y == 0 || x == 6 || y == 6;
          final isInner = x >= 2 && x <= 4 && y >= 2 && y <= 4;
          if (isOuter || isInner) drawCell(startX + x, startY + y);
        }
      }
    }

    drawFinder(0, 0);
    drawFinder(22, 0);
    drawFinder(0, 22);

    var hash = seed.hashCode.abs();
    for (var y = 0; y < 29; y++) {
      for (var x = 0; x < 29; x++) {
        final inTopLeft = x < 8 && y < 8;
        final inTopRight = x > 20 && y < 8;
        final inBottomLeft = x < 8 && y > 20;
        if (inTopLeft || inTopRight || inBottomLeft) continue;

        hash = (hash * 1103515245 + 12345) & 0x7fffffff;
        final shouldFill = ((hash + x * 3 + y * 5) % 7) < 3;
        if (shouldFill) drawCell(x, y);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCodePainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}
