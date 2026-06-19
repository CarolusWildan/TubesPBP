/*
|--------------------------------------------------------------------------
| Main Screen
|--------------------------------------------------------------------------
| Tujuan file:
| Menyediakan navigasi bawah utama setelah user berhasil login.
|
| Peran dalam arsitektur:
| MainScreen adalah container UI yang memilih Home, Trips, atau Profile.
| Authentication tidak diproses di sini; screen ini ditampilkan setelah
| AuthProvider menyatakan user authenticated.
|
| Hubungan dengan Authentication/Profile:
| LoginScreen dan AuthWrapper mengarahkan user authenticated ke MainScreen.
| Tab Profile membuka ProfileScreen yang membaca AuthProvider.user dan
| menyediakan Personal Information, Privacy Policy, serta Logout.
|
| Kapan digunakan:
| Setelah login berhasil atau saat sesi login dipulihkan dari secure storage.
|--------------------------------------------------------------------------
*/

// Komponen Flutter untuk Scaffold dan BottomNavigationBar.
import 'package:flutter/material.dart';

// Tab riwayat perjalanan/bookings.
import '../../../history/presentation/screens/history_screen.dart';

// Tab beranda utama aplikasi.
import 'home_screen.dart';

// Tab profile yang terhubung dengan Authentication dan Profile flow.
import '../../../profile/presentation/screens/profile_screen.dart';

/*
|--------------------------------------------------------------------------
| MainScreen
|--------------------------------------------------------------------------
| Tujuan class:
| Widget root untuk bottom navigation area authenticated.
|
| Tanggung jawab:
| Menyimpan index tab aktif dan menampilkan halaman sesuai pilihan user.
|
| Data yang dikelola:
| initialIndex, latestBooking, dan initialHistoryFilter untuk mengatur tab
| awal atau data transisi dari booking/history.
|--------------------------------------------------------------------------
*/
class MainScreen extends StatefulWidget {
  final int initialIndex;
  final HistoryBookingItem? latestBooking;
  final String? initialHistoryFilter;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
    this.latestBooking,
    this.initialHistoryFilter,
  });

  /*
  | createState()
  | Dipanggil Flutter saat MainScreen dimasukkan ke widget tree.
  */
  @override
  State<MainScreen> createState() => _MainScreenState();
}

/*
|--------------------------------------------------------------------------
| _MainScreenState
|--------------------------------------------------------------------------
| Tujuan class:
| Mengelola tab aktif pada bottom navigation.
|
| Hubungan class:
| Menampilkan ProfileScreen pada index 2 sehingga user dapat mengakses fitur
| profile dan logout.
|--------------------------------------------------------------------------
*/
class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  /*
  | initState()
  | Dipanggil sekali saat state dibuat. initialIndex dibatasi ke 0..2 agar
  | akses _pages selalu valid.
  */
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 2);
  }

  /*
  | _pages
  | Dipanggil build() untuk mengambil halaman sesuai _currentIndex.
  | Index 2 adalah ProfileScreen, sumber entry point Profile flow.
  */
  List<Widget> get _pages => [
    const HomeScreen(),
    HistoryScreen(
      latestBooking: widget.latestBooking,
      initialFilter: widget.initialHistoryFilter,
    ),
    const ProfileScreen(),
  ];

  /*
  | build()
  | Dipanggil Flutter untuk merender tab aktif dan BottomNavigationBar.
  | onTap mengubah _currentIndex melalui setState.
  */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0EA554),
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              activeIcon: Icon(Icons.home, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.luggage_outlined, size: 28),
              activeIcon: Icon(Icons.luggage, size: 28),
              label: 'Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 28),
              activeIcon: Icon(Icons.person, size: 28),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
