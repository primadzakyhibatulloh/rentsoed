import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'package:rentsoed_app/features/admin/promos/add_edit_promo_page.dart';

class ManagePromosPage extends StatelessWidget {
  const ManagePromosPage({super.key});

  String formatDate(String? dateStr) {
    if (dateStr == null) return "-";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return "Tanggal Invalid";
    }
  }

  // Fungsi untuk memformat nilai diskon berdasarkan tipe
  String formatDiscount(Map<String, dynamic> promo) {
    final value = promo['discount_value'] as int? ?? 0;
    final type = promo['discount_type'] as String? ?? 'percentage';

    if (type == 'fixed') {
      // Format sebagai Rupiah (fixed)
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
      return "${formatter.format(value)} OFF";
    } else {
      // Format sebagai Persen (percentage)
      return "$value% OFF";
    }
  }

  // Fungsi Delete Promo (ditingkatkan dengan konfirmasi)
  Future<void> _deletePromo(BuildContext context, String id, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Hapus Promo '$code'?", style: GoogleFonts.poppins(color: Colors.white)),
        content: const Text("Promo ini tidak akan bisa digunakan lagi.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal", style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('promos').delete().eq('id', id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Promo '$code' dihapus."), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal hapus: ${e.toString()}"), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("Kelola Promo", style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4AF37),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          // Ke Halaman Tambah Promo
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditPromoPage()),
          );
        },
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Ambil data dari tabel promos
        stream: Supabase.instance.client
            .from('promos')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada promo aktif.", style: TextStyle(color: Colors.white70)));
          }

          final promos = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: promos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final promo = promos[index];
              final isExpired = promo['expiry_date'] != null && DateTime.parse(promo['expiry_date']).isBefore(DateTime.now());
              final isActive = promo['is_active'] == true && !isExpired;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                tileColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  // Border merah jika sudah kadaluarsa atau tidak aktif
                  side: BorderSide(color: isActive ? Colors.transparent : Colors.red.withOpacity(0.5), width: 1),
                ),
                leading: CircleAvatar(
                  backgroundColor: isActive ? const Color(0xFFD4AF37).withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  child: Icon(Icons.local_offer, color: isActive ? const Color(0xFFD4AF37) : Colors.grey),
                ),
                title: Text(promo['code'] ?? 'NO CODE', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 💡 Menampilkan nilai diskon yang diformat
                    Text(
                      "${formatDiscount(promo)} - ${promo['description'] ?? ''}", 
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)
                    ),
                    // Menampilkan status dan tanggal kadaluarsa
                    Text(
                      isActive 
                        ? "Berlaku sampai: ${formatDate(promo['expiry_date'])}"
                        : (isExpired ? "Status: KADALUARSA" : "Status: TIDAK AKTIF"),
                      style: GoogleFonts.poppins(color: isActive ? Colors.greenAccent : Colors.redAccent, fontSize: 10)
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tombol Edit
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () {
                          Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddEditPromoPage(promo: promo)),
                        );
                      },
                    ),
                    // Tombol Hapus
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deletePromo(context, promo['id'], promo['code'] ?? 'Promo'),
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
}