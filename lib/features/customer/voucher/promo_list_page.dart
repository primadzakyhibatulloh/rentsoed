import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // PENTING: Untuk fitur Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart'; 
import 'package:intl/intl.dart'; 
import '../../../models/promo_model.dart'; // Pastikan path import model ini sesuai dengan struktur folder Anda

class PromoListPage extends StatefulWidget {
  const PromoListPage({super.key});

  @override
  State<PromoListPage> createState() => _PromoListPageState();
}

class _PromoListPageState extends State<PromoListPage> {
  // Gunakan late final untuk Future agar data tidak di-load ulang setiap set state
  late final Future<List<PromoModel>> _promoFuture;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _promoFuture = _fetchActivePromos();
  }

  // Fungsi untuk mengambil promo aktif dari Supabase
  Future<List<PromoModel>> _fetchActivePromos() async {
    try {
      final nowIso = DateTime.now().toIso8601String();

      final response = await supabase
          .from('promos')
          .select()
          .eq('is_active', true) // Hanya ambil yang status aktifnya TRUE
          .gte('expiry_date', nowIso) // Hanya ambil yang belum kadaluarsa
          .order('expiry_date', ascending: true); // Urutkan dari yang paling cepat habis

      // Konversi data JSON ke List<PromoModel>
      final List<PromoModel> promos = (response as List).map((json) => PromoModel.fromJson(json)).toList();
      return promos;
    } catch (e) {
      debugPrint('Error fetching promos: $e');
      rethrow; // Lempar error agar ditangkap oleh FutureBuilder
    }
  }

  // Helper untuk memformat tampilan nilai diskon
  String _formatDiscount(PromoModel promo) {
    if (promo.discountType == 'percentage') {
      return "${promo.discountValue}%";
    } else {
      final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
      return formatter.format(promo.discountValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Background Navy Gelap
      appBar: AppBar(
        title: Text(
          "Klaim Promo Eksklusif", 
          style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<PromoModel>>(
        future: _promoFuture,
        builder: (context, snapshot) {
          // 1. KONDISI LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }

          // 2. KONDISI ERROR
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 50, color: Colors.redAccent),
                    const Gap(10),
                    Text(
                      "Terjadi kesalahan saat memuat promo.", 
                      style: GoogleFonts.poppins(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(5),
                    Text(
                      "${snapshot.error}", // Tampilkan detail error untuk debugging
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. KONDISI DATA KOSONG
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_activity_outlined, size: 60, color: Colors.white24),
                  const Gap(16),
                  Text(
                    "Belum ada voucher aktif saat ini.", 
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // 4. KONDISI SUKSES (Tampilkan List)
          final promos = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              final isPercentage = promo.discountType == 'percentage';
              
              return _PromoCard(
                code: promo.code,
                discountText: isPercentage 
                    ? "Diskon ${_formatDiscount(promo)} Sewa Anda!"
                    : "Potongan ${_formatDiscount(promo)}!",
                description: promo.description ?? "Berlaku untuk semua transaksi.",
                expiryDate: promo.expiryDate,
                
                // LOGIKA COPY CODE
                onTap: () async {
                  // 1. Salin ke Clipboard
                  await Clipboard.setData(ClipboardData(text: promo.code));

                  // 2. Tampilkan Notifikasi (SnackBar)
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.black),
                            const Gap(10),
                            Expanded(
                              child: Text(
                                "Kode ${promo.code} berhasil disalin!",
                                style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFFD4AF37), // Warna Emas
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ====================================================================
// WIDGET CARD: TAMPILAN TIKET MEWAH
// ====================================================================

class _PromoCard extends StatelessWidget {
  final String code;
  final String discountText;
  final String description;
  final DateTime? expiryDate; // Nullable agar aman
  final VoidCallback? onTap;

  const _PromoCard({
    required this.code,
    required this.discountText,
    required this.description,
    this.expiryDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Navy Terang
          borderRadius: BorderRadius.circular(12),
          // Shadow Emas Lembut
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight( // Agar tinggi kiri dan kanan sama
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Bagian KIRI: Informasi ---
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Judul Diskon
                      Text(
                        discountText,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFD4AF37), // Emas
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          height: 1.2,
                        ),
                      ),
                      const Gap(8),
                      // Deskripsi
                      Text(
                        description,
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(12),
                      // Tanggal Kadaluarsa
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white54, size: 14),
                          const Gap(6),
                          Text(
                            expiryDate != null 
                              ? "Berlaku s/d: ${dateFormat.format(expiryDate!)}"
                              : "Periode: Selamanya",
                            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // --- Garis Putus-putus Pemisah (Visual Tiket) ---
              Container(
                width: 1,
                color: Colors.white10,
                margin: const EdgeInsets.symmetric(vertical: 10),
              ),

              // --- Bagian KANAN: Kode & Tombol ---
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A), // Navy Gelap Kontras
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.confirmation_number_outlined, color: Colors.white54, size: 20),
                      const Gap(8),
                      // Kode Promo
                      Text(
                        code,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                      const Gap(8),
                      // Tombol Kecil
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Salin", 
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF0F172A), 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}