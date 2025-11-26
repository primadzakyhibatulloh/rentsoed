import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import Halaman-Halaman Customer
import 'package:rentsoed_app/features/customer/home/home_page.dart';
import 'package:rentsoed_app/features/customer/history/history_page.dart';
import 'package:rentsoed_app/features/customer/profile/profile_page.dart';

// ✅ FIX IMPORTS: Impor halaman yang sudah dipisahkan ke dalam file/folder masing-masing
import 'package:rentsoed_app/features/customer/testimonial/testimonial_page.dart'; 
import 'package:rentsoed_app/features/customer/wishlist/wishlist_page.dart'; 


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // Daftar Halaman untuk setiap Tab (5 Halaman)
  final List<Widget> _pages = [
    const HomePage(),           // Index 0: Home (Katalog)
    const WishlistPage(),       // Index 1: Favorit/Wishlist 
    const HistoryPage(),        // Index 2: Riwayat Pesanan
    const TestimonialPage(),    // Index 3: Testimoni/Ulasan Global
    const ProfilePage(),        // Index 4: Profil Saya
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      
      // Menampilkan halaman sesuai index yang dipilih di Bottom Bar
      body: _pages[_selectedIndex],
      
      // --- BOTTOM NAVIGATION BAR MEWAH (5 ITEM) ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0F172A), 
          type: BottomNavigationBarType.fixed, 
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          
          // Warna Icon & Teks
          selectedItemColor: const Color(0xFFD4AF37), // Emas (Aktif)
          unselectedItemColor: Colors.white38,        // Putih pudar (Tidak aktif)
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
          
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              label: 'Favorit',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'History',
            ),
            // ITEM BARU: TESTIMONI
            BottomNavigationBarItem(
              icon: Icon(Icons.rate_review_outlined),
              label: 'Testimoni',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}