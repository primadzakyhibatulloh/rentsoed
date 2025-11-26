import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rentsoed_app/features/admin/categories/add_edit_category_page.dart'; 

class ManageCategoriesPage extends StatelessWidget {
  const ManageCategoriesPage({super.key});

  // Fungsi untuk menampilkan konfirmasi sebelum menghapus kategori
  Future<void> _confirmAndDelete(BuildContext context, String id, String categoryName) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text("Hapus Kategori", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text("Yakin ingin menghapus kategori '$categoryName'? Semua motor dengan kategori ini akan kehilangan relasinya!", style: GoogleFonts.poppins(color: Colors.white70)),
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
        // Hapus kategori dari Supabase
        await Supabase.instance.client.from('categories').delete().eq('id', id);
        // Tampilkan pesan sukses
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kategori '$categoryName' berhasil dihapus.")));
        }
      } catch (e) {
        // Penanganan error (misalnya: gagal karena masih ada motor yang merujuk)
        String errorMessage = "Gagal menghapus. Pastikan tidak ada motor yang masih menggunakan kategori ini.";
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
        title: Text("Kelola Kategori", style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        // 💡 Memperbaiki warna FAB
        backgroundColor: const Color(0xFFD4AF37), // Warna Emas/Kuning
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditCategoryPage()));
        },
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // 💡 Menggunakan kolom 'nama_kategori' (sesuai skema baru) untuk ordering
        stream: Supabase.instance.client.from('categories').stream(primaryKey: ['id']).order('nama_kategori', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada kategori.", style: TextStyle(color: Colors.white70)));
          }

          final categories = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              final categoryName = category['nama_kategori'] as String; // Nama kolom baru

              return ListTile(
                tileColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                // 💡 Menampilkan 'nama_kategori'
                title: Text(categoryName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: category['ikon_url'] != null ? Text("Ikon: Tersedia", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)) : null,
                leading: category['ikon_url'] != null
                    ? CircleAvatar(backgroundImage: NetworkImage(category['ikon_url']), radius: 20)
                    : const CircleAvatar(child: Icon(Icons.category, size: 20)),
                
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tombol Edit
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent), 
                      onPressed: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => AddEditCategoryPage(category: category))
                      )
                    ),
                    // Tombol Hapus (memanggil fungsi konfirmasi)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent), 
                      onPressed: () => _confirmAndDelete(context, category['id'], categoryName)
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