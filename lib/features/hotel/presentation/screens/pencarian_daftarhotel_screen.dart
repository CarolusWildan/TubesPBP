import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  final SpeechService _speechService = SpeechService();

  bool _isListening = false;

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
    final isPriceSort = homeProvider.sortBy == HotelSortOption.price;
    final isRatingSort = homeProvider.sortBy == HotelSortOption.rating;
    final sortIcon = homeProvider.sortAscending
        ? Icons.keyboard_arrow_up
        : Icons.keyboard_arrow_down;

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
                    color: Colors.black.withOpacity(0.04),
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
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFE5E5E5)),
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
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: (value) {
                                    homeProvider.updateSearchQuery(value);
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Bali, Indonesia',
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
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Filters by:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isPriceSort
                                ? const Color(0xFFE8F5E9)
                                : Colors.white,
                            foregroundColor: isPriceSort
                                ? _kPrimaryColor
                                : Colors.black87,
                            side: BorderSide(
                              color: isPriceSort
                                  ? _kPrimaryColor
                                  : const Color(0xFFD9D9D9),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () => homeProvider.toggleSortOption(
                            HotelSortOption.price,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Price'),
                              const SizedBox(width: 8),
                              Icon(
                                isPriceSort
                                    ? sortIcon
                                    : Icons.keyboard_arrow_down,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isRatingSort
                                ? const Color(0xFFE8F5E9)
                                : Colors.white,
                            foregroundColor: isRatingSort
                                ? _kPrimaryColor
                                : Colors.black87,
                            side: BorderSide(
                              color: isRatingSort
                                  ? _kPrimaryColor
                                  : const Color(0xFFD9D9D9),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () => homeProvider.toggleSortOption(
                            HotelSortOption.rating,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Rating'),
                              const SizedBox(width: 8),
                              Icon(
                                isRatingSort
                                    ? sortIcon
                                    : Icons.keyboard_arrow_down,
                                size: 20,
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  ] else if (homeProvider.hotels.isEmpty) ...[
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
                    ...homeProvider.hotels.map(
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
