import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Data Dummy Syarat & Ketentuan (Bisa diganti dengan data asli/API)
    final List<Map<String, dynamic>> termsData = [
      {
        "title": "Persyaratan Sewa",
        "icon": Icons.assignment_ind_outlined,
        "content": "1. Penyewa wajib memiliki e-KTP asli yang masih berlaku.\n"
            "2. Penyewa wajib memiliki SIM C yang masih aktif.\n"
            "3. Bersedia difoto bersama unit motor saat serah terima.\n"
            "4. Meninggalkan jaminan berupa identitas asli (KTP/NPWP/KTM) selama masa sewa."
      },
      {
        "title": "Pembayaran & Deposit",
        "icon": Icons.account_balance_wallet_outlined,
        "content": "1. Pembayaran sewa dilakukan LUNAS di muka saat pengambilan unit.\n"
            "2. Deposit keamanan (jika ada) akan dikembalikan 100% setelah unit kembali tanpa kerusakan.\n"
            "3. Keterlambatan pengembalian akan dikenakan denda sebesar Rp 20.000/jam."
      },
      {
        "title": "Tanggung Jawab & Larangan",
        "icon": Icons.gpp_maybe_outlined,
        "content": "1. Dilarang keras menggunakan unit untuk balap liar atau tindak kejahatan.\n"
            "2. Segala bentuk kerusakan akibat kelalaian penyewa (jatuh, tabrakan) menjadi tanggung jawab penyewa sepenuhnya.\n"
            "3. Kehilangan unit motor mewajibkan penyewa mengganti unit baru sesuai tipe yang sama."
      },
      {
        "title": "Fasilitas & Penggunaan",
        "icon": Icons.motorcycle_outlined,
        "content": "1. Harga sewa sudah termasuk 2 Helm SNI dan 1 Jas Hujan.\n"
            "2. Motor diserahkan dalam keadaan bensin terisi (minimal 1 bar), dan wajib dikembalikan pada posisi yang sama.\n"
            "3. Penggunaan hanya diizinkan di dalam area wilayah Banyumas dan sekitarnya (kecuali ada izin khusus)."
      },
      {
        "title": "Kebijakan Pembatalan",
        "icon": Icons.cancel_outlined,
        "content": "1. Pembatalan H-1 akan dikenakan biaya administrasi 20%.\n"
            "2. Pembatalan pada hari H (mendadak) uang muka hangus/tidak dapat dikembalikan."
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Navy Gelap
      appBar: AppBar(
        title: Text(
          "Syarat & Ketentuan",
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFD4AF37), // Emas
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // --- Header Deskripsi Singkat ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              "Mohon baca syarat dan ketentuan berikut dengan seksama demi kenyamanan dan keamanan berkendara Anda bersama Rentsoed.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
          ),
          
          const Divider(color: Colors.white10, thickness: 1, height: 30),

          // --- List Accordion ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: termsData.length,
              itemBuilder: (context, index) {
                final item = termsData[index];
                return _TermCard(
                  title: item['title'],
                  content: item['content'],
                  icon: item['icon'],
                );
              },
            ),
          ),

          // --- Footer Copyright ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "Terakhir diperbarui: November 2025\n© Rentsoed Management",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white24, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// Widget Custom Accordion yang Mewah
// =======================================================
class _TermCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _TermCard({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Navy Lebih Terang
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        // Menghilangkan garis divider bawaan ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFFD4AF37), // Warna Panah saat aktif
          collapsedIconColor: Colors.white54, // Warna Panah saat diam
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          
          // Ikon di kiri
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          ),
          
          // Judul
          title: Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          
          // Isi Konten (Muncul saat diklik)
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Text(
                content,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.6, // Spasi baris agar mudah dibaca
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ),
    );
  }
}