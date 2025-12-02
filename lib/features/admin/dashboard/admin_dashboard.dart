import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ WAJIB
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:rentsoed_app/features/auth/login_page.dart';

// Import Fitur-Fitur Admin
import 'package:rentsoed_app/features/admin/motors/manage_motors_page.dart';
import 'package:rentsoed_app/features/admin/categories/manage_categories_page.dart';
import 'package:rentsoed_app/features/admin/promos/manage_promos_page.dart';
import 'package:rentsoed_app/features/admin/transactions/booking_detail_page.dart';
import 'package:rentsoed_app/features/admin/transactions/manage_bookings_page.dart';
import 'package:rentsoed_app/features/admin/reviews/manage_reviews_page.dart';

// ✅ IMPORT SERVICE NOTIFIKASI
import 'package:rentsoed_app/services/notification_service.dart';

// ⚠️ UBAH JADI STATEFUL WIDGET AGAR BISA LISTEN REALTIME
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // ✅ Variable Subscription
  RealtimeChannel? _adminSubscription;

  @override
  void initState() {
    super.initState();
    // ✅ Mulai Dengarkan Aktivitas Booking
    _subscribeToAdminUpdates();
  }

  @override
  void dispose() {
    // ✅ Bersihkan Subscription
    if (_adminSubscription != null) {
      Supabase.instance.client.removeChannel(_adminSubscription!);
    }
    super.dispose();
  }

  // --- LOGIKA NOTIFIKASI ADMIN (REALTIME) ---
  void _subscribeToAdminUpdates() {
    final supabase = Supabase.instance.client;

    _adminSubscription = supabase
        .channel('public:bookings:admin_listener')
        .onPostgresChanges(
          event: PostgresChangeEvent.all, // Dengarkan INSERT dan UPDATE
          schema: 'public',
          table: 'bookings',
          callback: (payload) {
            _handleAdminNotification(payload);
          },
        )
        .subscribe();
  }

  void _handleAdminNotification(PostgresChangePayload payload) {
    // 1. KASUS: BOOKING BARU (INSERT)
    if (payload.eventType == PostgresChangeEvent.insert) {
      final newData = payload.newRecord;
      final bookingId = newData['id'].toString().substring(0, 5).toUpperCase();
      final motorName = newData['motor_name'] ?? 'Motor';

      NotificationService.showNotification(
        title: 'Booking Baru Masuk! 🔔',
        body: '#$bookingId: Customer menyewa $motorName. Cek sekarang!',
      );
    }

    // 2. KASUS: UPDATE STATUS (PEMBAYARAN MASUK)
    if (payload.eventType == PostgresChangeEvent.update) {
      final newData = payload.newRecord;
      final oldData = payload.oldRecord;

      // Cek jika status berubah menjadi 'Menunggu Verifikasi'
      // Artinya user baru saja upload bukti bayar
      if (newData['status'] == 'Menunggu Verifikasi' &&
          oldData['status'] != 'Menunggu Verifikasi') {
        final bookingId = newData['id']
            .toString()
            .substring(0, 5)
            .toUpperCase();

        NotificationService.showNotification(
          title: 'Pembayaran Diterima! 💰',
          body: 'Booking #$bookingId menunggu verifikasi Anda.',
        );
      }
    }
  }

  void _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ??
        'Admin';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Admin Panel",
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Keluar",
            onPressed: () => _logout(context),
          ),
          const Gap(10),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- WELCOME HEADER ---
              Text(
                "Selamat datang,",
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
              ),
              Text(
                userName,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Gap(20),

              Text(
                "Menu Pengelolaan",
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
              ),
              const Gap(10),

              // --- GRID MENU (6 Item) ---
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildMenuCard(
                    context,
                    icon: Icons.motorcycle,
                    title: "Kelola Motor",
                    color: Colors.orangeAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageMotorsPage(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.category,
                    title: "Kelola Kategori",
                    color: Colors.purpleAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageCategoriesPage(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.local_offer,
                    title: "Kelola Promo",
                    color: Colors.greenAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManagePromosPage(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.receipt_long,
                    title: "Kelola Transaksi",
                    color: Colors.blueAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageBookingsPage(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.star_half,
                    title: "Kelola Ulasan",
                    color: Colors.yellow,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageReviewsPage(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.analytics,
                    title: "Laporan",
                    color: Colors.teal,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur Laporan segera hadir.'),
                      ),
                    ),
                  ),
                ],
              ),

              const Gap(30),

              // --- JUDUL SEKSI TRANSAKSI PENDING ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pembayaran Menunggu Verifikasi",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const Icon(Icons.refresh, color: Colors.white24, size: 16),
                ],
              ),
              const Gap(10),

              // --- LIST TRANSAKSI PENDING (REALTIME) ---
              StreamBuilder<List<Map<String, dynamic>>>(
                // Mengambil semua data untuk filter manual client-side agar lebih stabil
                stream: Supabase.instance.client
                    .from('bookings')
                    .stream(primaryKey: ['id'])
                    .order('created_at', ascending: false),

                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD4AF37),
                      ),
                    );
                  }

                  final allBookings = snapshot.data ?? [];

                  // Filter Manual: Status 'Menunggu Pembayaran' (dan opsional cek payment_proof)
                  // Di sini kita tampilkan semua yang Menunggu Pembayaran agar admin tau ada order masuk
                  // Walaupun user belum upload bukti
                  final bookings = allBookings.where((b) {
                    return b['status'] == 'Menunggu Pembayaran' ||
                        b['status'] == 'Menunggu Verifikasi';
                  }).toList();

                  if (bookings.isEmpty) {
                    return Container(
                      height: 100,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 40,
                            color: Colors.white24,
                          ),
                          const Gap(10),
                          Text(
                            "Tidak ada pembayaran pending.",
                            style: GoogleFonts.poppins(color: Colors.white30),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bookings.length,
                    separatorBuilder: (ctx, i) => const Gap(10),
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      final priceFormatted = NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp',
                        decimalDigits: 0,
                      ).format(booking['total_price'] ?? 0);

                      final bool hasProof =
                          booking['payment_proof_url'] != null;
                      final String status = booking['status'] ?? '';

                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BookingDetailPage(bookingData: booking),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        tileColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: hasProof
                                ? const Color(0xFFD4AF37)
                                : Colors.redAccent.withOpacity(0.5),
                            width: 1.0,
                          ),
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: hasProof
                                ? const Color(0xFFD4AF37).withOpacity(0.2)
                                : Colors.redAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasProof ? Icons.receipt_long : Icons.pending,
                            color: hasProof
                                ? const Color(0xFFD4AF37)
                                : Colors.redAccent,
                          ),
                        ),
                        title: Text(
                          '#${booking['id'].toString().substring(0, 8).toUpperCase()} - ${booking['motor_name'] ?? 'Motor'}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              priceFormatted,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            if (!hasProof)
                              Text(
                                "Belum upload bukti transfer",
                                style: GoogleFonts.poppins(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            else if (status == 'Menunggu Verifikasi')
                              Text(
                                "Bukti terupload! Perlu verifikasi.",
                                style: GoogleFonts.poppins(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white54,
                        ),
                      );
                    },
                  );
                },
              ),

              const Gap(30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 24, color: color),
            ),
            const Gap(12),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
