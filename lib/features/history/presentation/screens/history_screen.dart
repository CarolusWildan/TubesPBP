import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../shared/network/api_client.dart';
import '../../../../shared/models/booking_history_model.dart';
import '../widgets/history_booking_card.dart';
import '../widgets/history_empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'history_detail_screen.dart';

typedef HistoryBookingItem = BookingHistoryModel;

class HistoryScreen extends StatefulWidget {
  final BookingHistoryModel? latestBooking;

  const HistoryScreen({super.key, this.latestBooking});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  bool _isLoading = true;
  String? _errorMessage;
  List<BookingHistoryModel> _bookings = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  List<BookingHistoryModel> get _filteredBookings {
    final keyword = _searchController.text.trim().toLowerCase();
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.idUser;

    return _bookings.where((booking) {
      if (!booking.belongsToUser(currentUserId)) {
        return false;
      }

      final matchesSearch = keyword.isEmpty ||
          booking.hotelName.toLowerCase().contains(keyword) ||
          booking.location.toLowerCase().contains(keyword);

      final matchesFilter = _selectedFilter == 'All' ||
          booking.paymentStatus.toLowerCase().contains(
                _selectedFilter.toLowerCase(),
              );

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = context.read<ApiClient>();
      final authProvider = context.read<AuthProvider>();
      final fetchedBookings = await _fetchHistoryItems(
        apiClient,
        authProvider.user?.idUser,
      );

      if (!mounted) return;
      setState(() {
        _bookings = _mergeBookings(fetchedBookings);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bookings = _mergeBookings(const []);
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<List<BookingHistoryModel>> _fetchHistoryItems(
    ApiClient apiClient,
    String? userId,
  ) async {
    try {
      final response = await apiClient.get('/bookings');
      return _extractList(response)
          .whereType<Map<String, dynamic>>()
          .map(BookingHistoryModel.fromJson)
          .where((booking) => booking.belongsToUser(userId))
          .toList();
    } catch (_) {
      final response = await apiClient.get('/payments');
      return _extractList(response)
          .whereType<Map<String, dynamic>>()
          .map(BookingHistoryModel.fromPaymentJson)
          .where((booking) => booking.belongsToUser(userId))
          .toList();
    }
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      if (response['items'] is List) return response['items'] as List;
      if (response['payments'] is List) return response['payments'] as List;
    }
    return const [];
  }

  List<BookingHistoryModel> _mergeBookings(List<BookingHistoryModel> fetched) {
    final merged = <String, BookingHistoryModel>{};

    if (widget.latestBooking != null) {
      merged[widget.latestBooking!.idPayment ?? '-'] = widget.latestBooking!;
    }

    for (final booking in fetched) {
      merged[booking.idPayment ?? '-'] = booking;
    }

    return merged.values.toList()
      ..sort((a, b) => b.checkIn.compareTo(a.checkIn));
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _filteredBookings;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Column(
        children: [
          _HistoryHeader(
            searchController: _searchController,
            onSearchChanged: (_) => setState(() {}),
          ),
          _HistoryFilterBar(
            selectedFilter: _selectedFilter,
            onSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0EA554)),
                  )
                : bookings.isEmpty
                    ? HistoryEmptyState(
                        selectedFilter: _selectedFilter,
                        errorMessage: _errorMessage,
                        onRetry: _loadHistory,
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF0EA554),
                        onRefresh: _loadHistory,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                          children: [
                            if (_errorMessage != null) ...[
                              _HistoryNotice(
                                message:
                                    'History terbaru belum bisa diambil. Menampilkan data terakhir.',
                                onRetry: _loadHistory,
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              DateFormat('MMMM yyyy').format(bookings.first.checkIn),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...bookings.map(
                              (booking) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: HistoryBookingCard(
                                  booking: booking,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HistoryDetailScreen(
                                            booking: booking),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _HistoryHeader({
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 20),
      color: const Color(0xFF0EA554),
      child: Column(
        children: [
          const Text(
            'History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Bali, Indonesia',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey.shade400,
                size: 25,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  const _HistoryFilterBar({
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Filter:',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'All',
                  'Success',
                  'Pending',
                  'Cancel',
                ].map(_buildFilterChip).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = selectedFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(filter),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) => onSelected(filter),
        selectedColor: const Color(0xFF0EA554),
        backgroundColor: const Color(0xFFF2F4F7),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

class _HistoryNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HistoryNotice({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE599)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFF1C40F), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7F6000),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF7F6000), size: 18),
            onPressed: onRetry,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}