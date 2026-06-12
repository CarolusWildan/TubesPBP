import 'package:flutter/material.dart';

class HistoryNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const HistoryNotice({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF8A00), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, color: Color(0xFF7A4B00)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class HistoryEmptyState extends StatelessWidget {
  final String selectedFilter;
  final String? errorMessage;
  final VoidCallback onRetry;

  const HistoryEmptyState({
    super.key,
    required this.selectedFilter,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.luggage_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              errorMessage ??
                  (selectedFilter == 'All'
                      ? 'No booking history yet'
                      : 'No $selectedFilter booking found'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 10),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
