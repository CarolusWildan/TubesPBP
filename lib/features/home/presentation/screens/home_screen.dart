import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../../../shared/models/hotel_model.dart';
import '../../../../shared/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import 'detail_kamar_screen.dart';
import 'pencarian&daftarhotel_screen.dart';

const _kPrimaryColor = Color(0xFF0EA554);
const _kBackgroundColor = Color(0xFFF8F9FA);
const _kCardBackground = Colors.white;
const _kShadowColor = Color(0x1F000000);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadHomeData();
    });
  }

  String? _resolveImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final imagePath = value.trim();
    final uri = Uri.tryParse(imagePath);
    if (uri != null && uri.hasScheme) return imagePath;

    final serverUrl = ApiClient.serverUrl;
    if (imagePath.startsWith('/')) return '$serverUrl$imagePath';
    return '$serverUrl/storage/$imagePath';
  }

  HotelModel? _firstHotelInCity(List<HotelModel> hotels, String city) {
    for (final hotel in hotels) {
      if (hotel.kota.trim() == city) return hotel;
    }
    return null;
  }

  Widget _hotelImage(String? imageUrl, {double? width, double? height}) {
    final resolvedUrl = _resolveImageUrl(imageUrl);

    if (resolvedUrl == null) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.hotel, color: Color(0xFF0EA554), size: 32),
      );
    }

    return Image.network(
      resolvedUrl,
      headers: kIsWeb ? null : ApiClient.imageHeaders,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: const Color(0xFFE8F5E9),
          child: const Icon(Icons.broken_image, color: Color(0xFF0EA554)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final authProvider = context.watch<AuthProvider>();

    final userName = authProvider.user?.fullName.split(' ').first ?? 'Guest';

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: homeProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _kPrimaryColor),
            )
          : RefreshIndicator(
              color: const Color(0xFF0EA554),
              onRefresh: homeProvider.loadHomeData,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    expandedHeight: 240,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0EA554), Color(0xFF22C36B)],
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(30),
                        ),
                      ),
                    ),
                    titleSpacing: 0,
                    automaticallyImplyLeading: false,
                    title: Padding(
                      padding: const EdgeInsets.only(
                        top: 16,
                        right: 24,
                        left: 24,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text(
                              'Find Your Hotel',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white,
                            foregroundImage:
                                _resolveImageUrl(
                                      authProvider.user?.userImage,
                                    ) !=
                                    null
                                ? NetworkImage(
                                    _resolveImageUrl(
                                      authProvider.user?.userImage,
                                    )!,
                                  )
                                : null,
                            child: authProvider.user?.userImage == null
                                ? Text(
                                    userName.isEmpty
                                        ? 'G'
                                        : userName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: _kPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                    iconTheme: const IconThemeData(color: Colors.white),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(170),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(0xFFD9D9D9),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 18),
                                  const Icon(
                                    Icons.search,
                                    color: _kPrimaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const PencarianDaftarHotelScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Search hotels or destinations...',
                                        style: TextStyle(
                                          color: Color(0xFF9E9E9E),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    margin: const EdgeInsets.only(right: 14),
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F2F2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Curated Destinations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Discover premier escapes to begin your journey.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 190,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              itemCount: homeProvider.destinationCities.length,
                              itemBuilder: (context, index) {
                                final city =
                                    homeProvider.destinationCities[index];
                                final sampleHotel = _firstHotelInCity(
                                  homeProvider.hotels,
                                  city,
                                );
                                final totalHotels = homeProvider.hotels
                                    .where((hotel) => hotel.kota.trim() == city)
                                    .length;

                                return Container(
                                  width: 190,
                                  margin: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: _hotelImage(
                                            sampleHotel?.hotelImage,
                                            width: double.infinity,
                                            height: 190,
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black.withOpacity(
                                                    0.22,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 16,
                                          right: 16,
                                          bottom: 16,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                city,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '$totalHotels hotel tersedia',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _HomeContent(
                      errorMessage: homeProvider.errorMessage,
                      hotels: homeProvider.hotels,
                      destinationCities: homeProvider.destinationCities,
                      firstHotelInCity: _firstHotelInCity,
                      hotelImage: _hotelImage,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.errorMessage,
    required this.hotels,
    required this.destinationCities,
    required this.firstHotelInCity,
    required this.hotelImage,
  });

  final String? errorMessage;
  final List<HotelModel> hotels;
  final List<String> destinationCities;
  final HotelModel? Function(List<HotelModel> hotels, String city)
  firstHotelInCity;
  final Widget Function(String? imageUrl, {double? width, double? height})
  hotelImage;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        child: Center(
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (hotels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 80, 24, 24),
        child: Center(
          child: Text(
            'Data hotel belum tersedia.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Hotels',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Available stays for you with best rate',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 18),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: hotels.length,
                itemBuilder: (context, index) {
                  final hotel = hotels[index];
                  return _HotelListItem(hotel: hotel, hotelImage: hotelImage);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _HotelListItem extends StatelessWidget {
  const _HotelListItem({required this.hotel, required this.hotelImage});

  final HotelModel hotel;
  final Widget Function(String? imageUrl, {double? width, double? height})
  hotelImage;

  @override
  Widget build(BuildContext context) {
    final location = [
      hotel.alamat,
      hotel.kota,
    ].where((value) => value.trim().isNotEmpty).join(', ');
    final rating = hotel.rating;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailKamarScreen(hotel: hotel)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBackground,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _kShadowColor,
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: hotelImage(hotel.hotelImage, width: 108, height: 108),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.namaHotel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location.isEmpty ? '-' : location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (rating != null)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _kPrimaryColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: _kPrimaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _kPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hotel.minPrice != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Mulai dari Rp ${hotel.minPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  if (hotel.minPrice != null && rating == null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Mulai dari Rp ${hotel.minPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  if (hotel.facilityNames.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hotel.facilityNames.take(3).map((facility) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8F4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            facility,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4B6E53),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
