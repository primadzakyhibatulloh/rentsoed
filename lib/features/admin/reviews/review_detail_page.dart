import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Pastikan package ini ada di pubspec.yaml
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';

class ReviewDetailPage extends StatelessWidget {
  final Map<String, dynamic> reviewData;
  const ReviewDetailPage({super.key, required this.reviewData});

  // Fungsi untuk mengambil detail tambahan
  Future<Map<String, dynamic>> _fetchBookingAndUserDetail() async {
    final supabase = Supabase.instance.client;
    final bookingId = reviewData['booking_id'];

    // Ambil detail booking dan user
    final response = await supabase
        .from('bookings')
        .select('*, users:user_id(email), motors(nama_motor)')
        .eq('id', bookingId)
        .single();
    
    return response;
  }

  @override
  Widget build(BuildContext context) {
    final rating = (reviewData['rating'] as int?)?.toDouble() ?? 0.0;
    final comment = reviewData['comment'] ?? 'Tidak ada komentar.';
    final createdAt = DateTime.parse(reviewData['created_at']);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("Detail Ulasan", style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchBookingAndUserDetail(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text("Gagal memuat detail booking: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }
          
          final booking = snapshot.data!;
          final motorName = booking['motors']?['nama_motor'] ?? 'Motor Tidak Diketahui';
          final userEmail = booking['users']?['email'] ?? 'Pengguna Anonim';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- KARTU RATING & MOTOR ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(motorName, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const Gap(4),
                      Text("Oleh: $userEmail", style: GoogleFonts.poppins(color: Colors.white70)),
                      const Divider(color: Colors.white12, height: 20),
                      
                      // Tampilan Bintang Rating
                      Row(
                        children: [
                          // ✅ PERBAIKAN: Gunakan RatingBar.builder
                          RatingBar.builder(
                            initialRating: rating,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: false,
                            itemCount: 5,
                            itemSize: 28,
                            itemPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                            onRatingUpdate: (rating) {}, 
                            ignoreGestures: true,
                          ),
                          const Gap(10),
                          Text("($rating/5)", style: GoogleFonts.poppins(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Gap(10),
                      Text("Tanggal Ulasan: ${DateFormat('dd MMMM yyyy, HH:mm').format(createdAt)}", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                
                const Gap(30),

                // --- DETAIL KOMENTAR LENGKAP ---
                Text("Komentar Pelanggan", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
                const Gap(10),
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(comment, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                ),

                const Gap(30),

                // --- DETAIL BOOKING TERKAIT ---
                Text("Informasi Booking", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
                const Gap(10),
                _buildInfoRow("ID Booking", booking['id']),
                _buildInfoRow("Motor Disewa", motorName),
                _buildInfoRow("Status Pembayaran", booking['status']),
                _buildInfoRow("Tanggal Sewa", "${DateFormat('dd/MM/yy').format(DateTime.parse(booking['start_date']))} - ${DateFormat('dd/MM/yy').format(DateTime.parse(booking['end_date']))}"),
                _buildInfoRow("Total Harga", "Rp ${NumberFormat('#,##0').format(booking['total_price'])}"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          const Text(": ", style: TextStyle(color: Colors.white54)),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}