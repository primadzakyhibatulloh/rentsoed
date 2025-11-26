import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import 'package:rentsoed_app/features/auth/login_page.dart';
import 'package:rentsoed_app/features/customer/profile/profile_page.dart'; 

// --- IMPORT HALAMAN BARU ---
import 'package:rentsoed_app/features/customer/voucher/promo_list_page.dart'; 
import 'package:rentsoed_app/features/customer/terms/terms_page.dart'; // <<< Import TermsPage

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  // Fungsi untuk membuka WhatsApp (Pusat Bantuan)
  Future<void> _launchWhatsApp() async {
    const phoneNumber = "628123456789"; 
    const message = "Halo Rentsoed, saya butuh bantuan.";
    final url = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Tidak bisa membuka WhatsApp");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    // Menggunakan data dari profiles jika tersedia, atau dari metadata
    final name = user?.userMetadata?['full_name'] ?? 'Rider Rentsoed'; 
    final email = user?.email ?? '-';

    return Drawer(
      backgroundColor: const Color(0xFF0F172A), // Navy
      child: Column(
        children: [
          // --- HEADER USER ---
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B), // Navy lebih terang
              border: Border(bottom: BorderSide(color: Color(0xFFD4AF37), width: 1)),
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                color: Colors.white10,
              ),
              child: const Icon(Icons.person, size: 40, color: Colors.white70),
            ),
            accountName: Text(name, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFFD4AF37))),
            accountEmail: Text(email, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
          ),

          // --- MENU ITEMS ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  Icons.local_offer, 
                  "Voucher & Promo", 
                  () {
                    Navigator.pop(context);
                    // Navigasi ke Halaman Promo
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PromoListPage()));
                  }
                ),
                _buildDrawerItem(
                  Icons.description, 
                  "Syarat & Ketentuan", 
                  () {
                    Navigator.pop(context);
                    // Navigasi ke Halaman Terms (Syarat & Ketentuan)
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsPage()));
                  }
                ),
                _buildDrawerItem(
                  Icons.help_center, 
                  "Pusat Bantuan", 
                  () {
                    Navigator.pop(context);
                    _launchWhatsApp(); // Memanggil fungsi WhatsApp
                  }
                ),
                _buildDrawerItem(
                  Icons.info_outline, 
                  "Tentang Rentsoed", 
                  () {
                    Navigator.pop(context);
                    showAboutDialog(
                      context: context,
                      applicationName: "Rentsoed",
                      applicationVersion: "1.0.0",
                    );
                  }
                ),
                const Divider(color: Colors.white10),
                _buildDrawerItem(
                  Icons.settings, 
                  "Pengaturan Profil", 
                  () {
                    Navigator.pop(context);
                    // Navigasi ke Profile Page
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
                  }
                ),
              ],
            ),
          ),

          // --- LOGOUT DI BAWAH ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  // Tampilkan dialog konfirmasi logout
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      title: Text("Logout", style: GoogleFonts.poppins(color: Colors.white)),
                      content: Text("Apakah Anda yakin ingin keluar?", style: GoogleFonts.poppins(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false), 
                          child: const Text("Batal")
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true), 
                          child: const Text("Keluar", style: TextStyle(color: Colors.red))
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
                    }
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: Text("LOGOUT", style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: const Color(0xFFD4AF37)),
      title: Text(title, style: GoogleFonts.poppins(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
      onTap: onTap,
      hoverColor: Colors.white.withOpacity(0.05),
    );
  }
}