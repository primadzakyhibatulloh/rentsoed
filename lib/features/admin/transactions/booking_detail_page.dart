import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rentsoed_app/services/notification_service.dart';

class BookingDetailPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  const BookingDetailPage({super.key, required this.bookingData});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  late Future<Map<String, dynamic>> _futureBookingDetails;
  late Future<Map<String, dynamic>?> _futureDocument;

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _futureBookingDetails = _fetchDetails();
    _futureDocument = _fetchDocuments(widget.bookingData['user_id']);
  }

  // --- FUNGSI 1: MENGAMBIL DETAIL BOOKING, INVOICE, PROFIL (Tanpa Dokumen) ---
  Future<Map<String, dynamic>> _fetchDetails() async {
    final supabase = Supabase.instance.client;
    final bookingId = widget.bookingData['id'];

    // FIX QUERY: Hanya JOIN relasi yang pasti (profiles, motors, invoices)
    final response = await supabase
        .from('bookings')
        .select('''
          *, 
          profiles:user_id(email, full_name), 
          motors!inner(nama_motor, foto_motor), 
          invoices(*)
        ''')
        .eq('id', bookingId)
        .single();

    return response;
  }

  // --- FUNGSI 2: MENGAMBIL DOKUMEN SECARA TERPISAH ---
  Future<Map<String, dynamic>?> _fetchDocuments(String customerUserId) async {
    final supabase = Supabase.instance.client;

    // Ambil dokumen terbaru milik user ini
    final response = await supabase
        .from('documents')
        .select('document_type, document_number, image_url, is_verified')
        .eq('user_id', customerUserId)
        .order('upload_date', ascending: false) // Ambil yang terbaru
        .limit(1)
        .maybeSingle();

    return response;
  }

  // --- FUNGSI UPDATE STATUS DENGAN NOTIFIKASI POP-UP ---
  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    final supabase = Supabase.instance.client;
    final bookingId = widget.bookingData['id'];
    final motorId = widget.bookingData['motor_id'];
    final adminId = supabase.auth.currentUser?.id;

    try {
      final isPaid = newStatus == 'Dibayar';
      final isFinished = newStatus == 'Selesai';
      final isCanceled = newStatus == 'Dibatalkan';

      final updateData = {
        'status': newStatus,
        'paid_at': isPaid
            ? DateTime.now().toIso8601String()
            : widget.bookingData['paid_at'],
      };

      // 1. Update Booking
      await supabase.from('bookings').update(updateData).eq('id', bookingId);

      // 2. Update Invoice
      await supabase
          .from('invoices')
          .update({'is_paid': isPaid || isFinished, 'admin_id': adminId})
          .eq('booking_id', bookingId);

      // 3. Update Motor Availability
      if (isPaid) {
        await supabase
            .from('motors')
            .update({'is_available': false})
            .eq('id', motorId);
      } else if (isFinished || isCanceled) {
        await supabase
            .from('motors')
            .update({'is_available': true})
            .eq('id', motorId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status berhasil diubah menjadi '$newStatus'."),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _futureBookingDetails = _fetchDetails();
          _futureDocument = _fetchDocuments(widget.bookingData['user_id']);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal update status: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // --- HELPERS ---
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Dibayar':
        return Colors.green;
      case 'Selesai':
        return Colors.teal;
      case 'Menunggu Verifikasi':
        return Colors.blueAccent;
      case 'Menunggu Pembayaran':
        return Colors.orangeAccent;
      case 'Dibatalkan':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatRupiah(int? number) {
    if (number == null) return "Rp 0";
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          const Text(": ", style: TextStyle(color: Colors.white54)),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: valueColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            errorWidget: (context, url, error) =>
                const Icon(Icons.error, color: Colors.white, size: 50),
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          "Detail Booking",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureBookingDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                "Gagal memuat detail: ${snapshot.error}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final fullBooking = snapshot.data!;
          final motor = fullBooking['motors'];
          final userProfile = fullBooking['profiles'];

          final invoice = fullBooking['invoices'];

          final status = fullBooking['status'] as String? ?? 'Unknown';
          final paymentProofUrl = fullBooking['payment_proof_url'] as String?;

          // Data Invoice yang sudah di-handle null
          final subtotal = invoice?['subtotal'] as int? ?? 0;
          final insuranceFee = invoice?['insurance_fee'] as int? ?? 0;
          final discountUsed = invoice?['discount_used'] as int? ?? 0;
          final finalTotal = invoice?['final_total'] as int? ?? 0;

          // FIX NAMA LENGKAP: Ambil full_name, fallback ke email jika null
          final userFullName =
              userProfile?['full_name'] ?? userProfile?['email'] ?? 'N/A';

          return FutureBuilder<Map<String, dynamic>?>(
            future: _futureDocument,
            builder: (context, docSnapshot) {
              final document = docSnapshot.data;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- STATUS CHIP ---
                    Chip(
                      label: Text(
                        status,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: _getStatusColor(status),
                    ),
                    const Gap(20),

                    // --- DETAIL MOTOR ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: motor?['foto_motor'] != null
                                ? CachedNetworkImage(
                                    imageUrl: motor!['foto_motor'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.motorcycle,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                          ),
                          const Gap(16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                motor?['nama_motor'] ?? 'Motor Dihapus',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "ID Booking: ${fullBooking['id'].toString().substring(0, 8)}",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Gap(30),

                    // --- DETAIL PELANGGAN & SEWA ---
                    Text(
                      "Detail Pelanggan",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
                    _buildInfoRow(
                      "Nama Lengkap",
                      userFullName,
                    ), // Menggunakan variabel yang sudah disiapkan
                    _buildInfoRow("Email", userProfile?['email'] ?? 'N/A'),
                    const Gap(20),

                    // --- DETAIL DOKUMEN (KTP/SIM) ---
                    Text(
                      "Dokumen Identitas",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
                    if (document != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            "Tipe Dokumen",
                            document['document_type'] ?? 'N/A',
                          ),
                          _buildInfoRow(
                            "Nomor Dokumen",
                            document['document_number'] ?? 'N/A',
                          ),
                          // ✅ FIX: Hapus Status Verifikasi Dokumen
                          // OLD: _buildInfoRow("Status Verifikasi", (document['is_verified'] == true ? 'Terverifikasi' : 'Belum Diverifikasi'), valueColor: document['is_verified'] == true ? Colors.greenAccent : Colors.redAccent),
                          const Gap(10),
                          // Tampilan Gambar Dokumen
                          if (document['image_url'] != null)
                            GestureDetector(
                              onTap: () => _showImageDialog(
                                context,
                                document['image_url'],
                              ),
                              child: Container(
                                height: 150,
                                width: 250,
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: document['image_url'],
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      const Center(
                                        child: Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                        ],
                      )
                    else
                      Text(
                        "Customer belum mengunggah dokumen identitas.",
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),

                    const Gap(30),

                    // --- DETAIL PERIODE SEWA ---
                    Text(
                      "Detail Sewa",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
                    _buildInfoRow(
                      "Durasi",
                      "${fullBooking['total_days'] ?? 0} hari",
                    ),
                    _buildInfoRow(
                      "Periode",
                      "${DateFormat('dd MMM').format(DateTime.parse(fullBooking['start_date']))} - ${DateFormat('dd MMM').format(DateTime.parse(fullBooking['end_date']))}",
                    ),
                    const Gap(30),

                    // --- RINGKASAN PEMBAYARAN ---
                    Text(
                      "Ringkasan Pembayaran",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
                    _buildInfoRow("Subtotal Motor", _formatRupiah(subtotal)),
                    _buildInfoRow(
                      "Biaya Asuransi",
                      _formatRupiah(insuranceFee),
                    ),
                    _buildInfoRow(
                      "Diskon Promo",
                      "- ${_formatRupiah(discountUsed)}",
                      valueColor: Colors.redAccent,
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    _buildInfoRow(
                      "TOTAL FINAL",
                      _formatRupiah(finalTotal),
                      valueColor: const Color(0xFFD4AF37),
                    ),
                    const Gap(30),

                    // --- BUKTI PEMBAYARAN & ACTION VERIFIKASI ---
                    if (paymentProofUrl != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bukti Transfer Pelanggan",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(10),
                          // Tampilan Bukti Pembayaran
                          GestureDetector(
                            onTap: () =>
                                _showImageDialog(context, paymentProofUrl),
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: paymentProofUrl,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    const Center(
                                      child: Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      ),
                                    ),
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFD4AF37),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Gap(20),

                          // Tombol Aksi HANYA JIKA bukti sudah ada
                          if (status == 'Menunggu Verifikasi')
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isUpdating
                                        ? null
                                        : () => _showStatusConfirmation(
                                            context,
                                            'Dibayar',
                                          ),
                                    icon: _isUpdating
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.black,
                                          ),
                                    label: Text(
                                      "VERIFIKASI PEMBAYARAN",
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.greenAccent,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                    ),
                                  ),
                                ),
                                const Gap(10),
                                // Tombol Batalkan saat Verifikasi
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isUpdating
                                        ? null
                                        : () => _showStatusConfirmation(
                                            context,
                                            'Dibatalkan',
                                          ),
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.redAccent,
                                    ),
                                    label: Text(
                                      "TOLAK / BATALKAN BOOKING",
                                      style: GoogleFonts.poppins(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          // Tombol Selesai HANYA JIKA status = 'Dibayar'
                          else if (status == 'Dibayar')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isUpdating
                                    ? null
                                    : () => _showStatusConfirmation(
                                        context,
                                        'Selesai',
                                      ),
                                icon: const Icon(
                                  Icons.done_all,
                                  color: Colors.black,
                                ),
                                label: Text(
                                  "SET BOOKING SELESAI (Motor Kembali)",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.tealAccent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            )
                          else
                            // Status Dibatalakan/Selesai Permanen
                            Text(
                              "Status transaksi final: $status",
                              style: GoogleFonts.poppins(color: Colors.white38),
                            ),
                        ],
                      )
                    else
                      // Jika belum ada bukti pembayaran (Status: Menunggu Pembayaran)
                      Text(
                        "Pelanggan belum mengunggah bukti pembayaran.",
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),

                    const Gap(30),

                    // --- TOMBOL BATALKAN UNTUK STATUS 'Menunggu Pembayaran' (Tanpa Bukti) ---
                    // Tombol ini akan muncul jika status 'Menunggu Pembayaran' DAN paymentProofUrl masih null.
                    if (status == 'Menunggu Pembayaran' &&
                        paymentProofUrl == null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isUpdating
                              ? null
                              : () => _showStatusConfirmation(
                                  context,
                                  'Dibatalkan',
                                ),
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.redAccent,
                          ),
                          label: Text(
                            "TOLAK / BATALKAN BOOKING",
                            style: GoogleFonts.poppins(color: Colors.redAccent),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    const Gap(30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Dialog konfirmasi status
  Future<void> _showStatusConfirmation(
    BuildContext context,
    String status,
  ) async {
    final title = status == 'Dibayar'
        ? "Verifikasi Pembayaran?"
        : status == 'Selesai'
        ? "Selesaikan Booking?"
        : "Batalkan Booking?";
    final message = status == 'Dibayar'
        ? "Ini akan mengkonfirmasi pembayaran dan mengubah status menjadi 'Dibayar'."
        : status == 'Selesai'
        ? "Konfirmasi motor sudah dikembalikan dan transaksi selesai."
        : "Booking akan dibatalkan. Tindakan ini tidak bisa diurungkan.";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("TIDAK"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(color: _getStatusColor(status)),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _updateStatus(status);
    }
  }
}
