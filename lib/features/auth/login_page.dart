import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rentsoed_app/features/auth/register_page.dart';
import 'package:rentsoed_app/features/main_page.dart'; // Pastikan file ini ada!
import 'package:rentsoed_app/features/admin/dashboard/admin_dashboard.dart'; // Import Halaman Admin
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gap/gap.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- FUNGSI LOGIN SUPABASE ---
  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // 1. Login ke Supabase
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Cek Hasil Login
      if (response.user != null) {
        final user = response.user;
        final role = user?.userMetadata?['role'] ?? 'customer';

        Widget targetPage;

        // Tentukan Halaman Tujuan (Admin vs Customer)
        if (role == 'admin') {
          targetPage = const AdminDashboard();
        } else {
          targetPage = const MainPage(); // Ke Halaman Utama (Bottom Bar)
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Login Berhasil! Selamat Datang, ${user?.email?.split('@')[0]}.",
              ),
              backgroundColor: Colors.green,
            ),
          );

          // 3. Pindah Halaman
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => targetPage),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI LOGIN DENGAN GOOGLE ---
  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // 1. Dapatkan kredensial dari Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn(); // Membuka pop-up Google
      final googleAuth = await googleUser?.authentication;

      if (googleAuth?.idToken != null) {
        // 2. Kirim idToken Google ke Supabase untuk diotorisasi
        final response = await supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: googleAuth!.idToken!,
        );

        // 3. Cek hasil Supabase dan Navigasi
        if (response.user != null) {
          final user = response.user;
          // Ambil peran dari metadata pengguna
          final role = user?.userMetadata?['role'] ?? 'customer';

          Widget targetPage = (role == 'admin')
              ? const AdminDashboard()
              : const MainPage();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Login Google Berhasil!"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => targetPage),
            );
          }
        }
      } else {
        // Pengguna membatalkan login Google
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login Google dibatalkan."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      // Tangani error dari Supabase
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Supabase Auth Error: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Tangani error umum (misalnya, masalah koneksi)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Background Navy Mewah
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(80),
              // LOGO & JUDUL
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.motorcycle_outlined,
                      size: 80,
                      color: const Color(0xFFD4AF37),
                    ).animate().scale(duration: 600.ms),
                    const Gap(10),
                    Text(
                      "RENTSOED",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD4AF37), // Emas
                        letterSpacing: 2,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                  ],
                ),
              ),
              const Gap(60),

              // FORM SECTION
              Text(
                "Welcome Back,",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ).animate().fadeIn(delay: 200.ms),
              Text(
                "Sign in to start your journey.",
                style: GoogleFonts.poppins(color: Colors.white54),
              ).animate().fadeIn(delay: 300.ms),

              const Gap(30),

              // INPUT EMAIL
              _buildLuxuryTextField(
                controller: _emailController,
                label: "Email Address",
                icon: Icons.email_outlined,
              ),
              const Gap(20),

              // INPUT PASSWORD
              _buildLuxuryTextField(
                controller: _passwordController,
                label: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const Gap(40),

              // TOMBOL LOGIN MEWAH
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37), // Warna Emas
                    foregroundColor: const Color(0xFF0F172A), // Text Navy
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFF0F172A),
                        )
                      : Text(
                          "LOGIN",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

              const Gap(20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : _loginWithGoogle, // Memanggil fungsi login Google
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    width: 24,
                    height: 24,
                  ),
                  label: Text(
                    _isLoading ? "Memproses..." : "Sign In with Google",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                ),
              ),

              const Gap(20),

              // LINK KE REGISTER
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: GoogleFonts.poppins(color: Colors.white54),
                      children: [
                        TextSpan(
                          text: "Sign Up",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET INPUT FIELD CUSTOM (GLASS STYLE)
  Widget _buildLuxuryTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), // Efek Kaca Gelap
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
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
