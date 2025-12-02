import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rentsoed_app/features/splash/splash_page.dart';
import 'package:rentsoed_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- KONEKSI KE SUPABASE ---
  await Supabase.initialize(
    url: 'https://sffjpwqexsecofgoaxgu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmZmpwd3FleHNlY29mZ29heGd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4MDY2OTAsImV4cCI6MjA3OTM4MjY5MH0.yxtGbfF8SApNeHtcK4_ro5lCLgp49jTS8LkvCAS8DVI',
  );

  await NotificationService.init();

  runApp(const RentsoedApp());
}

class RentsoedApp extends StatelessWidget {
  const RentsoedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rentsoed',
      debugShowCheckedModeBanner: false,
      theme: _buildLuxuryTheme(),

      // --- HANYA MENGARAHKAN KE SPLASH PAGE ---
      // SplashPage akan menangani logika cek sesi & role admin/customer
      home: const SplashPage(),
    );
  }

  // --- KONFIGURASI TEMA MEWAH (GOLD & DARK NAVY) ---
  ThemeData _buildLuxuryTheme() {
    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      primaryColor: const Color(0xFFD4AF37),

      textTheme: GoogleFonts.poppinsTextTheme(
        base.textTheme,
      ).apply(bodyColor: Colors.white, displayColor: const Color(0xFFD4AF37)),

      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFD4AF37),
        secondary: Color(0xFF64748B),
        surface: Color(0xFF1E293B),
        error: Color(0xFFEF4444),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}
