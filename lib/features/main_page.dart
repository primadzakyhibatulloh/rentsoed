import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import halaman
import 'package:rentsoed_app/features/customer/home/home_page.dart';
import 'package:rentsoed_app/features/customer/history/history_page.dart';
import 'package:rentsoed_app/features/customer/profile/profile_page.dart';
import 'package:rentsoed_app/features/customer/testimonial/testimonial_page.dart';
import 'package:rentsoed_app/features/customer/wishlist/wishlist_page.dart';

import 'package:rentsoed_app/services/notification_service.dart';

class MainPage extends StatefulWidget {
  final int initialIndex;

  const MainPage({super.key, this.initialIndex = 0});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedIndex;
  RealtimeChannel? _bookingSubscription;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _subscribeToBookingUpdates();
  }

  @override
  void dispose() {
    if (_bookingSubscription != null) {
      Supabase.instance.client.removeChannel(_bookingSubscription!);
    }
    super.dispose();
  }

  void _subscribeToBookingUpdates() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    _bookingSubscription = supabase
        .channel('public:bookings:user_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _handleBookingUpdate(payload);
          },
        )
        .subscribe();
  }

  // ✅ FUNGSI UTAMA: LOGIKA PESAN NOTIFIKASI DI SINI
  void _handleBookingUpdate(PostgresChangePayload payload) {
    final newData = payload.newRecord;
    final oldData = payload.oldRecord;

    // Cek jika status berubah
    if (newData['status'] != oldData['status']) {
      final newStatus = newData['status'];
      final motorName = newData['motor_name'] ?? 'Pesanan Anda';

      String title = "Info Booking";
      String body = "$motorName: Status berubah menjadi $newStatus";

      // --- KUSTOMISASI PESAN ---
      if (newStatus == 'Menunggu Verifikasi') {
        title = "Pembayaran Diterima";
        body = "Pembayaran berhasil, silahkan tunggu verifikasi admin.";
      } else if (newStatus == 'Dibayar') {
        title = "Booking Terkonfirmasi!";
        body =
            "Pesanan Anda ($motorName) sudah diverifikasi. Silakan ambil unit.";
      } else if (newStatus == 'Dibatalkan') {
        title = "Booking Dibatalkan";
        body = "Pesanan Anda ($motorName) dibatalkan oleh admin.";
      } else if (newStatus == 'Selesai') {
        title = "Booking Selesai";
        body = "Terima kasih telah menyewa di Rentsoed.";
      }

      // Tampilkan Notifikasi
      NotificationService.showNotification(title: title, body: body);
    }
  }

  final List<Widget> _pages = [
    const HomePage(),
    const WishlistPage(),
    const HistoryPage(),
    const TestimonialPage(),
    const ProfilePage(),
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0F172A),
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFFD4AF37),
          unselectedItemColor: Colors.white38,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
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
