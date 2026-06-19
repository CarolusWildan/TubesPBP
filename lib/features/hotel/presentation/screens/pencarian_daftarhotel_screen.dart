import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/geolocation_service.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../shared/models/hotel_model.dart';
import '../../../../shared/network/api_client.dart';
import '../../../home/presentation/providers/home_provider.dart';
import 'detail_kamar_screen.dart';

const _kPrimaryColor = Color(0xFF0EA554);
const _kBackgroundColor = Color(0xFFF8F9FA);
const _kCardBackground = Colors.white;
const _kShadowColor = Color(0x1F000000);

class PencarianDaftarHotelScreen extends StatefulWidget {
  const PencarianDaftarHotelScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<PencarianDaftarHotelScreen> createState() =>
      _PencarianDaftarHotelScreenState();
}

class _PencarianDaftarHotelScreenState
    extends State<PencarianDaftarHotelScreen> {
  late final TextEditingController _searchController;
  final GeolocationService _geolocationService = GeolocationService();
  final SpeechService _speechService = SpeechService();

  bool _isListening = false;
  bool _isLoadingLocation = false;
  String? _currentCity;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    final homeProvider = context.read<HomeProvider>();
    final initialQuery = widget.initialQuery?.trim();
    _searchController = TextEditingController(
      text: initialQuery?.isNotEmpty == true
          ? initialQuery
          : homeProvider.searchQuery,
    );
    _searchController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (initialQuery?.isNotEmpty == true) {
        homeProvider.updateSearchQuery(initialQuery!);
      }
      if (homeProvider.hotels.isEmpty) {
        homeProvider.loadHomeData();
      }
      _loadCurrentCity();
    });
  }

  @override
  void dispose() {
    _speechService.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startVoiceSearch() async {
    if (_isListening) {
      await _speechService.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);

    await _speechService.startSearchListening(
      onError: (message) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      onResult: (words, isFinal) {
        if (!mounted || words.isEmpty) return;

        _searchController.text = words;
        _searchController.selection = TextSelection.collapsed(
          offset: _searchController.text.length,
        );

        if (isFinal) {
          setState(() => _isListening = false);
          context.read<HomeProvider>().updateSearchQuery(words);
        }
      },
    );

    if (!mounted) return;
    if (!_speechService.isListening) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _loadCurrentCity() async {
    setState(() {
      _isLoadingLocation = true;
      _locationMessage = null;
    });

    final result = await _geolocationService.resolveCurrentCity();

    if (!mounted) return;
    setState(() {
      _isLoadingLocation = false;
      _currentCity = result.city;
      _locationMessage = result.message;
    });
  }

  void _submitSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      context.read<HomeProvider>().clearSearch();
      return;
    }
    context.read<HomeProvider>().updateSearchQuery(query);
  }

  List<HotelModel> _trendingHotelsForCurrentCity(List<HotelModel> hotels) {
    final city = _currentCity;
    if (city == null || city.trim().isEmpty) return const [];

    return hotels.where((hotel) {
      return _cityMatches(hotel.kota, city);
    }).take(6).toList();
  }

  List<HotelModel> _searchResults(List<HotelModel> hotels, String query) {
    final normalizedQuery = _normalizeCity(query);
    if (normalizedQuery.isEmpty) return hotels;

    final cityMatches = hotels.where((hotel) {
      return _cityMatches(hotel.kota, query);
    }).toList();

    if (cityMatches.isNotEmpty) return cityMatches;

    return hotels.where((hotel) {
      return [
        hotel.namaHotel,
        hotel.alamat,
        hotel.kota,
        hotel.deskripsi ?? '',
        ...hotel.facilityNames,
      ].any((value) => _normalizeCity(value).contains(normalizedQuery));
    }).toList();
  }

  bool _cityMatches(String hotelCity, String currentCity) {
    final hotelValue = _normalizeCity(hotelCity);
    final currentValue = _normalizeCity(currentCity);
    if (hotelValue.isEmpty || currentValue.isEmpty) return false;
    if (hotelValue.contains(currentValue) || currentValue.contains(hotelValue)) {
      return true;
    }

    final hotelAliases = _cityAliases(hotelValue);
    final currentAliases = _cityAliases(currentValue);
    return hotelAliases.any(currentAliases.contains);
  }

  Set<String> _cityAliases(String city) {
    final aliases = <String>{city};
    if (city.contains('yogyakarta') || city.contains('jogja')) {
      aliases.addAll({'yogyakarta', 'jogja'});
    }
    return aliases;
  }

  String _normalizeCity(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\b(kota|kabupaten|indonesia)\b'), '')
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
    final isSearching = _searchController.text.trim().isNotEmpty;
    final popularDestinations = _popularDestinations(homeProvider);
    final trendingHotels = _trendingHotelsForCurrentCity(homeProvider.hotels);
    final searchResults = _searchResults(
      homeProvider.hotels,
      _searchController.text,
    );

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: RefreshIndicator(
        color: _kPrimaryColor,
        onRefresh: homeProvider.loadHomeData,
        child: ListView(
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(context),
                        child: const SizedBox(
                          width: 40,
                          height: 44,
                          child: Icon(Icons.arrow_back, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD9D9D9)),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.search,
                                color: _kPrimaryColor,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  textInputAction: TextInputAction.search,
                                  onChanged: (value) {
                                    if (value.trim().isEmpty) {
                                      homeProvider.clearSearch();
                                    }
                                    setState(() {});
                                  },
                                  onSubmitted: _submitSearch,
                                  decoration: const InputDecoration(
                                    hintText: 'Where to?',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF9E9E9E),
                                      fontSize: 15,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.black45,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    homeProvider.clearSearch();
                                    setState(() {});
                                  },
                                ),
                              IconButton(
                                tooltip: _isListening
                                    ? 'Stop voice search'
                                    : 'Voice search',
                                icon: Icon(
                                  _isListening ? Icons.mic : Icons.mic_none,
                                  color: _isListening
                                      ? _kPrimaryColor
                                      : Colors.black45,
                                ),
                                onPressed: _startVoiceSearch,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (homeProvider.isLoading) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: CircularProgressIndicator(color: _kPrimaryColor),
                      ),
                    ),
                  ] else if (homeProvider.errorMessage != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          homeProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ] else if (!isSearching) ...[
                    _DiscoverySearchContent(
                      popularDestinations: popularDestinations,
                      trendingHotels: trendingHotels,
                      currentCity: _currentCity,
                      isLoadingLocation: _isLoadingLocation,
                      locationMessage: _locationMessage,
                      hotelImage: _hotelImage,
                      onDestinationTap: (city) {
                        _searchController.text = city;
                        _searchController.selection = TextSelection.collapsed(
                          offset: _searchController.text.length,
                        );
                        _submitSearch(city);
                        setState(() {});
                      },
                      onHotelTap: (hotel) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailKamarScreen(hotel: hotel),
                          ),
                        );
                      },
                    ),
                  ] else if (searchResults.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'Tidak ada hotel yang cocok untuk pencarian ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Search Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...searchResults.map(
                      (hotel) => _HotelSearchListItem(
                        hotel: hotel,
                        hotelImage: _hotelImage,
                      ),
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

  List<_PopularDestination> _popularDestinations(HomeProvider homeProvider) {
    const fallback = [
      _PopularDestination(
        city: 'Bali',
        country: 'Indonesia',
        subtitle: 'Island - Beaches & Culture',
      ),
      _PopularDestination(
        city: 'Yogyakarta',
        country: 'Indonesia',
        subtitle: 'City - Heritage & Culinary',
      ),
      _PopularDestination(
        city: 'Bandung',
        country: 'Indonesia',
        subtitle: 'City - Mountains & Shopping',
      ),
    ];

    final cities = homeProvider.destinationCities.take(3).toList();
    if (cities.isEmpty) return fallback;

    return cities.map((city) {
      final matchedFallback = fallback.where((item) {
        return _cityMatches(item.city, city);
      }).firstOrNull;

      return _PopularDestination(
        city: city,
        country: 'Indonesia',
        subtitle: matchedFallback?.subtitle ?? 'City - Hotels & Stays',
      );
    }).toList();
  }
}

class _PopularDestination {
  const _PopularDestination({
    required this.city,
    required this.country,
    required this.subtitle,
  });

  final String city;
  final String country;
  final String subtitle;
}

class _DiscoverySearchContent extends StatelessWidget {
  const _DiscoverySearchContent({
    required this.popularDestinations,
    required this.trendingHotels,
    required this.currentCity,
    required this.isLoadingLocation,
    required this.locationMessage,
    required this.hotelImage,
    required this.onDestinationTap,
    required this.onHotelTap,
  });

  final List<_PopularDestination> popularDestinations;
  final List<HotelModel> trendingHotels;
  final String? currentCity;
  final bool isLoadingLocation;
  final String? locationMessage;
  final Widget Function(String? imageUrl, {double? width, double? height})
  hotelImage;
  final ValueChanged<String> onDestinationTap;
  final ValueChanged<HotelModel> onHotelTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Destinations',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ...popularDestinations.map(
          (destination) => _PopularDestinationTile(
            destination: destination,
            onTap: () => onDestinationTap(destination.city),
          ),
        ),
        const SizedBox(height: 34),
        const Text(
          'Trending Hotels',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        if (isLoadingLocation)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kPrimaryColor,
                ),
              ),
            ),
          )
        else if (trendingHotels.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              locationMessage ??
                  (currentCity == null
                      ? 'Izinkan lokasi untuk menampilkan hotel sesuai kota Anda.'
                      : 'Belum ada hotel trending di $currentCity.'),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          )
        else
          ...trendingHotels.map(
            (hotel) => _TrendingHotelTile(
              hotel: hotel,
              hotelImage: hotelImage,
              onTap: () => onHotelTap(hotel),
            ),
          ),
      ],
    );
  }
}

class _PopularDestinationTile extends StatelessWidget {
  const _PopularDestinationTile({
    required this.destination,
    required this.onTap,
  });

  final _PopularDestination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 54,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kPrimaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on,
                size: 20,
                color: _kPrimaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${destination.city}, ${destination.country}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destination.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7B8490),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}

class _TrendingHotelTile extends StatelessWidget {
  const _TrendingHotelTile({
    required this.hotel,
    required this.hotelImage,
    required this.onTap,
  });

  final HotelModel hotel;
  final Widget Function(String? imageUrl, {double? width, double? height})
  hotelImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 54,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hotelImage(hotel.hotelImage, width: 38, height: 38),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.namaHotel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${hotel.kota}, Indonesia',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7B8490),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 20, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}

class _HotelSearchListItem extends StatelessWidget {
  const _HotelSearchListItem({required this.hotel, required this.hotelImage});

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
                            color: _kPrimaryColor.withValues(alpha: 0.14),
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
