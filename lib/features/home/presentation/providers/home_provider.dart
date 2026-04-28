import 'package:flutter/material.dart';

// Karena kita mensimulasikan data yang presisi dengan Figma,
// kita buat mock model sementara di dalam provider ini sebelum disambung ke Repository.

class MockDestination {
  final String imageUrl;
  final String city;
  final String subtitle;
  final String hotelCount;

  MockDestination(this.imageUrl, this.city, this.subtitle, this.hotelCount);
}

class MockBestHotel {
  final String imageUrl;
  final String name;
  final String location;
  final double rating;
  final int reviews;
  final double startingPrice;

  MockBestHotel(
    this.imageUrl,
    this.name,
    this.location,
    this.rating,
    this.reviews,
    this.startingPrice,
  );
}

class HomeProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<MockDestination> destinations = [];
  List<MockBestHotel> bestHotels = [];

  // Fungsi ini NANTI akan dipanggil oleh UI (initState)
  Future<void> loadHomeData() async {
    _isLoading = true;
    notifyListeners();

    // Simulasi loading jaringan lambat (1.5 detik)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Data Mock Pixel-Perfect dengan Figma Anda
    destinations = [
      MockDestination(
        'https://images.unsplash.com/photo-1596402184320-417e7178b2cd?q=80&w=1000', // Jogja (fixed)
        'Yogyakarta',
        'City of Culture and Tourism',
        '500+ Hotels available',
      ),
      MockDestination(
        'https://images.unsplash.com/photo-1555400038-63f5ba517a47?q=80&w=1000', // Bali
        'Bali',
        'Island of Gods & Beaches',
        '2,000+ Hotels available',
      ),
      MockDestination(
        'https://images.unsplash.com/photo-1559628233-100c798642d4?q=80&w=1000', // Bandung
        'Bandung',
        'Paris van Java',
        '800+ Hotels available',
      ),
      MockDestination(
        'https://images.unsplash.com/photo-1555412654-72a95a495858?q=80&w=1000', // Jakarta
        'Jakarta',
        'Business and Government',
        '1,800+ Hotels available',
      ),
    ];

    bestHotels = [
      MockBestHotel(
        'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?q=80&w=1000',
        'Capella Ubud',
        'Tegallalang, Bali',
        4.8,
        758,
        16997222,
      ),
      MockBestHotel(
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=1000',
        'Nihi Sumba',
        'Sumba Barat, Nusa Tenggara Timur',
        4.9,
        420,
        21500000,
      ),
      MockBestHotel(
        'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?q=80&w=1000',
        'The Ritz-Carlton Jakarta',
        'Mega Kuningan, Jakarta',
        4.7,
        980,
        2850000,
      ),
      MockBestHotel(
        'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?q=80&w=1000',
        'Padma Hotel Bandung',
        'Ciumbuleuit, Bandung',
        4.6,
        1340,
        1750000,
      ),
      MockBestHotel(
        'https://images.unsplash.com/photo-1571896349842-33c89424de2d?q=80&w=1000',
        'Katamaran Resort',
        'Senggigi, Lombok',
        4.8,
        860,
        2100000,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }
}
