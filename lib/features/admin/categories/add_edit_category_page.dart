import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';

class AddEditCategoryPage extends StatefulWidget {
  // Menggunakan Map<String, dynamic> karena belum menggunakan CategoryModel
  final Map<String, dynamic>? category; 
  const AddEditCategoryPage({super.key, this.category});

  @override
  State<AddEditCategoryPage> createState() => _AddEditCategoryPageState();
}

class _AddEditCategoryPageState extends State<AddEditCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _iconUrlCtrl = TextEditingController(); // Kontroler BARU untuk ikon_url
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 💡 Inisialisasi data untuk mode EDIT
    if (widget.category != null) {
      // Menggunakan nama kolom yang baru: 'nama_kategori' dan 'ikon_url'
      _nameCtrl.text = widget.category!['nama_kategori'] ?? '';
      _iconUrlCtrl.text = widget.category!['ikon_url'] ?? '';
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    // 💡 Menyesuaikan nama kolom dengan skema SQL baru
    final data = {
      'nama_kategori': _nameCtrl.text.trim(), 
      'ikon_url': _iconUrlCtrl.text.trim().isEmpty ? null : _iconUrlCtrl.text.trim(), // Pastikan null jika kosong
    };

    try {
      final supabase = Supabase.instance.client;

      if (widget.category == null) {
        // Mode Tambah (INSERT)
        await supabase.from('categories').insert(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kategori berhasil ditambahkan!")));
        }
      } else {
        // Mode Edit (UPDATE)
        await supabase.from('categories').update(data).eq('id', widget.category!['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kategori berhasil diperbarui!")));
        }
      }
      
      if (mounted) Navigator.pop(context);
      
    } catch (e) {
      if (mounted) {
        // Penanganan error khusus (misalnya: nama kategori sudah ada/UNIQUE constraint)
        String errorMessage = "Terjadi kesalahan saat menyimpan data.";
        if (e.toString().contains('categories_nama_kategori_key')) {
          errorMessage = "Nama kategori sudah ada. Mohon gunakan nama lain.";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // Membersihkan kontroler saat widget dibuang
  @override
  void dispose() {
    _nameCtrl.dispose();
    _iconUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Menyesuaikan Judul
    final isEditing = widget.category != null;
    final title = isEditing ? "Edit Kategori" : "Tambah Kategori Baru";
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView( // Menggunakan SingleChildScrollView untuk mencegah overflow
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Input Nama Kategori (Wajib diisi)
                TextFormField(
                  controller: _nameCtrl, 
                  style: const TextStyle(color: Colors.white), 
                  validator: (val) => val!.isEmpty ? "Nama kategori wajib diisi" : null, 
                  decoration: const InputDecoration(
                    labelText: "Nama Kategori", 
                    filled: true, 
                    fillColor: Colors.white10,
                  ),
                ),
                
                const Gap(20),
                
                // 2. Input URL Ikon/Gambar Kategori (Opsional)
                TextFormField(
                  controller: _iconUrlCtrl, 
                  keyboardType: TextInputType.url,
                  style: const TextStyle(color: Colors.white), 
                  decoration: const InputDecoration(
                    labelText: "URL Ikon/Gambar", 
                    hintText: "Contoh: https://example.com/icon.png (Opsional)",
                    filled: true, 
                    fillColor: Colors.white10
                  ),
                ),
                
                const Gap(40),
                
                // 3. Tombol SIMPAN
                SizedBox(
                  width: double.infinity, 
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, 
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: _isLoading ? null : _saveCategory, 
                    child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) 
                        : Text(isEditing ? "PERBARUI" : "SIMPAN", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}