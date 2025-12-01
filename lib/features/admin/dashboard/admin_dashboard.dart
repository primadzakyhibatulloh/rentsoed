import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:rentsoed_app/features/auth/login_page.dart';

// Import Fitur-Fitur Admin
import 'package:rentsoed_app/features/admin/motors/manage_motors_page.dart';
import 'package:rentsoed_app/features/admin/categories/manage_categories_page.dart';
import 'package:rentsoed_app/features/admin/promos/manage_promos_page.dart';

// FIX IMPORTS: Mengubah ':' menjadi '/'
import 'package:rentsoed_app/features/admin/transactions/booking_detail_page.dart';
import 'package:rentsoed_app/features/admin/transactions/manage_bookings_page.dart';
import 'package:rentsoed_app/features/admin/reviews/manage_reviews_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // Fungsi Logout Admin
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
      backgroundColor: const Color(0xFF0F172A), // Background Navy
      // ✅ FIX: Menghapus drawer karena Admin tidak menggunakannya
      appBar: AppBar(
        // ✅ FIX: Menghilangkan otomatis tombol back/drawer
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
                  // 1. Kelola Motor
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
                  // 2. Kelola Kategori
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
                  // 3. Kelola Promo
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
                  // 4. Kelola Transaksi (Verifikasi Pembayaran)
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
                  // 5. Kelola Review
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
                  // 6. Laporan (Menggantikan Verifikasi Dokumen)
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
                stream: Supabase.instance.client
                    .from('bookings')
                    .stream(primaryKey: ['id'])
                    .eq('status', 'Menunggu Pembayaran'),

                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD4AF37),
                      ),
                    );
                  }

                  final allBookings = snapshot.data ?? [];

                  // FILTER hanya yang punya bukti pembayaran
                  final bookings = allBookings
                      .where((b) => b['payment_proof_url'] != null)
                      .toList();

                  // SORTING berdasarkan created_at (manual)
                  bookings.sort((a, b) {
                    final aTime = DateTime.parse(a['created_at']);
                    final bTime = DateTime.parse(b['created_at']);
                    return aTime.compareTo(bTime);
                  });

                  if (bookings.isEmpty) {
                    return Container(
                      height: 100,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.waving_hand,
                            size: 40,
                            color: Colors.white24,
                          ),
                          const Gap(10),
                          Text(
                            "Tidak ada pembayaran menunggu verifikasi.",
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
                          side: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.payment,
                            color: Colors.redAccent,
                          ),
                        ),
                        title: Text(
                          '#${booking['id'].toString().substring(0, 8)} - ${booking['motor_name'] ?? 'Pemesanan'}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          priceFormatted,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
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

  // Widget Pembantu untuk Kartu Menu
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
