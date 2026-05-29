import 'package:flutter/material.dart';

import '../../../../shared/models/hotel_model.dart';
import '../../../../shared/network/api_client.dart';

class HomeProvider extends ChangeNotifier {
  HomeProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  bool _isLoading = false;
  String? _errorMessage;
  List<HotelModel> _hotels = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<HotelModel> get hotels => List.unmodifiable(_hotels);

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
      final response = await _apiClient.get('/hotels');
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

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic> && response['data'] is List) {
      return response['data'] as List;
    }
    return const [];
  }
}
