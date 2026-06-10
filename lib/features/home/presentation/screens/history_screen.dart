import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/network/api_client.dart';

class HistoryBookingItem {
  final String orderId;
  final String hotelName;
  final String location;
  final String imageUrl;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalPayment;
  final String paymentStatus;
  final String reviewStatus;

  const HistoryBookingItem({
    required this.orderId,
    required this.hotelName,
    required this.location,
    required this.imageUrl,
    required this.checkIn,
    required this.checkOut,
    required this.totalPayment,
    this.paymentStatus = 'Payment Pending',
    this.reviewStatus = 'Not Reviewed',
  });
}

class HistoryScreen extends StatefulWidget {
  final HistoryBookingItem? latestBooking;

  const HistoryScreen({super.key, this.latestBooking});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  bool _isLoading = true;
  String? _errorMessage;
  List<HistoryBookingItem> _bookings = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  List<HistoryBookingItem> get _filteredBookings {
    final keyword = _searchController.text.trim().toLowerCase();

    return _bookings.where((booking) {
      final matchesSearch =
          keyword.isEmpty ||
          booking.hotelName.toLowerCase().contains(keyword) ||
          booking.location.toLowerCase().contains(keyword);
      final matchesFilter =
          _selectedFilter == 'All' ||
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
      final payments = await _loadEndpointList(apiClient, '/payments');
      final bookings = await _loadEndpointList(apiClient, '/bookings');
      final hotels = await _loadEndpointList(apiClient, '/hotels');
      final hotelLookup = _buildLookup(hotels, const ['id_hotel', 'id']);
      final paymentLookup = _buildPaymentLookup(payments);
      final fetchedBookings = bookings.isNotEmpty
          ? _parseBookingHistoryItems(
              bookings,
              currentUserId: authProvider.user?.idUser,
              hotelLookup: hotelLookup,
              paymentLookup: paymentLookup,
            )
          : _parsePaymentHistoryItems(
              payments,
              currentUserId: authProvider.user?.idUser,
              hotelLookup: hotelLookup,
            );

      if (bookings.isEmpty && payments.isEmpty) {
        throw Exception('Data history booking belum tersedia dari server.');
      }

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

  List<HistoryBookingItem> _mergeBookings(List<HistoryBookingItem> fetched) {
    final merged = <String, HistoryBookingItem>{};

    if (widget.latestBooking != null) {
      merged[widget.latestBooking!.orderId] = widget.latestBooking!;
    }

    for (final booking in fetched) {
      merged[booking.orderId] = booking;
    }

    final result = merged.values.toList()
      ..sort((a, b) => b.checkIn.compareTo(a.checkIn));
    return result;
  }

  List<HistoryBookingItem> _parseHistoryItems(
    dynamic response, {
    required String? currentUserId,
    required Map<String, Map<String, dynamic>> hotelLookup,
  }) {
    final rawItems = _extractList(response);

    return rawItems
        .whereType<Map<String, dynamic>>()
        .where((item) => _belongsToCurrentUser(item, currentUserId))
        .map((item) => _historyItemFromJson(item, hotelLookup))
        .toList();
  }

  Future<Map<String, Map<String, dynamic>>> _loadHotelLookup(
    ApiClient apiClient,
  ) async {
    try {
      final response = await apiClient.get('/hotels');
      final hotels = _extractList(response).whereType<Map<String, dynamic>>();
      return {
        for (final hotel in hotels)
          if ((hotel['id_hotel'] ?? hotel['id']) != null)
            (hotel['id_hotel'] ?? hotel['id']).toString(): hotel,
      };
    } catch (_) {
      return const {};
    }
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      if (response['payments'] is List) return response['payments'] as List;
      if (response['items'] is List) return response['items'] as List;
    }
    return const [];
  }

  bool _belongsToCurrentUser(
    Map<String, dynamic> payment,
    String? currentUserId,
  ) {
    if (currentUserId == null || currentUserId.isEmpty) return true;

    final booking = _asMap(payment['booking']);
    final rawUserId =
        booking?['id_user'] ??
        booking?['user_id'] ??
        _findValue(payment, const ['id_user', 'user_id']) ??
        payment['id_user'] ??
        payment['user_id'];

    if (rawUserId == null) return true;
    return rawUserId.toString() == currentUserId;
  }

  HistoryBookingItem _historyItemFromJson(
    Map<String, dynamic> payment,
    Map<String, Map<String, dynamic>> hotelLookup,
  ) {
    final booking = _asMap(payment['booking']);
    final hotelId =
        (booking?['id_hotel'] ??
                booking?['hotel_id'] ??
                _findValue(payment, const ['id_hotel', 'hotel_id']) ??
                payment['id_hotel'] ??
                payment['hotel_id'])
            ?.toString();
    final hotel =
        _asMap(booking?['hotel']) ??
        _asMap(payment['hotel']) ??
        _findHotelMap(payment) ??
        (hotelId == null ? null : hotelLookup[hotelId]);

    final paymentId = (payment['id_payment'] ?? payment['id'])?.toString();
    final bookingId = (payment['id_booking'] ?? booking?['id_booking'])
        ?.toString();
    final checkIn = _parseDate(booking?['check_in']) ?? DateTime.now();
    final checkOut =
        _parseDate(booking?['check_out']) ??
        checkIn.add(const Duration(days: 1));

    return HistoryBookingItem(
      orderId: paymentId ?? bookingId ?? '-',
      hotelName: _firstText([
        hotel?['nama_hotel'],
        hotel?['hotel_name'],
        hotel?['name'],
        hotel?['nama'],
        booking?['nama_hotel'],
        booking?['hotel_name'],
        payment['nama_hotel'],
        payment['hotel_name'],
        _findValue(payment, const ['nama_hotel', 'hotel_name', 'namaHotel']),
      ], fallback: 'Hotel booking'),
      location:
          (hotel?['kota'] ?? hotel?['alamat'] ?? booking?['kota'])
              ?.toString() ??
          'Booking',
      imageUrl: _resolveImageUrl(
        (hotel?['hotel_image'] ??
                hotel?['image'] ??
                hotel?['image_url'] ??
                booking?['hotel_image'] ??
                _findValue(payment, const [
                  'hotel_image',
                  'image_url',
                  'image',
                ]))
            ?.toString(),
      ),
      checkIn: checkIn,
      checkOut: checkOut,
      totalPayment: _toDouble(
        payment['jumlah_bayar'] ?? booking?['total_harga'],
      ),
      paymentStatus: _formatPaymentStatus(payment['status_pembayaran']),
    );
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Map<String, dynamic>? _findHotelMap(dynamic value) {
    if (value is List) {
      for (final item in value) {
        final match = _findHotelMap(item);
        if (match != null) return match;
      }
      return null;
    }

    final map = _asMap(value);
    if (map == null) return null;

    final hasHotelName =
        map.containsKey('nama_hotel') ||
        map.containsKey('hotel_name') ||
        map.containsKey('namaHotel');
    final hasHotelId =
        map.containsKey('id_hotel') || map.containsKey('hotel_id');

    if (hasHotelName || hasHotelId) return map;

    for (final item in map.values) {
      final match = _findHotelMap(item);
      if (match != null) return match;
    }

    return null;
  }

  dynamic _findValue(dynamic value, List<String> keys) {
    if (value is List) {
      for (final item in value) {
        final match = _findValue(item, keys);
        if (match != null) return match;
      }
      return null;
    }

    final map = _asMap(value);
    if (map == null) return null;

    for (final key in keys) {
      final direct = map[key];
      if (direct != null) return direct;
    }

    for (final item in map.values) {
      final match = _findValue(item, keys);
      if (match != null) return match;
    }

    return null;
  }

  String _firstText(List<dynamic> values, {required String fallback}) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty && text != 'null') return text;
    }
    return fallback;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatPaymentStatus(dynamic value) {
    final status = value?.toString().toLowerCase() ?? 'pending';
    if (status.contains('success') || status.contains('paid')) {
      return 'Payment Success';
    }
    if (status.contains('cancel') || status.contains('failed')) {
      return 'Payment Cancel';
    }
    return 'Payment Pending';
  }

  String _resolveImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400';
    }

    final imagePath = value.trim().replaceAll('\\', '/');
    final uri = Uri.tryParse(imagePath);
    if (uri != null && uri.hasScheme) return imagePath;

    final serverUrl = ApiClient.serverUrl;
    if (imagePath.startsWith('/')) return '$serverUrl$imagePath';
    return '$serverUrl/storage/$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _filteredBookings;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF0EA554),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
            ),
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
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Bali, Indonesia',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
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
          ),
          Container(
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
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0EA554)),
                  )
                : bookings.isEmpty
                ? _EmptyHistory(
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
                          DateFormat(
                            'MMMM yyyy',
                          ).format(bookings.first.checkIn),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...bookings.map(
                          (booking) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _HistoryBookingCard(booking: booking),
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

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(filter),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) {
          setState(() {
            _selectedFilter = filter;
          });
        },
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

class _HistoryBookingCard extends StatelessWidget {
  final HistoryBookingItem booking;

  const _HistoryBookingCard({required this.booking});

  String get _safeImageUrl {
    final cleanedUrl = booking.imageUrl.trim().replaceAll('\\', '/');
    if (cleanedUrl.isEmpty) {
      return 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400';
    }
    return Uri.encodeFull(cleanedUrl);
  }

  bool get _isPending =>
      booking.paymentStatus.toLowerCase().contains('pending');

  String _formatDateRange() {
    final start = DateFormat('d').format(booking.checkIn);
    final end = DateFormat('d MMM yyyy').format(booking.checkOut);
    return '$start - $end';
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ID: ${booking.orderId}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusPill(
                label: booking.paymentStatus,
                backgroundColor: _isPending
                    ? const Color(0xFFFFF0DF)
                    : const Color(0xFFE7F8EE),
                textColor: _isPending
                    ? const Color(0xFFFF8A00)
                    : const Color(0xFF0EA554),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _HistoryHotelImage(
                  imageUrl: _safeImageUrl,
                  width: 56,
                  height: 56,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.hotelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDateRange(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatRupiah(booking.totalPayment),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0EA554),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: _StatusPill(
                    label: booking.reviewStatus,
                    backgroundColor: const Color(0xFFFFF0DF),
                    textColor: const Color(0xFFFF6B3A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryHotelImage extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;

  const _HistoryHotelImage({
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  @override
  State<_HistoryHotelImage> createState() => _HistoryHotelImageState();
}

class _HistoryHotelImageState extends State<_HistoryHotelImage> {
  late Future<Uint8List?> _imageBytesFuture;

  @override
  void initState() {
    super.initState();
    _imageBytesFuture = _loadImageBytes();
  }

  @override
  void didUpdateWidget(covariant _HistoryHotelImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageBytesFuture = _loadImageBytes();
    }
  }

  Future<Uint8List?> _loadImageBytes() async {
    final uri = Uri.tryParse(widget.imageUrl);
    if (uri == null || !uri.hasScheme) return null;

    try {
      final response = await http.get(uri, headers: ApiClient.imageHeaders);
      final contentType = response.headers['content-type'] ?? '';
      final isImage = contentType.startsWith('image/');

      if (response.statusCode >= 200 && response.statusCode < 300 && isImage) {
        return response.bodyBytes;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _imageBytesFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null) {
          return Image.memory(
            bytes,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey.shade100,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          );
        }

        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.hotel, color: Colors.grey, size: 22),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HistoryNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HistoryNotice({required this.message, required this.onRetry});

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

class _EmptyHistory extends StatelessWidget {
  final String selectedFilter;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _EmptyHistory({
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
