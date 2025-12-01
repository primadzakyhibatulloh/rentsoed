import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:rentsoed_app/features/customer/payment/payment_page.dart';
import 'package:rentsoed_app/features/customer/history/rate_page.dart';
import 'package:postgrest/postgrest.dart';

// --- HISTORY PAGE DIBUAT STATEFUL UNTUK REFRESH DATA ---
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Variabel yang digunakan untuk memicu refresh StreamBuilder
  Key _streamKey = UniqueKey();
  final supabase = Supabase.instance.client;

  // Helper: Format Tanggal
  String formatDate(String? dateStr) {
    if (dateStr == null) return "-";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // Helper: Format Rupiah
  String formatRupiah(int number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  // Helper: Warna Status
  Map<String, dynamic> getStatusVisuals(String status) {
    switch (status) {
      case 'Menunggu Pembayaran':
        return {'color': Colors.orangeAccent, 'icon': Icons.access_time_filled};
      case 'Dibayar':
        return {'color': Colors.lightBlueAccent, 'icon': Icons.payment};
      case 'Selesai':
        return {
          'color': Colors.lightGreenAccent,
          'icon': Icons.check_circle_outline,
        };
      case 'Dibatalkan':
        return {'color': Colors.redAccent, 'icon': Icons.cancel_outlined};
      default:
        return {'color': Colors.grey, 'icon': Icons.pending};
    }
  }

  // Helper: Cek apakah user sudah memberi ulasan
  Future<bool> _hasReviewed(String bookingId) async {
    try {
      final response = await supabase
          .from('reviews')
          .select('id')
          .eq('booking_id', bookingId)
          .limit(1)
          .count(CountOption.exact);

      return response.count > 0;
    } catch (e) {
      return false;
    }
  }

  // Fungsi untuk memicu refresh stream (dipanggil setelah kembali dari RatePage)
  void _refreshHistory() {
    setState(() {
      _streamKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Riwayat Booking",
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: userId == null
          ? const Center(
              child: Text(
                "Anda belum login.",
                style: TextStyle(color: Colors.white54),
              ),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              key: _streamKey, // Gunakan key untuk memicu reload stream
              stream: supabase
                  .from('bookings')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', userId)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Terjadi kesalahan: ${snapshot.error}",
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.history,
                          size: 80,
                          color: Colors.white24,
                        ),
                        const Gap(16),
                        Text(
                          "Belum ada riwayat booking",
                          style: GoogleFonts.poppins(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }

                final bookings = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: bookings.length,
                  separatorBuilder: (context, index) => const Gap(16),
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final docId = booking['id'];

                    return _HistoryCard(
                      booking: booking,
                      formatDate: formatDate,
                      formatRupiah: formatRupiah,
                      getStatusVisuals: getStatusVisuals,
                      hasReviewedFuture: _hasReviewed(docId),
                      refreshCallback: _refreshHistory, // Pass fungsi refresh
                    );
                  },
                );
              },
            ),
    );
  }
}

// ===================================================================
// WIDGET CARD RIWAYAT BARU (Mewah & Interaktif)
// ===================================================================

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String Function(String?) formatDate;
  final String Function(int) formatRupiah;
  final Map<String, dynamic> Function(String) getStatusVisuals;
  final Future<bool> hasReviewedFuture;
  final VoidCallback refreshCallback; // Callback untuk refresh HistoryPage

  const _HistoryCard({
    required this.booking,
    required this.formatDate,
    required this.formatRupiah,
    required this.getStatusVisuals,
    required this.hasReviewedFuture,
    required this.refreshCallback,
  });

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? 'Proses';
    final statusVisuals = getStatusVisuals(status);
    final statusColor = statusVisuals['color'] as Color;
    final statusIcon = statusVisuals['icon'] as IconData;

    return FutureBuilder<bool>(
      future: hasReviewedFuture,
      builder: (context, reviewSnapshot) {
        final hasReviewed = reviewSnapshot.data ?? false;

        return Card(
          color: const Color(0xFF1E293B), // Navy Lebih Terang
          elevation: 8,
          shadowColor: statusColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: status == 'Menunggu Pembayaran'
                  ? const Color(0xFFD4AF37)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: () {
              // Opsional: Navigasi ke Detail Booking
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER: STATUS & ICON ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // Tambahkan crossAxisAlignment
                        children: [
                          Icon(statusIcon, color: statusColor, size: 20),
                          const Gap(8),
                          Text(
                            status,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Ikon Informasi Tambahan
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),

                  const Gap(12),
                  const Divider(color: Colors.white10),
                  const Gap(12),

                  // --- MOTOR & TOTAL PRICE (FIX 1: Truncation dan Proporsi Harga) ---
                  Row(
                    // Hapus textBaseline yang berlebihan di sini
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // Center alignment vertikal
                    children: [
                      // Nama Motor - Fleksibel dengan sedikit ruang ekstra
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking['motor_name'] ?? 'Motor Tidak Diketahui',
                              style: GoogleFonts.playfairDisplay(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontSize: 20,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(4),
                            Text(
                              "(${booking['total_days']} Hari)",
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Harga - Alignment di kanan
                      Expanded(
                        flex: 3,
                        child: Text(
                          formatRupiah(booking['total_price'] ?? 0),
                          textAlign: TextAlign.end,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD4AF37),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Gap(4) dan (Total Hari) dipindahkan ke dalam Column di atas.
                  const Gap(20),

                  // --- TANGGAL (FIX 2: Menggunakan Expanded/Flexible) ---
                  Row(
                    children: [
                      // Mulai
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.white54,
                            ),
                            const Gap(6),
                            Flexible(
                              // Pastikan teks yang panjang akan terpotong
                              child: Text(
                                "Mulai: ${formatDate(booking['start_date'])}",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Selesai
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.white54,
                            ),
                            const Gap(6),
                            Flexible(
                              child: Text(
                                "Selesai: ${formatDate(booking['end_date'])}",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Gap(20),

                  // --- TOMBOL AKSI ---
                  _buildActionButton(context, status, booking, hasReviewed),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget untuk membangun tombol aksi
  Widget _buildActionButton(
    BuildContext context,
    String status,
    Map<String, dynamic> booking,
    bool hasReviewed,
  ) {
    if (status == 'Menunggu Pembayaran') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPage(
                  bookingId: booking['id'],
                  totalPrice: booking['total_price'],
                  motorName: booking['motor_name'],
                ),
              ),
            );
          },
          icon: const Icon(Icons.payment, color: Color(0xFF0F172A)),
          label: Text(
            "LANJUTKAN PEMBAYARAN",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    } else if (status == 'Selesai') {
      return SizedBox(
        width: double.infinity,
        child: hasReviewed
            ? OutlinedButton.icon(
                onPressed: null, // Disable button
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Colors.lightGreenAccent,
                ),
                label: Text(
                  "Ulasan Terkirim",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.lightGreenAccent,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.lightGreenAccent.withOpacity(0.5),
                  ),
                ),
              )
            : OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RatePage(bookingData: booking),
                    ),
                  );
                  // Trigger refresh data jika ulasan sukses dikirim (result == true)
                  if (result == true) {
                    refreshCallback(); // Panggil callback refresh
                  }
                },
                icon: const Icon(Icons.star_border, color: Color(0xFFD4AF37)),
                label: Text(
                  "BERI ULASAN",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD4AF37),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
      );
    }

    return const SizedBox.shrink(); // Hide button for 'Dibayar' or 'Dibatalkan'
  }
}
