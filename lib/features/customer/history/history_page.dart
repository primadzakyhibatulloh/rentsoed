import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:rentsoed_app/features/customer/payment/payment_page.dart'; 
import 'package:rentsoed_app/features/customer/history/rate_page.dart'; 

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

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
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  // Helper: Warna Status
  Color getStatusColor(String status) {
    switch (status) {
      case 'Menunggu Pembayaran':
        return Colors.orangeAccent;
      case 'Dibayar': // Status setelah Admin verifikasi (Lunas)
        return Colors.lightGreen; 
      case 'Selesai': // Status Final (Motor dikembalikan)
        return Colors.tealAccent;
      case 'Dibatalkan':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // Helper: Cek apakah user sudah memberi ulasan
  Future<bool> _hasReviewed(String bookingId) async {
    try {
      final response = await Supabase.instance.client
          .from('reviews')
          .select('id')
          .eq('booking_id', bookingId)
          .limit(1)
          .count();
      
      return response.count > 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        title: Text("Riwayat Booking", style: GoogleFonts.playfairDisplay(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: userId == null
          ? const Center(child: Text("Anda belum login.", style: TextStyle(color: Colors.white54)))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('bookings')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', userId)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Terjadi kesalahan: ${snapshot.error}", style: GoogleFonts.poppins(color: Colors.white)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 80, color: Colors.white24),
                        const Gap(16),
                        Text("Belum ada riwayat booking", style: GoogleFonts.poppins(color: Colors.white54)),
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
                    final status = booking['status'] ?? 'Proses';
                    final docId = booking['id']; 

                    return FutureBuilder<bool>(
                      future: _hasReviewed(docId),
                      builder: (context, reviewSnapshot) {
                        final hasReviewed = reviewSnapshot.data ?? false;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: status == 'Menunggu Pembayaran' 
                                  ? const Color(0xFFD4AF37).withOpacity(0.5) 
                                  : Colors.white.withOpacity(0.05)
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- HEADER: NAMA & STATUS ---
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      booking['motor_name'] ?? 'Motor',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: getStatusColor(status).withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      status,
                                      style: GoogleFonts.poppins(fontSize: 10, color: getStatusColor(status), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white10, height: 24),
                              
                              // --- DETAIL TANGGAL ---
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.white54),
                                  const Gap(8),
                                  Text(
                                    "${formatDate(booking['start_date'])} - ${formatDate(booking['end_date'])}",
                                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              
                              // --- HARGA & DURASI ---
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${booking['total_days']} Hari", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                                  Text(
                                    formatRupiah(booking['total_price'] ?? 0),
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37), fontSize: 16),
                                  ),
                                ],
                              ),

                              // --- TOMBOL AKSI ---
                              const Gap(16),
                              
                              // 1. Jika Menunggu Pembayaran -> Tombol Bayar
                              if (status == 'Menunggu Pembayaran')
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PaymentPage(
                                            bookingId: docId, 
                                            totalPrice: booking['total_price'],
                                            motorName: booking['motor_name'],
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD4AF37),
                                      foregroundColor: const Color(0xFF0F172A),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: Text("BAYAR SEKARANG", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  ),
                                )
                              
                              // 2. Jika Selesai -> Tombol Ulasan (Hanya jika belum review)
                              else if (status == 'Selesai')
                                SizedBox(
                                  width: double.infinity,
                                  child: hasReviewed 
                                    ? OutlinedButton.icon(
                                        onPressed: null, // Disable button
                                        icon: const Icon(Icons.check, size: 16, color: Colors.green),
                                        label: Text("Ulasan Terkirim", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green)),
                                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green)),
                                      )
                                    : OutlinedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => RatePage(
                                                bookingData: booking,
                                              ),
                                            ),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFFD4AF37)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: Text("BERI ULASAN", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37))),
                                      ),
                                ),
                            ],
                          ),
                        );
                      }
                    );
                  },
                );
              },
            ),
    );
  }
}