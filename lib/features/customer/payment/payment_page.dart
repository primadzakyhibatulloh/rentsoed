import 'dart:io';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class PaymentPage extends StatefulWidget {
  final String bookingId;
  final int totalPrice;
  final String motorName;

  const PaymentPage({
    super.key,
    required this.bookingId,
    required this.totalPrice,
    required this.motorName,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;
  XFile? _selectedImage;

  // DATA BANK
  final List<Map<String, String>> bankAccounts = [
    {
      'bank': 'BCA',
      'number': '123 456 7890',
      'name': 'Rentsoed',
      'icon': 'assets/images/bca.png',
    },
    {
      'bank': 'MANDIRI',
      'number': '098 765 432 100',
      'name': 'Rentsoed',
      'icon': 'assets/images/mandiri.png',
    },
    {
      'bank': 'DANA / OVO',
      'number': '0812 3456 7890',
      'name': 'Rentsoed',
      'icon': 'assets/images/ewalet.png',
    },
  ];

  String formatRupiah(int number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Nomor rekening berhasil disalin!"),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _submitPayment() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon upload bukti transfer dulu!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final fileName =
          '${widget.bookingId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (kIsWeb) {
        final bytes = await _selectedImage!.readAsBytes();
        await supabase.storage
            .from('payment_proofs')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
        await supabase.storage
            .from('payment_proofs')
            .upload(
              fileName,
              File(_selectedImage!.path),
              fileOptions: const FileOptions(upsert: true),
            );
      }

      final imageUrl = supabase.storage
          .from('payment_proofs')
          .getPublicUrl(fileName);

      await supabase
          .from('bookings')
          .update({
            'status': 'Menunggu Verifikasi',
            'payment_proof_url': imageUrl,
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.bookingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bukti terkirim! Admin akan memverifikasi."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal Upload: $e"),
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          "Pembayaran",
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- INFO TAGIHAN ---
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Total Tagihan",
                    style: GoogleFonts.poppins(color: Colors.white54),
                  ),
                  const Gap(8),
                  Text(
                    formatRupiah(widget.totalPrice),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD4AF37),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    "Untuk sewa: ${widget.motorName}",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Gap(24),

            // --- DAFTAR REKENING BANK ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Transfer ke salah satu:",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Gap(16),

                  // Loop menampilkan daftar bank
                  ...bankAccounts.map((account) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 40,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors
                                  .white, // Background putih agar logo jelas
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: (account['icon'] != null)
                                ? Image.asset(
                                    account['icon']!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.account_balance,
                                        color: Color(0xFFD4AF37),
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.account_balance,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                          ),
                          const Gap(12),

                          // Detail Rekening
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account['bank']!,
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFD4AF37),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  account['number']!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  "a.n ${account['name']}",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Tombol Copy
                          IconButton(
                            onPressed: () =>
                                _copyToClipboard(account['number']!),
                            icon: const Icon(
                              Icons.copy,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: "Salin No Rek",
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const Gap(30),

            // --- KOTAK UPLOAD FOTO ---
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedImage != null
                        ? const Color(0xFFD4AF37)
                        : Colors.white24,
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: kIsWeb
                            ? Image.network(
                                _selectedImage!.path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_selectedImage!.path),
                                fit: BoxFit.cover,
                              ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_upload_outlined,
                            size: 40,
                            color: Colors.white54,
                          ),
                          const Gap(10),
                          Text(
                            "Upload Bukti Transfer",
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                        ],
                      ),
              ),
            ),

            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  label: const Text(
                    "Ganti Foto",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),

            const Gap(40),

            // --- TOMBOL KIRIM ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          ),
                          const Gap(10),
                          Text(
                            "MENGUPLOAD...",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        "KIRIM BUKTI PEMBAYARAN",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
