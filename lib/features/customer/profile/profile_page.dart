import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rentsoed_app/features/auth/login_page.dart';
import 'package:rentsoed_app/features/customer/profile/edit_profile_page.dart'; // Pastikan file ini sudah dibuat

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Ambil user saat ini
  final user = Supabase.instance.client.auth.currentUser;
  String? fullName;
  String? email;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      // Ambil nama dari metadata (saat register/edit), default ke 'Rider Rentsoed'
      fullName = user?.userMetadata?['full_name'] ?? 'Rider Rentsoed';
      email = user?.email ?? '-';
    });
  }

  // --- FUNGSI BUKA WHATSAPP ---
  Future<void> _openWhatsApp() async {
    // Ganti nomor ini dengan nomor Admin Rental Anda (Format: 628...)
    final Uri url = Uri.parse("https://wa.me/6281234567890?text=Halo%20Admin%20Rentsoed,%20saya%20butuh%20bantuan.");
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal membuka WhatsApp, pastikan aplikasi terinstall.")),
        );
      }
    }
  }

  // --- FUNGSI LOGOUT ---
  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      // Hapus semua route dan kembali ke Login Page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Background Navy
      appBar: AppBar(
        // --- PERBAIKAN: TOMBOL BACK DITAMBAHKAN ---
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Profile", 
          style: GoogleFonts.playfairDisplay(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- FOTO PROFIL (Avatar) ---
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  color: Colors.white10,
                ),
                child: const Icon(Icons.person, size: 60, color: Colors.white54),
              ),
            ),
            const Gap(16),
            
            // --- NAMA & EMAIL ---
            Text(
              fullName ?? "User",
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              email ?? "-",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
            ),
            const Gap(40),

            // --- MENU PILIHAN ---
            _buildMenuTile(
              icon: Icons.edit,
              title: "Edit Profile",
              onTap: () {
                // Navigasi ke Halaman Edit Profile
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const EditProfilePage())
                ).then((_) => _loadUserData()); // Refresh data setelah kembali dari edit
              },
            ),
            const Gap(16),
            
            _buildMenuTile(
              icon: Icons.help_outline,
              title: "Pusat Bantuan (WhatsApp)",
              onTap: _openWhatsApp,
            ),
            const Gap(16),
            
            _buildMenuTile(
              icon: Icons.info_outline,
              title: "Tentang Aplikasi",
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: "Rentsoed",
                  applicationVersion: "1.0.0",
                  applicationLegalese: "© 2025 Rentsoed Team",
                );
              },
            ),
            
            const Gap(50),
            
            // --- TOMBOL LOGOUT ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text("LOGOUT", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Item Menu
  Widget _buildMenuTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFD4AF37)),
            const Gap(16),
            Expanded(child: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16))),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }
}