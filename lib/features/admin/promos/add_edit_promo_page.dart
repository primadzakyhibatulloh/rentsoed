// file: add_edit_promo_page.dart (FINAL Disesuaikan)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart'; 

class AddEditPromoPage extends StatefulWidget {
  final Map<String, dynamic>? promo; 
  const AddEditPromoPage({super.key, this.promo});

  @override
  State<AddEditPromoPage> createState() => _AddEditPromoPageState();
}

class _AddEditPromoPageState extends State<AddEditPromoPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _discountValueCtrl = TextEditingController(); 
  // final _minTransactionCtrl = TextEditingController(); // Dihapus!
  
  DateTime? _expiryDate;
  String _discountType = 'percentage'; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.promo != null) {
      _codeCtrl.text = widget.promo!['code'];
      _descCtrl.text = widget.promo!['description'] ?? '';
      
      _discountValueCtrl.text = widget.promo!['discount_value'].toString(); 
      
      _discountType = widget.promo!['discount_type'] ?? 'percentage';
      
      // _minTransactionCtrl.text = (widget.promo!['min_transaction_amount'] as int?)?.toString() ?? '0'; // Dihapus!

      _expiryDate = DateTime.parse(widget.promo!['expiry_date']);
    } 
  }

  // Fungsi Pilih Tanggal Kadaluarsa (Tidak Berubah)
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              onPrimary: Color(0xFF0F172A),
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _savePromo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih tanggal kadaluarsa!")));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      
      // Data yang akan dikirim ke Supabase (min_transaction_amount sudah dihapus)
      final data = {
        'code': _codeCtrl.text.trim().toUpperCase(),
        'description': _descCtrl.text.trim(),
        'discount_type': _discountType, 
        'discount_value': int.parse(_discountValueCtrl.text), 
        // 'min_transaction_amount' dihapus dari data
        'expiry_date': _expiryDate!.toIso8601String(),
      };

      if (widget.promo == null) {
        await supabase.from('promos').insert(data);
      } else {
        await supabase.from('promos').update(data).eq('id', widget.promo!['id']);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Promo berhasil disimpan!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = "Terjadi kesalahan saat menyimpan promo.";
        if (e.toString().contains('promos_code_key')) {
           errorMessage = "Kode promo ini sudah digunakan. Mohon gunakan kode lain.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _descCtrl.dispose();
    _discountValueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.promo != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(isEditing ? "Edit Promo" : "Buat Promo Baru", style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Input Kode Promo
              TextFormField(
                controller: _codeCtrl,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                validator: (val) => val!.isEmpty ? "Kode wajib diisi" : null,
                decoration: InputDecoration(
                  labelText: "KODE PROMO",
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.confirmation_number, color: Color(0xFFD4AF37)),
                ),
              ),
              const Gap(20),
              
              // 2. Pilih Tipe Diskon
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 16),
                      child: Text("Tipe Diskon", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: RadioListTile<String>(
                          title: const Text('Persentase (%)', style: TextStyle(color: Colors.white)),
                          value: 'percentage',
                          groupValue: _discountType,
                          onChanged: (val) => setState(() => _discountType = val!),
                          activeColor: const Color(0xFFD4AF37),
                          contentPadding: EdgeInsets.zero,
                        )),
                        Expanded(child: RadioListTile<String>(
                          title: const Text('Nominal (Rp)', style: TextStyle(color: Colors.white)),
                          value: 'fixed',
                          groupValue: _discountType,
                          onChanged: (val) => setState(() => _discountType = val!),
                          activeColor: const Color(0xFFD4AF37),
                          contentPadding: EdgeInsets.zero,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(20),

              // 3. Input Nilai Diskon
              TextFormField(
                controller: _discountValueCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Nilai diskon wajib diisi";
                  final n = int.tryParse(val);
                  if (n == null || n <= 0) return "Masukkan angka positif";
                  if (_discountType == 'percentage' && n > 100) return "Maksimum 100% untuk persentase";
                  return null;
                },
                decoration: InputDecoration(
                  labelText: _discountType == 'percentage' ? "Nilai Diskon (1-100)" : "Nilai Diskon Nominal (Rp)",
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: Icon(_discountType == 'percentage' ? Icons.percent : Icons.money, color: const Color(0xFFD4AF37)),
                ),
              ),
              const Gap(20),

              // 4. Pilih Tanggal Kadaluarsa
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _expiryDate == null ? Colors.transparent : const Color(0xFFD4AF37)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFFD4AF37)),
                      const Gap(16),
                      Text(
                        _expiryDate == null 
                          ? "Pilih Tanggal Kadaluarsa" 
                          : DateFormat('dd MMMM yyyy').format(_expiryDate!),
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(20),

              // 5. Input Deskripsi
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Deskripsi Promo (Opsional)",
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.description, color: Color(0xFFD4AF37)),
                ),
              ),
              const Gap(40),

              // 6. Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePromo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(isEditing ? "PERBARUI PROMO" : "SIMPAN PROMO", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}