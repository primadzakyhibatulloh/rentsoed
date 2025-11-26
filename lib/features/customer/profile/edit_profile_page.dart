import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';
import 'package:rentsoed_app/features/main_page.dart'; // Navigasi kembali ke MainPage

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Isi kolom nama dengan nama yang sudah ada di Supabase saat halaman dibuka
    final user = Supabase.instance.client.auth.currentUser;
    _nameController.text = user?.userMetadata?['full_name'] ?? '';
  }

  // Fungsi untuk menyimpan perubahan nama
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      
      // Update Metadata User di Supabase Auth
      await supabase.auth.updateUser(
        UserAttributes(
          data: {'full_name': _nameController.text.trim()}, // Kolom yang diupdate
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil diperbarui!"), backgroundColor: Colors.green),
        );
        // Kembali ke MainPage (Profile Tab) dan hapus halaman edit
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const MainPage()), 
          (route) => false
        );
      }
    } on AuthException catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: ${e.message}"), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Background Navy
      appBar: AppBar(
        title: Text("Edit Profile", style: GoogleFonts.playfairDisplay(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.transparent, elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nama Lengkap", style: GoogleFonts.poppins(color: Colors.white54)),
            const Gap(10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05), 
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: Colors.white.withOpacity(0.1))
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person, color: Color(0xFFD4AF37)),
                  border: InputBorder.none, 
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
              ),
            ),
            const Gap(40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black) 
                  : Text("SIMPAN PERUBAHAN", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}