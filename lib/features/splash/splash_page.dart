import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rentsoed_app/features/auth/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Jalankan timer untuk animasi
    _startSplashTimer();
  }

  Future<void> _startSplashTimer() async {
    // Tunggu 3 detik agar animasi selesai
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Langsung pindah ke Halaman Login setelah animasi
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Background Navy Gelap
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- LOGO MOTOR (ANIMASI) ---
            Icon(
              Icons.motorcycle_outlined,
              size: 120,
              color: const Color(0xFFD4AF37), // Emas
            )
            .animate()
            .fadeIn(duration: 1000.ms) 
            .scale(delay: 500.ms, duration: 800.ms, curve: Curves.elasticOut)
            .shimmer(delay: 1500.ms, duration: 1000.ms, color: Colors.white38),

            const SizedBox(height: 20),

            // --- JUDUL ---
            Text(
              "RENTSOED",
              style: GoogleFonts.playfairDisplay(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD4AF37),
                letterSpacing: 4,
              ),
            )
            .animate()
            .fadeIn(delay: 500.ms, duration: 800.ms)
            .slideY(begin: 0.5, end: 0, curve: Curves.easeOutQuad),

            const SizedBox(height: 10),

            // --- SLOGAN ---
            Text(
              "Sewa Motor Mewah & Mudah",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white54,
              ),
            )
            .animate()
            .fadeIn(delay: 1000.ms, duration: 800.ms),

            const SizedBox(height: 60),

            // --- LOADING INDICATOR ---
            const CircularProgressIndicator(
              color: Color(0xFFD4AF37),
              strokeWidth: 3,
            )
            .animate()
            .fadeIn(delay: 1500.ms),
          ],
        ),
      ),
    );
  }
}