import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rentsoed_app/features/admin/motors/add_edit_motor_page.dart';

class ManageMotorsPage extends StatelessWidget {
  const ManageMotorsPage({super.key});

  // Fungsi untuk menampilkan konfirmasi dan menghapus motor
  Future<void> _confirmAndDelete(BuildContext context, String id, String motorName) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text("Hapus Motor", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text("Yakin ingin menghapus motor '$motorName'? Data motor ini akan hilang secara permanen!", style: GoogleFonts.poppins(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Batal
              child: Text("BATAL", style: GoogleFonts.poppins(color: Colors.blueAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Hapus
              child: Text("HAPUS", style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        // Hapus motor dari Supabase
        await Supabase.instance.client.from('motors').delete().eq('id', id);
        // Tampilkan pesan sukses
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Motor '$motorName' berhasil dihapus.")));
        }
      } catch (e) {
        // Penanganan error
        String errorMessage = "Gagal menghapus motor. Error: ${e.toString()}";
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("Kelola Motor", style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4AF37),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditMotorPage()));
        },
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Menggunakan nama kolom yang baru 'nama_motor' untuk ordering jika diinginkan
        // Saat ini tetap menggunakan 'created_at'
        stream: Supabase.instance.client.from('motors').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada motor.", style: TextStyle(color: Colors.white70)));
          }

          final motors = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: motors.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final motor = motors[index];
              final isAvailable = motor['is_available'] == true;
              final motorName = motor['nama_motor'] ?? 'Motor Tanpa Nama'; // Nama kolom baru

              // Format harga dengan titik sebagai pemisah ribuan
              final price = (motor['harga'] as int?)?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.') ?? '0';
              
              return ListTile(
                contentPadding: const EdgeInsets.all(12),
                tileColor: isAvailable ? const Color(0xFF1E293B) : const Color(0xFF1E293B).withOpacity(0.5), // Warna gelap jika tidak tersedia
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isAvailable ? Colors.transparent : Colors.red.withOpacity(0.5), width: 1),
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    // 💡 Menggunakan 'foto_motor' (nama kolom baru)
                    imageUrl: motor['foto_motor'] ?? '',
                    width: 60, height: 60, fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(Icons.motorcycle, color: Colors.white, size: 30),
                  ),
                ),
                // 💡 Menggunakan 'nama_motor'
                title: Text(motorName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  // Menampilkan harga, CC, dan status
                  "Rp $price/hari | CC ${motor['cc'] ?? '-'} | Status: ${isAvailable ? 'Tersedia' : 'Tidak Tersedia'}", 
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tombol Edit
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue), 
                      onPressed: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => AddEditMotorPage(motor: motor))
                      )
                    ),
                    // Tombol Hapus (memanggil fungsi konfirmasi)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red), 
                      onPressed: () => _confirmAndDelete(context, motor['id'], motorName)
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