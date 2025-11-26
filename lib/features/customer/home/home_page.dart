import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart'; 

import 'package:rentsoed_app/features/customer/detail/detail_page.dart';
import 'package:rentsoed_app/models/motor_model.dart';
import 'package:rentsoed_app/models/category_model.dart'; 
import 'package:rentsoed_app/widgets/custom_drawer.dart'; 
import 'package:rentsoed_app/features/customer/inbox/inbox_page.dart'; // Import Inbox Page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Simpan hasil fetch kategori dan motor
  late Future<List<CategoryModel>> _categoriesFuture;
  late Future<List<MotorModel>> _motorsFuture;
  
  String _selectedCategoryId = 'all'; 

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchCategories();
    _motorsFuture = _fetchMotors();
  }

  // --- FUNGSI 1: AMBIL DATA KATEGORI DARI SUPABASE ---
  Future<List<CategoryModel>> _fetchCategories() async {
    final supabase = Supabase.instance.client;
    
    final response = await supabase
        .from('categories')
        .select('*')
        .order('nama_kategori', ascending: true);
    
    List<CategoryModel> categories = [];
    
    for (var json in response) {
      try {
        categories.add(CategoryModel.fromJson(json as Map<String, dynamic>));
      } catch (e) {
        debugPrint('Skipping category row due to parsing error: $e');
      }
    }
    
    // Tambahkan kategori 'All' secara manual di awal untuk filter
    categories.insert(0, CategoryModel(id: 'all', namaKategori: 'All'));
    
    return categories;
  }

  // --- FUNGSI 2: AMBIL DATA MOTOR DARI SUPABASE ---
  Future<List<MotorModel>> _fetchMotors() async {
    final supabase = Supabase.instance.client;
    
    var query = supabase
        .from('motors')
        .select('*')
        .eq('is_available', true);

    if (_selectedCategoryId != 'all') {
      query = query.eq('category_id', _selectedCategoryId);
    }

    final response = await query.order('nama_motor', ascending: true);

    final List<MotorModel> motors = response
        .map((json) => MotorModel.fromJson(json as Map<String, dynamic>))
        .toList();

    return motors;
  }

  // --- HELPER DAN UTILITY ---

  String formatRupiah(int number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  // Fungsi untuk mendapatkan Nama Kategori dari ID (Optimized)
  String _getCategoryNameById(String categoryId, List<CategoryModel> categories) {
    try {
      final category = categories.firstWhere(
        (cat) => cat.id == categoryId, 
        orElse: () => CategoryModel(id: '', namaKategori: 'Lain-lain')
      );
      return category.namaKategori.isEmpty ? 'Lain-lain' : category.namaKategori;

    } catch (e) {
      return 'Unlisted';
    }
  }

  // Fungsi untuk refresh data motor saat filter diganti
  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _motorsFuture = _fetchMotors(); 
    });
  }
  
  // Fungsi untuk navigasi ke Inbox Page
  void _navigateToInbox() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const InboxPage())
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? 'Pelanggan';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      
      drawer: const CustomDrawer(),
      
      appBar: AppBar(
        automaticallyImplyLeading: true, 
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        
        title: Text(
          "RENTSOED",
          style: GoogleFonts.playfairDisplay(
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            color: const Color(0xFFD4AF37),
            letterSpacing: 1.5,
          ),
        ),
        
        actions: [
          // Tombol Notifikasi (Lonceng)
          IconButton(
            onPressed: _navigateToInbox, 
            icon: const Icon(Icons.notifications_none, color: Colors.white54)
          ),
          const Gap(10),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 0),
        child: FutureBuilder<List<CategoryModel>>( 
          future: _categoriesFuture,
          builder: (context, snapshotCategories) { 
            if (snapshotCategories.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
            }
            if (snapshotCategories.hasError || !snapshotCategories.hasData) {
              return Center(child: Text("Gagal memuat kategori: ${snapshotCategories.error.toString()}", style: GoogleFonts.poppins(color: Colors.red)));
            }
            
            final categories = snapshotCategories.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- WELCOME HEADER ---
                Text("Welcome Back, ", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16)),
                Text(userName, style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const Gap(20),


                // --- SEARCH BAR MEWAH ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08), 
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      icon: Icon(Icons.search, color: Color(0xFFD4AF37)),
                      hintText: "Cari motor impian Anda...",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms),
                const Gap(20),

                // --- KATEGORI CHIPS ---
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      final isSelected = _selectedCategoryId == category.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => _onCategorySelected(category.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              category.namaKategori, 
                              style: GoogleFonts.poppins(
                                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ).animate().slideX(duration: 600.ms, begin: 0.2),


                const Gap(20),

                // --- LIST GRID MOTOR (FutureBuilder Motor) ---
                Expanded(
                  child: FutureBuilder<List<MotorModel>>(
                    future: _motorsFuture,
                    builder: (context, snapshotMotor) {
                      if (snapshotMotor.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                      }
                      if (snapshotMotor.hasError) {
                        return Center(child: Text("Gagal memuat motor: ${snapshotMotor.error}", style: const TextStyle(color: Colors.red)));
                      }
                      
                      final motors = snapshotMotor.data!;
                      
                      if (motors.isEmpty) {
                        return Center(
                          child: Text("Motor tidak ditemukan untuk kategori ini.", style: GoogleFonts.poppins(color: Colors.white54)),
                        );
                      }

                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, 
                          childAspectRatio: 0.65, 
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: motors.length,
                        itemBuilder: (context, index) {
                          final motor = motors[index];
                          return _buildMotorCard(motor, index, categories); 
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // WIDGET KARTU MOTOR BARU (Desain Lebih Mewah)
  Widget _buildMotorCard(MotorModel motor, int index, List<CategoryModel> categories) {
    final categoryName = _getCategoryNameById(motor.categoryId, categories);
    final safeImageUrl = motor.fotoMotor ?? ''; 

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(motor: motor),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Card Color
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)), 
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. GAMBAR (Paling Menonjol)
            Expanded(
              flex: 3,
              child: Hero( 
                tag: motor.namaMotor, 
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: safeImageUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: safeImageUrl,
                        fit: BoxFit.contain, 
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2)),
                        errorWidget: (context, url, error) => const Center(child: Icon(Icons.motorcycle, color: Colors.white24, size: 50)),
                      )
                    : const Center(child: Icon(Icons.motorcycle, size: 70, color: Colors.white24)),
                ),
              ),
            ),
            
            const Gap(12),
            
            // 2. TEKS INFO
            Text(
              categoryName.toUpperCase(), 
              style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white54),
            ),
            const Gap(4),

            // Nama Motor
            Text(
              motor.namaMotor, 
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Gap(10),
            
            // Harga
            Row(
              children: [
                Text(
                  formatRupiah(motor.harga), 
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37)),
                ),
                Text(
                  " /hari", 
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.2, end: 0),
    );
  }
}