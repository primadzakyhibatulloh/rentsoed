import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';

import 'package:rentsoed_app/models/motor_model.dart';
import 'package:rentsoed_app/features/customer/detail/detail_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  late Future<List<MotorModel>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _wishlistFuture = _fetchWishlist();
  }
  
  // Helper: Format Rupiah
  String _formatRupiah(int number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  // --- FUNGSI UTAMA: AMBIL DAFTAR WISHLIST ---
  Future<List<MotorModel>> _fetchWishlist() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      // Jika user belum login, kembalikan list kosong
      return []; 
    }

    // 1. Ambil ID motor dari tabel 'wishlists' milik user ini
    final wishlistResponse = await supabase
        .from('wishlists')
        .select('motor_id')
        .eq('user_id', userId);

    final motorIds = wishlistResponse.map((row) => row['motor_id']).toList();

    if (motorIds.isEmpty) {
      return [];
    }

    // 2. Ambil detail motor menggunakan ID yang ditemukan
    final motorResponse = await supabase
        .from('motors')
        .select('*')
        // ✅ FIX ERROR: Mengganti .in_('id', motorIds) menjadi .inFilter('id', motorIds)
        .inFilter('id', motorIds) 
        .eq('is_available', true);

    // Konversi hasil ke MotorModel
    return motorResponse.map((json) => MotorModel.fromJson(json)).toList();
  }
  
  // --- FUNGSI: HAPUS DARI WISHLIST ---
  Future<void> _removeFromWishlist(String motorId) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;
    
    // Hapus relasi dari tabel 'wishlists'
    await supabase
        .from('wishlists')
        .delete()
        .eq('user_id', userId)
        .eq('motor_id', motorId);
        
    // Refresh UI
    setState(() {
      _wishlistFuture = _fetchWishlist();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Motor dihapus dari favorit.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("Motor Favorit", style: GoogleFonts.playfairDisplay(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<MotorModel>>(
        future: _wishlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }
          if (snapshot.hasError) {
             return Center(child: Text("Gagal memuat favorit: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }
          final motors = snapshot.data ?? [];

          if (motors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 80, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text("Belum ada motor di daftar favorit.", style: GoogleFonts.poppins(color: Colors.white54)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: motors.length,
            itemBuilder: (context, index) {
              final motor = motors[index];
              final safeImageUrl = motor.fotoMotor ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(motor: motor)));
                  },
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: safeImageUrl,
                      width: 60, height: 60, fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(Icons.motorcycle, color: Colors.white),
                    ),
                  ),
                  title: Text(motor.namaMotor, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(_formatRupiah(motor.harga), style: GoogleFonts.poppins(color: const Color(0xFFD4AF37), fontWeight: FontWeight.w600)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _removeFromWishlist(motor.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}