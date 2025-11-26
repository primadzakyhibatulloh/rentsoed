import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gap/gap.dart';

class AddEditMotorPage extends StatefulWidget {
  final Map<String, dynamic>? motor;
  const AddEditMotorPage({super.key, this.motor});

  @override
  State<AddEditMotorPage> createState() => _AddEditMotorPageState();
}

class _AddEditMotorPageState extends State<AddEditMotorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _ccCtrl = TextEditingController();
  final _yearCtrl = TextEditingController(); // Kontroler BARU: Tahun Keluaran
  final _colorCtrl = TextEditingController(); // Kontroler BARU: Warna Motor
  final _descCtrl = TextEditingController();
  
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  XFile? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    
    // 💡 Inisialisasi data untuk mode EDIT
    if (widget.motor != null) {
      // Menggunakan nama kolom BARU dari skema SQL:
      _nameCtrl.text = widget.motor!['nama_motor'] ?? '';
      _priceCtrl.text = (widget.motor!['harga'] as int?)?.toString() ?? ''; // 'price' diganti 'harga'
      _ccCtrl.text = (widget.motor!['cc'] as int?)?.toString() ?? '';
      _yearCtrl.text = (widget.motor!['tahun_keluaran'] as int?)?.toString() ?? ''; // Kolom baru
      _colorCtrl.text = widget.motor!['warna_motor'] ?? ''; // Kolom baru
      _descCtrl.text = widget.motor!['deskripsi'] ?? ''; // 'description' diganti 'deskripsi'
      
      _selectedCategoryId = widget.motor!['category_id'];
      _existingImageUrl = widget.motor!['foto_motor']; // 'image_url' diganti 'foto_motor'
    }
  }

  Future<void> _fetchCategories() async {
    // 💡 Menggunakan nama kolom BARU dari tabel categories: 'nama_kategori'
    final response = await Supabase.instance.client.from('categories').select('id, nama_kategori');
    setState(() {
      _categories = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _imageFile = picked);
  }

  Future<void> _saveMotor() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kategori wajib dipilih!")));
      return;
    }
    
    setState(() => _isLoading = true);
    
    String imageUrl = _existingImageUrl ?? '';

    try {
      final supabase = Supabase.instance.client;
      
      // 1. Upload Gambar Baru jika ada
      if (_imageFile != null) {
        final fileName = 'motor_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // Logika upload Supabase Storage
        if (kIsWeb) {
            await supabase.storage.from('motor_images').uploadBinary(fileName, await _imageFile!.readAsBytes());
        } else {
            await supabase.storage.from('motor_images').upload(fileName, File(_imageFile!.path));
        }
        
        imageUrl = supabase.storage.from('motor_images').getPublicUrl(fileName);
        
        // Opsional: Hapus gambar lama jika ada dan sedang dalam mode edit
        if (widget.motor != null && _existingImageUrl != null) {
             // Logic untuk menghapus file lama dari storage (perlu path file/bucket name)
             // ...
        }
      }

      // 2. Siapkan Data dengan Nama Kolom BARU
      final data = {
        'nama_motor': _nameCtrl.text.trim(),
        'category_id': _selectedCategoryId,
        'harga': int.tryParse(_priceCtrl.text) ?? 0,
        'cc': int.tryParse(_ccCtrl.text) ?? 0,
        'tahun_keluaran': int.tryParse(_yearCtrl.text) ?? DateTime.now().year, // Kolom baru
        'warna_motor': _colorCtrl.text.trim(), // Kolom baru
        'deskripsi': _descCtrl.text.trim(),
        'foto_motor': imageUrl, // Nama kolom baru
        // is_available dan created_at diurus oleh database default
      };

      // 3. Insert atau Update
      if (widget.motor == null) {
        await supabase.from('motors').insert(data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Motor berhasil ditambahkan!")));
      } else {
        await supabase.from('motors').update(data).eq('id', widget.motor!['id']);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Motor berhasil diperbarui!")));
      }
      
      if (mounted) Navigator.pop(context);
      
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saat menyimpan: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _ccCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.motor != null;
    final title = isEditing ? "Edit Motor" : "Tambah Motor Baru";

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- UPLOAD FOTO MOTOR ---
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200, width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24)),
                  child: _imageFile != null
                      ? (kIsWeb 
                          ? Image.network(_imageFile!.path, fit: BoxFit.cover) 
                          : Image.file(File(_imageFile!.path), fit: BoxFit.cover))
                      : (_existingImageUrl != null 
                          ? Image.network(_existingImageUrl!, fit: BoxFit.cover) 
                          : const Icon(Icons.add_a_photo, color: Colors.white54, size: 50)),
                ),
              ),
              const Gap(20),
              
              // --- FIELD NAMA MOTOR ---
              TextFormField(
                  controller: _nameCtrl, 
                  style: const TextStyle(color: Colors.white), 
                  validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                  decoration: const InputDecoration(labelText: "Nama Motor", filled: true, fillColor: Colors.white10)),
              const Gap(16),
              
              // --- FIELD HARGA ---
              TextFormField(
                  controller: _priceCtrl, 
                  keyboardType: TextInputType.number, 
                  style: const TextStyle(color: Colors.white), 
                  validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                  decoration: const InputDecoration(labelText: "Harga Sewa Harian (Rp)", filled: true, fillColor: Colors.white10)),
              const Gap(16),

              // --- FIELD CC ---
              TextFormField(
                  controller: _ccCtrl, 
                  keyboardType: TextInputType.number, 
                  style: const TextStyle(color: Colors.white), 
                  validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                  decoration: const InputDecoration(labelText: "CC Mesin", filled: true, fillColor: Colors.white10)),
              const Gap(16),
              
              // --- FIELD TAHUN KELUARAN ---
              TextFormField(
                  controller: _yearCtrl, 
                  keyboardType: TextInputType.number, 
                  style: const TextStyle(color: Colors.white), 
                  validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                  decoration: const InputDecoration(labelText: "Tahun Keluaran", filled: true, fillColor: Colors.white10)),
              const Gap(16),

              // --- FIELD WARNA MOTOR ---
              TextFormField(
                  controller: _colorCtrl, 
                  style: const TextStyle(color: Colors.white), 
                  decoration: const InputDecoration(labelText: "Warna Motor", filled: true, fillColor: Colors.white10)),
              const Gap(16),

              // --- DROPDOWN KATEGORI ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    validator: (val) => val == null ? "Kategori wajib dipilih" : null,
                    hint: const Text("Pilih Kategori", style: TextStyle(color: Colors.white54)),
                    dropdownColor: const Color(0xFF1E293B),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: _categories.map((cat) => DropdownMenuItem<String>(
                      value: cat['id'].toString(), 
                      // 💡 Menggunakan 'nama_kategori'
                      child: Text(cat['nama_kategori'] as String? ?? 'N/A')
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  ),
                ),
              ),
              const Gap(16),
              
              // --- FIELD DESKRIPSI ---
              TextFormField(
                  controller: _descCtrl, 
                  maxLines: 3, 
                  style: const TextStyle(color: Colors.white), 
                  decoration: const InputDecoration(labelText: "Deskripsi", filled: true, fillColor: Colors.white10)),
              const Gap(30),
              
              // --- TOMBOL SIMPAN ---
              SizedBox(
                width: double.infinity, 
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent, 
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: _isLoading ? null : _saveMotor, 
                    child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) 
                        : Text(isEditing ? "PERBARUI MOTOR" : "TAMBAH MOTOR", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                )),
            ],
          ),
        ),
      ),
    );
  }
}