import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Ganti Firebase ke Supabase
import 'package:gap/gap.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- FUNGSI REGISTER SUPABASE ---
  Future<void> _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama dan Email harus diisi!"))
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // 1. Buat Akun di Supabase Auth
      final AuthResponse response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        // Simpan Nama di Metadata User (Fitur bawaan Supabase)
        data: {
          'full_name': _nameController.text.trim(),
          'role': 'customer',
        },
      );

      // 2. Simpan Data Tambahan ke Tabel 'bookings' (Opsional, jika ingin bikin profil terpisah)
      // Tapi untuk sekarang, metadata di atas sudah cukup.
      // Nanti kalau mau bikin tabel 'profiles', bisa insert di sini.

      if (response.user != null) {
        if (mounted) {
          Navigator.pop(context); // Kembali ke Login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registrasi Berhasil! Silakan Login."),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      // Error Khusus Supabase
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // Error Umum
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Account",
                style: GoogleFonts.playfairDisplay(
                    fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37)),
              ),
              const Gap(10),
              Text(
                "Join Rentsoed exclusive member.",
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
              const Gap(40),

              // INPUT NAMA
              _buildLuxuryTextField(_nameController, "Full Name", Icons.person_outline),
              const Gap(20),
              // INPUT EMAIL
              _buildLuxuryTextField(_emailController, "Email Address", Icons.email_outlined),
              const Gap(20),
              // INPUT PASSWORD
              _buildLuxuryTextField(_passwordController, "Password", Icons.lock_outline, isPassword: true),
              const Gap(40),

              // TOMBOL REGISTER
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Color(0xFF0F172A))
                      : Text("SIGN UP", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
          hintText: label,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }
}