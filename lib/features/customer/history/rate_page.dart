import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; 

class RatePage extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const RatePage({super.key, required this.bookingData});

  @override
  State<RatePage> createState() => _RatePageState();
}

class _RatePageState extends State<RatePage> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 5.0; // Default rating 5 bintang
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Helper untuk mendapatkan teks rating yang lebih detail
  String _getRatingText(double rating) {
    if (rating == 5) return "Sempurna!";
    if (rating >= 4) return "Sangat Bagus"; 
    if (rating == 3) return "Cukup Bagus"; 
    if (rating == 2) return "Kurang Memuaskan"; 
    return "Tidak Memuaskan"; // 1 Bintang
  }

  Future<void> _submitReview() async {
    // Validasi input sederhana
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon tuliskan komentar singkat.")),
      );
      return;
    }

    setState(() => _isSending = true);
    
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) throw Exception("User tidak terautentikasi.");

      // 1. Cek apakah user sudah pernah kasih review untuk booking ID ini
      final existingReview = await supabase
          .from('reviews')
          .select('id')
          .eq('booking_id', widget.bookingData['id'])
          .maybeSingle(); 

      if (existingReview != null) {
        throw Exception("Anda sudah memberi ulasan untuk pesanan ini.");
      }

      // 2. Kirim ulasan ke tabel 'reviews' (Perlu RLS INSERT yang benar)
      await supabase.from('reviews').insert({
        'booking_id': widget.bookingData['id'],
        'user_id': user.id,
        // Asumsi motor_id ada di bookingData, sesuai skema yang dibutuhkan
        'motor_id': widget.bookingData['motor_id'], 
        'rating': _rating.toInt(),
        'comment': _commentController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terima kasih! Ulasan berhasil dikirim."), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Kembali ke Riwayat dengan sinyal sukses
      }
    } catch (e) {
      if (mounted) {
        // Menampilkan pesan error yang spesifik jika ada RLS violation
        String errorMessage = e.toString().contains('row violates row-level security policy') 
            ? "Gagal mengirim: Izin (RLS) database ditolak. Hubungi Admin."
            : "Gagal mengirim ulasan: ${e.toString()}";
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil nama motor dari data booking
    final motorName = widget.bookingData['motor_name'] ?? 'Motor';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Background Navy
      appBar: AppBar(
        title: Text("Ulas Motor", style: GoogleFonts.playfairDisplay(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center alignment agar rapi
          children: [
            Text(
              "Bagaimana pengalaman Anda dengan", 
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const Gap(5),
            Text(
              motorName, 
              style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            
            const Gap(40),

            // --- PILIH BINTANG ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: 40,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Color(0xFFD4AF37), // Emas
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),
                  const Gap(10),
                  Text(
                    _getRatingText(_rating), // Menggunakan fungsi helper baru
                    style: GoogleFonts.poppins(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
            
            const Gap(40),

            // --- KOLOM KOMENTAR ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Komentar Anda", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const Gap(10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Ceritakan pengalaman berkendara Anda...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 5,
              ),
            ),
            
            const Gap(40),

            // --- TOMBOL KIRIM ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: _isSending
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Color(0xFF0F172A)))
                    : Text("KIRIM ULASAN", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}