import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; 
import 'package:rentsoed_app/features/admin/reviews/review_detail_page.dart';

class ManageReviewsPage extends StatefulWidget {
  const ManageReviewsPage({super.key});

  @override
  State<ManageReviewsPage> createState() => _ManageReviewsPageState();
}

class _ManageReviewsPageState extends State<ManageReviewsPage> {
  // Variable untuk menyimpan future agar tidak rebuild terus menerus
  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Fungsi untuk mengambil data (Refreshable)
  void _refreshData() {
    setState(() {
      // ✅ FIX QUERY: Menggunakan 'profiles(email)' untuk join user data
      _reviewsFuture = Supabase.instance.client
          .from('reviews')
          .select('*, motors(nama_motor), profiles(email)') // Mengganti users:user_id menjadi profiles
          .order('created_at', ascending: false);
    });
  }

  // Fungsi Hapus Ulasan
  Future<void> _confirmAndDelete(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Hapus Ulasan?", style: GoogleFonts.poppins(color: Colors.white)),
        content: const Text("Yakin ingin menghapus ulasan ini secara permanen?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal", style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('reviews').delete().eq('id', id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ulasan berhasil dihapus."), backgroundColor: Colors.green));
          _refreshData(); 
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus: ${e.toString()}"), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("Kelola Ulasan", style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }
          if (snapshot.hasError) {
             // Jika error PGRST200 muncul, berarti tabel profiles belum disetup di Supabase
             return Center(child: Padding(
               padding: const EdgeInsets.all(20.0),
               child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
             ));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada ulasan yang masuk.", style: TextStyle(color: Colors.white70)));
          }

          final reviews = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              
              // Ambil data dari hasil JOIN (sekarang menggunakan 'profiles')
              final motorName = review['motors']?['nama_motor'] ?? 'Motor Tidak Diketahui';
              final userEmail = review['profiles']?['email'] ?? 'Pengguna Anonim'; // Diambil dari tabel profiles
              
              final rating = (review['rating'] as int?)?.toDouble() ?? 0.0;
              final commentPreview = review['comment']?.toString() ?? '';
              final shortComment = commentPreview.length > 50 
                  ? '${commentPreview.substring(0, 50)}...' 
                  : commentPreview;
              
              return ListTile(
                onTap: () async {
                  await Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => ReviewDetailPage(reviewData: review))
                  );
                  // Refresh data setelah kembali (untuk melihat apakah item terhapus di DetailPage)
                  _refreshData(); 
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                tileColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFD4AF37).withOpacity(0.2),
                  child: Text(rating.toStringAsFixed(1), style: GoogleFonts.poppins(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                ),
                title: Text(motorName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    RatingBar.builder(
                      initialRating: rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 16,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                      itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) {}, 
                      ignoreGestures: true, // Read-only
                    ),
                    const SizedBox(height: 4),
                    Text("Oleh: $userEmail", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                    if (shortComment.isNotEmpty)
                      Text(shortComment, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _confirmAndDelete(context, review['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}