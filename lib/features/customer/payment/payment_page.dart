import 'dart:io';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
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
  XFile? _selectedImage; // Gunakan XFile agar support Web & Mobile

  // Helper Format Rupiah
  String formatRupiah(int number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  // --- 1. AMBIL FOTO (Kompresi Otomatis) ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Ambil foto dari galeri dengan kompresi agar file kecil (cepat upload)
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Kualitas 50%
      maxWidth: 800,    // Lebar maksimal 800px
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  // --- 2. UPLOAD KE SUPABASE STORAGE ---
  Future<void> _submitPayment() async {
    // Validasi: Harus ada foto
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon upload bukti transfer dulu!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      // Gunakan timestamp untuk nama file agar unik dan menghindari cache issue
      final fileName = '${widget.bookingId}_${DateTime.now().millisecondsSinceEpoch}.jpg'; 

      // A. Upload Foto ke Bucket 'payment_proofs'
      // Supabase butuh 'Bytes' untuk Web dan 'File' untuk Mobile
      if (kIsWeb) {
        final bytes = await _selectedImage!.readAsBytes();
        await supabase.storage.from('payment_proofs').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(upsert: true), // Timpa jika ada
        );
      } else {
        await supabase.storage.from('payment_proofs').upload(
          fileName,
          File(_selectedImage!.path),
          fileOptions: const FileOptions(upsert: true),
        );
      }

      // B. Ambil Link Foto (Public URL)
      final imageUrl = supabase.storage.from('payment_proofs').getPublicUrl(fileName);

      // C. Update Data di Tabel 'bookings'
      await supabase.from('bookings').update({
        'status': 'Menunggu Verifikasi', // Status berubah agar Admin tahu ada pembayaran masuk
        'payment_proof_url': imageUrl, 
        'paid_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.bookingId); // Cari berdasarkan ID Booking

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bukti terkirim! Admin akan memverifikasi."), 
            backgroundColor: Colors.green
          ),
        );
        // Kembali ke halaman sebelumnya (Biasanya Riwayat)
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal Upload: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Background Navy
      appBar: AppBar(
        title: Text("Upload Bukti", style: GoogleFonts.playfairDisplay(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
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
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text("Total Tagihan", style: GoogleFonts.poppins(color: Colors.white54)),
                  const Gap(8),
                  Text(
                    formatRupiah(widget.totalPrice),
                    style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37)),
                  ),
                  const Gap(8),
                  Text("Untuk sewa: ${widget.motorName}", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Gap(30),

            // --- KOTAK UPLOAD FOTO ---
            GestureDetector(
              onTap: _pickImage, // Klik untuk ambil foto
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedImage != null ? const Color(0xFFD4AF37) : Colors.white24, 
                    style: BorderStyle.solid,
                    width: 1.5
                  ),
                ),
                // Tampilkan gambar (Logic Web vs Mobile)
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: kIsWeb
                            ? Image.network(_selectedImage!.path, fit: BoxFit.cover) // Web pakai network blob
                            : Image.file(File(_selectedImage!.path), fit: BoxFit.cover), // HP pakai File path
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined, size: 50, color: Colors.white54),
                          const Gap(10),
                          Text("Tap untuk Upload Bukti", style: GoogleFonts.poppins(color: Colors.white70)),
                          Text("(Transfer Bank / E-Wallet)", style: GoogleFonts.poppins(color: Colors.white24, fontSize: 12)),
                        ],
                      ),
              ),
            ),
            
            // Tombol Ganti Foto (Muncul kalau sudah pilih foto)
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton.icon(
                  onPressed: _pickImage, 
                  icon: const Icon(Icons.refresh, color: Colors.white70), 
                  label: const Text("Ganti Foto", style: TextStyle(color: Colors.white70))
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
                          const Gap(10),
                          Text("MENGUPLOAD...", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      )
                    : Text("KIRIM BUKTI PEMBAYARAN", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}