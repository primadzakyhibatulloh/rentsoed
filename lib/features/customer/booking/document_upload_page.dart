import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gap/gap.dart';

import 'package:rentsoed_app/models/motor_model.dart';
import 'package:rentsoed_app/features/customer/booking/booking_page.dart';

class DocumentUploadPage extends StatefulWidget {
  final MotorModel motor;

  const DocumentUploadPage({super.key, required this.motor});

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  final userId = Supabase.instance.client.auth.currentUser?.id;

  // State untuk alur dokumen
  bool _isVerified = false;
  bool _isDocumentUploaded = false;
  bool _isLoading = true;
  String _documentType = 'KTP'; // Default pilihan dokumen
  XFile? _selectedImage;
  final TextEditingController _documentNumberController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkDocumentStatus();
  }

  // --- 1. CEK STATUS DOKUMEN PENGGUNA ---
  Future<void> _checkDocumentStatus() async {
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('documents')
          .select('is_verified')
          .eq('user_id', userId!)
          .maybeSingle();

      if (mounted) {
        setState(() {
          // Asumsi: Jika ada dokumen verified, proses upload dilewati
          _isVerified = response?['is_verified'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking document status: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. PILIH GAMBAR DOKUMEN ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1000,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
        _isDocumentUploaded = true;
      });
    }
  }

  // --- 3. SUBMIT DOKUMEN KE DB & STORAGE ---
  Future<void> _submitDocument() async {
    if (_selectedImage == null ||
        _documentNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi nomor dokumen dan foto!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final docNumber = _documentNumberController.text.trim();

    try {
      final supabase = Supabase.instance.client;
      final fileName =
          '${userId}_${_documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // A. Upload Foto ke Storage
      if (kIsWeb) {
        final bytes = await _selectedImage!.readAsBytes();
        await supabase.storage
            .from('user_documents')
            .uploadBinary(fileName, bytes);
      } else {
        await supabase.storage
            .from('user_documents')
            .upload(fileName, File(_selectedImage!.path));
      }

      // B. Ambil URL Publik
      final imageUrl = supabase.storage
          .from('user_documents')
          .getPublicUrl(fileName);

      // C. Simpan data dokumen ke tabel 'documents'
      await supabase.from('documents').insert({
        'user_id': userId,
        'document_type': _documentType,
        'document_number': docNumber,
        'image_url': imageUrl,
        'is_verified': false, // Admin harus memverifikasi nanti
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dokumen berhasil di-upload.")),
        );
        _navigateToBookingPage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal upload dokumen: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Navigasi ke halaman booking
  void _navigateToBookingPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => BookingPage(motor: widget.motor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    // Jika dokumen sudah diverifikasi, langsung pindah ke halaman booking
    if (_isVerified) {
      // ✅ Jika sudah verified, otomatis navigasi (tanpa show dialog)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToBookingPage();
      });
      // Tampilkan placeholder sebentar
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Text(
            "Dokumen terverifikasi. Memuat form booking...",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          "Verifikasi Identitas",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Langkah 1/2: Upload Dokumen",
              style: GoogleFonts.poppins(
                color: const Color(0xFFD4AF37),
                fontSize: 16,
              ),
            ),
            const Gap(8),
            Text(
              "Mohon upload KTP/SIM yang masih berlaku untuk melanjutkan pemesanan.",
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
            const Gap(30),

            // --- PILIH JENIS DOKUMEN & NOMOR ---
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _documentType,
                        dropdownColor: const Color(0xFF1E293B),
                        isExpanded: true,
                        style: GoogleFonts.poppins(color: Colors.white),
                        items: const ['KTP', 'SIM C', 'Paspor']
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _documentType = val!),
                      ),
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _documentNumberController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Nomor Dokumen",
                      labelStyle: GoogleFonts.poppins(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(30),

            // --- KOTAK UPLOAD FOTO ---
            Text(
              "Foto $_documentType",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isDocumentUploaded
                        ? const Color(0xFFD4AF37)
                        : Colors.white24,
                    width: 2,
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
                          Icon(
                            Icons.photo_camera,
                            size: 50,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const Gap(10),
                          Text(
                            "Tap untuk Upload Foto",
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                        ],
                      ),
              ),
            ),
            const Gap(40),

            // --- TOMBOL SUBMIT ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        "UPLOAD & LANJUT KE BOOKING",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
