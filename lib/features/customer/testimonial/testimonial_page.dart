import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TestimonialPage extends StatefulWidget {
  const TestimonialPage({super.key});

  @override
  State<TestimonialPage> createState() => _TestimonialPageState();
}

class _TestimonialPageState extends State<TestimonialPage> {
  // Gunakan Future untuk data JOIN
  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  // Fungsi untuk mengambil data reviews dengan JOIN
  void _fetchReviews() {
    setState(() {
      _reviewsFuture = Supabase.instance.client
          .from('reviews')
          // ✅ FIX QUERY: Menggunakan JOIN (motors, profiles) tanpa .stream()
          .select('*, motors(nama_motor, foto_motor), profiles(full_name)') 
          .order('created_at', ascending: false)
          .limit(20); 
    });
  }

  // Helper: Hitung waktu posting
  String _getTimeAgo(String dateStr) {
    try {
      final postedTime = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(postedTime);

      if (diff.inDays > 0) {
        return '${diff.inDays} hari lalu';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} jam lalu';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} menit lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return 'Tanggal Invalid';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("Testimoni Pelanggan", style: GoogleFonts.playfairDisplay(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // Tombol Lonceng/Inbox
          IconButton(
             icon: const Icon(Icons.notifications_none, color: Colors.white54),
             onPressed: () {
                _openInbox(); // Panggil fungsi di dalam State
             },
          )
        ],
      ),
      // ✅ FIX: Menggunakan FutureBuilder
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }
          if (snapshot.hasError) {
             return Center(child: Text("Gagal memuat ulasan: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_half, size: 80, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text("Belum ada testimoni dari pelanggan.", style: GoogleFonts.poppins(color: Colors.white54)),
                ],
              ),
            );
          }

          final reviews = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              final motorName = review['motors']?['nama_motor'] ?? 'Motor';
              final reviewerName = review['profiles']?['full_name'] ?? review['profiles']?['email'] ?? 'Pelanggan';
              final rating = (review['rating'] as int?)?.toDouble() ?? 0.0;
              final comment = review['comment'] as String? ?? '-';
              
              final timeAgo = _getTimeAgo(review['created_at']);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reviewer Name & Time Ago
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(reviewerName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(timeAgo, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white38)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Rating
                    RatingBar.builder(
                      initialRating: rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 18,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                      itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) {}, 
                      ignoreGestures: true,
                    ),
                    const SizedBox(height: 10),

                    // Comment
                    Text(
                      comment, 
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Motor Info
                    Text(
                      "Motor: $motorName", 
                      style: GoogleFonts.poppins(color: const Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.w600)
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Fungsi untuk Notifikasi
  void _openInbox() {
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fitur Notifikasi (Inbox)!")),
     );
  }
}