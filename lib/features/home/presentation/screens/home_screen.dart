import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/models/hotel_model.dart';
import '../../../../shared/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/home_provider.dart';

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

    final serverUrl = ApiClient.baseUrl.replaceFirst('/api', '');
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: homeProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0EA554)),
            )
          : RefreshIndicator(
              color: const Color(0xFF0EA554),
              onRefresh: homeProvider.loadHomeData,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    backgroundColor: const Color(0xFF0EA554),
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 90,
                    titleSpacing: 24,
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Find Your Hotel\n$userName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white24,
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/150?img=11',
                          ),
                        ),
                      ],
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: Container(
                        transform: Matrix4.translationValues(0, 25, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'Search hotels or destinations...',
                              hintStyle: TextStyle(
                                color: Colors.black45,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Color(0xFF0EA554),
                              ),
                              suffixIcon: Icon(
                                Icons.cancel,
                                color: Colors.black38,
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                        ),
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
        const SizedBox(height: 50),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
              const SizedBox(height: 4),
              const Text(
                'Discover cities from available hotels.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: destinationCities.length,
                  itemBuilder: (context, index) {
                    final city = destinationCities[index];
                    final sampleHotel = firstHotelInCity(hotels, city);
                    final totalHotels = hotels
                        .where((hotel) => hotel.kota.trim() == city)
                        .length;

                    return Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: hotelImage(
                              sampleHotel?.hotelImage,
                              height: 110,
                              width: double.infinity,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  city,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$totalHotels hotel tersedia',
                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hotels',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Available stays from Laravel API.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
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
    final location = [hotel.alamat, hotel.kota]
        .where((value) => value.trim().isNotEmpty)
        .join(', ');
    final rating = hotel.rating;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hotelImage(hotel.hotelImage, width: 100, height: 100),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location.isEmpty ? '-' : location,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (rating != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                if (hotel.facilityNames.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    hotel.facilityNames.take(3).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
