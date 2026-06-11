import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/models/hotel_model.dart';
import '../../../../shared/models/room_model.dart';
import '../../../../shared/network/api_client.dart';
import 'booking_date_screen.dart';

const _kPrimaryColor = Color(0xFF0EA554);
const _kBackgroundColor = Color(0xFFF6F7F9);
const _kCardShadow = Color(0x1A000000);

class DetailKamarScreen extends StatefulWidget {
  final HotelModel hotel;

  const DetailKamarScreen({super.key, required this.hotel});

  @override
  State<DetailKamarScreen> createState() => _DetailKamarScreenState();
}

class _DetailKamarScreenState extends State<DetailKamarScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<RoomModel> _rooms = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRooms();
    });
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = context.read<ApiClient>();
      final query = Uri(queryParameters: {'id_hotel': widget.hotel.idHotel}).query;
      final response = await apiClient.get('/rooms/available?$query');
      final rooms = _extractList(response)
          .whereType<Map<String, dynamic>>()
          .map(RoomModel.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      if (response['items'] is List) return response['items'] as List;
      if (response['rooms'] is List) return response['rooms'] as List;
    }
    return const [];
  }

  String? _resolveImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final imagePath = value.trim().replaceAll('\\', '/');
    final uri = Uri.tryParse(imagePath);
    if (uri != null && uri.hasScheme) return imagePath;

    final serverUrl = ApiClient.serverUrl;
    if (imagePath.startsWith('/')) return '$serverUrl$imagePath';
    if (imagePath.startsWith('storage/')) return '$serverUrl/$imagePath';
    return '$serverUrl/storage/$imagePath';
  }

  Widget _networkImage(String? value, {double? width, double? height}) {
    final imageUrl = _resolveImageUrl(value);

    if (imageUrl == null) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.king_bed_outlined, color: _kPrimaryColor),
      );
    }

    return Image.network(
      imageUrl,
      headers: kIsWeb ? null : ApiClient.imageHeaders,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: const Color(0xFFE8F5E9),
          child: const Icon(Icons.broken_image, color: _kPrimaryColor),
        );
      },
    );
  }

  String _formatRupiah(double amount) {
    if (amount <= 0) return 'Rp -';
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: RefreshIndicator(
        color: _kPrimaryColor,
        onRefresh: _loadRooms,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 250,
              backgroundColor: _kPrimaryColor,
              foregroundColor: Colors.white,
              title: const Text(
                'Daftar & Detail Kamar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _networkImage(widget.hotel.hotelImage),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.08),
                            Colors.black.withOpacity(0.58),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.hotel.namaHotel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _hotelLocation,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HotelSummary(
                      hotel: widget.hotel,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available Rooms',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          '${_rooms.length} options',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildRoomContent(),
                    const SizedBox(height: 22),
                    _GuestReviewSection(hotelName: widget.hotel.namaHotel),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _hotelLocation {
    final parts = [
      widget.hotel.alamat,
      widget.hotel.kota,
    ].where((value) => value.trim().isNotEmpty);
    return parts.isEmpty ? 'Location unavailable' : parts.join(', ');
  }

  Widget _buildRoomContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 44),
        child: Center(child: CircularProgressIndicator(color: _kPrimaryColor)),
      );
    }

    if (_errorMessage != null) {
      return _StateBox(
        icon: Icons.wifi_off_outlined,
        title: 'Room data belum bisa dimuat',
        message: _errorMessage!,
        actionLabel: 'Retry',
        onAction: _loadRooms,
      );
    }

    if (_rooms.isEmpty) {
      return _StateBox(
        icon: Icons.bedroom_parent_outlined,
        title: 'Kamar belum tersedia',
        message: 'Belum ada kamar available untuk hotel ini.',
        actionLabel: 'Refresh',
        onAction: _loadRooms,
      );
    }

    return Column(
      children: List.generate(_rooms.length, (index) {
        final room = _rooms[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index == _rooms.length - 1 ? 0 : 14),
          child: _RoomCard(
            room: room,
            image: _networkImage(room.roomImage ?? widget.hotel.hotelImage),
            priceText: _formatRupiah(room.pricePerNight),
            roomsLeftText: _rooms.length <= 2 ? 'Only ${_rooms.length} rooms left!' : null,
            onChoose: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingDateScreen(
                    hotel: widget.hotel,
                    room: room,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _HotelSummary extends StatelessWidget {
  final HotelModel hotel;

  const _HotelSummary({required this.hotel});

  @override
  Widget build(BuildContext context) {
    final facilities = hotel.facilityNames
        .where((facility) => facility.trim().isNotEmpty)
        .toList();
    final mainFacilities = facilities.isEmpty
        ? const ['Free Wifi', 'Breakfast', 'Outdoor pool', 'Airport shuttle (free)']
        : facilities.take(4).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StarRatingRow(),
                    const SizedBox(height: 10),
                    Text(
                      hotel.namaHotel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF2563EB),
                        decorationThickness: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _RatingBadge(rating: hotel.rating ?? 4.9),
            ],
          ),
          const SizedBox(height: 36),
          const Text(
            'About the Property',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          RichText(
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
              children: [
                TextSpan(text: _aboutText),
                const TextSpan(
                  text: ' Read more...',
                  style: TextStyle(
                    color: _kPrimaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Main Facilities',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mainFacilities.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 38,
              crossAxisSpacing: 18,
            ),
            itemBuilder: (context, index) {
              final facility = mainFacilities[index];
              return _FacilityItem(name: facility);
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () => _showAllFacilities(context, facilities),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimaryColor,
                side: const BorderSide(color: Color(0xFF9CA3AF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'View All Facilities',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _kPrimaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _locationText {
    final parts = [
      hotel.alamat,
      hotel.kota,
    ].where((value) => value.trim().isNotEmpty);
    return parts.isEmpty ? 'Location unavailable' : parts.join(', ');
  }

  String get _aboutText {
    final description = (hotel.deskripsi ?? '').trim();
    if (description.isNotEmpty) return description;
    return 'Staying at ${hotel.namaHotel} is a good choice when you are visiting ${hotel.kota.isEmpty ? 'this destination' : hotel.kota}. 24-hours front desk is available to serve you, from check-in to check-out,';
  }

  void _showAllFacilities(BuildContext context, List<String> facilities) {
    final facilityList = facilities.isEmpty
        ? const ['Free Wifi', 'Breakfast', 'Outdoor pool', 'Airport shuttle (free)']
        : facilities;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'All Facilities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: facilityList.length,
                    separatorBuilder: (_, __) => const Divider(height: 18),
                    itemBuilder: (context, index) {
                      return _FacilityItem(name: facilityList[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StarRatingRow extends StatelessWidget {
  const _StarRatingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (_) => const Padding(
          padding: EdgeInsets.only(right: 2),
          child: Icon(Icons.star, color: Color(0xFFF4A51C), size: 20),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFDDF5E7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: _kPrimaryColor,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '128 REVS',
            style: TextStyle(
              color: _kPrimaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityItem extends StatelessWidget {
  final String name;

  const _FacilityItem({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Icon(_iconForFacility(name), color: Colors.black, size: 24),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconForFacility(String value) {
    final name = value.toLowerCase();
    if (name.contains('wifi')) return Icons.wifi;
    if (name.contains('breakfast') || name.contains('restaurant')) {
      return Icons.free_breakfast_outlined;
    }
    if (name.contains('pool') || name.contains('swim')) return Icons.pool;
    if (name.contains('airport') || name.contains('shuttle')) {
      return Icons.airport_shuttle;
    }
    if (name.contains('parking')) return Icons.local_parking;
    if (name.contains('spa')) return Icons.spa_outlined;
    if (name.contains('gym') || name.contains('fitness')) {
      return Icons.fitness_center;
    }
    return Icons.check_circle_outline;
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  final Widget image;
  final String priceText;
  final String? roomsLeftText;
  final VoidCallback onChoose;

  const _RoomCard({
    required this.room,
    required this.image,
    required this.priceText,
    required this.onChoose,
    this.roomsLeftText,
  });

  @override
  Widget build(BuildContext context) {
    final roomName = room.roomType?.namaType.trim().isNotEmpty == true
        ? room.roomType!.namaType
        : 'Room ${room.nomorKamar}';
    final capacity = room.capacity <= 0 ? 2 : room.capacity;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: _kCardShadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(aspectRatio: 16 / 9, child: image),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        roomName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusPill(status: room.status),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      color: Color(0xFF6B7280),
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '$capacity Guests',
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (roomsLeftText != null) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          roomsLeftText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if ((room.roomType?.deskripsi ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    room.roomType!.deskripsi!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            priceText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            '/ night, taxes incl.',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: onChoose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Text(
                          'Choose',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final RoomStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == RoomStatus.available;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAvailable ? 'Available' : status.name,
        style: TextStyle(
          color: isAvailable ? _kPrimaryColor : const Color(0xFFC2410C),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GuestReviewSection extends StatelessWidget {
  final String hotelName;

  const _GuestReviewSection({required this.hotelName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guest Reviews',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '"A comfortable stay at $hotelName with helpful service and a room that is ready for a relaxing trip."',
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StateBox({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: _kPrimaryColor, size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimaryColor,
              side: const BorderSide(color: _kPrimaryColor),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
