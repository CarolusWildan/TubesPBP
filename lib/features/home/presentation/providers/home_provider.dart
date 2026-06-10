import 'package:flutter/material.dart';

import '../../../../shared/models/hotel_model.dart';
import '../../../../shared/network/api_client.dart';

enum HotelSortOption { price, rating }

class HomeProvider extends ChangeNotifier {
  HomeProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  bool _isLoading = false;
  String? _errorMessage;
  List<HotelModel> _hotels = [];

  String _searchQuery = '';
  HotelSortOption? _sortBy;
  bool _sortAscending = true;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<HotelModel> get hotels => List.unmodifiable(_hotels);
  String get searchQuery => _searchQuery;
  HotelSortOption? get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  List<String> get destinationCities {
    final cities = _hotels
        .map((hotel) => hotel.kota.trim())
        .where((city) => city.isNotEmpty)
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  Future<void> loadHomeData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final endpoint = '/hotels${_buildQueryString()}';
      final response = await _apiClient.get(endpoint);
      final hotelList = _extractList(response);
      _hotels = hotelList
          .whereType<Map<String, dynamic>>()
          .map(HotelModel.fromJson)
          .toList();
    } catch (e) {
      _hotels = [];
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.trim();
    loadHomeData();
  }

  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    loadHomeData();
  }

  void toggleSortOption(HotelSortOption option) {
    if (_sortBy == option) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = option;
      _sortAscending = option == HotelSortOption.price;
    }
    loadHomeData();
  }

  void clearSort() {
    if (_sortBy == null) return;
    _sortBy = null;
    _sortAscending = true;
    loadHomeData();
  }

  String _buildQueryString() {
    final params = <String, String>{};

    if (_searchQuery.isNotEmpty) {
      params['search'] = _searchQuery;
    }

    if (_sortBy != null) {
      params['sort_by'] = _sortBy == HotelSortOption.price ? 'price' : 'rating';
      params['sort_dir'] = _sortAscending ? 'asc' : 'desc';
    }

    if (params.isEmpty) return '';
    return '?${Uri(queryParameters: params).query}';
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic> && response['data'] is List) {
      return response['data'] as List;
    }
    return const [];
  }
}
