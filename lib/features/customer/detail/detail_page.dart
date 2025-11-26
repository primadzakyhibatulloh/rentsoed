import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart'; 
import 'package:intl/intl.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:rentsoed_app/models/motor_model.dart';
import 'package:rentsoed_app/features/customer/booking/document_upload_page.dart';

class DetailPage extends StatefulWidget {
  final MotorModel motor; 

  const DetailPage({super.key, required this.motor});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  final userId = Supabase.instance.client.auth.currentUser?.id;
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    if (userId != null) {
      _checkIsFavorite();
    } else {
      _isLoadingFavorite = false;
    }
  }

  Future<void> _checkIsFavorite() async {
    if (userId == null) {
      if (mounted) setState(() => _isLoadingFavorite = false);
      return;
    }
    
    try {
      final response = await Supabase.instance.client
          .from('wishlists')
          .select('motor_id')
          .eq('user_id', userId!)
          .eq('motor_id', widget.motor.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isFavorite = response != null;
        });
      }
    } catch (e) {
      debugPrint("Error checking wishlist: $e");
    } finally {
      if (mounted) setState(() => _isLoadingFavorite = false); 
    }
  }

  Future<void> _toggleWishlist() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda harus login untuk menambahkan favorit.")),
      );
      return;
    }

    setState(() => _isLoadingFavorite = true);

    try {
      if (_isFavorite) {
        await Supabase.instance.client
            .from('wishlists')
            .delete()
            .eq('user_id', userId!)
            .eq('motor_id', widget.motor.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dihapus dari favorit.")),
        );
      } else {
        await Supabase.instance.client.from('wishlists').insert({
          'user_id': userId,
          'motor_id': widget.motor.id,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ditambahkan ke favorit!")),
        );
      }
      
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  String _formatRupiah(int? price) {
    if (price == null) return "Rp 0";
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(price);
  }

  Future<String> _getCategoryName(String categoryId) async {
    if (categoryId.isEmpty) return 'UNLISTED';
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('nama_kategori')
          .eq('id', categoryId)
          .single();
      return response['nama_kategori'].toString().toUpperCase();
    } catch (e) {
      return 'Kategori ID: $categoryId'; 
    }
  }

  // Simulasi multiple images
  List<String> get _motorImages {
    final mainImage = widget.motor.fotoMotor ?? '';
    return [
      mainImage,
      mainImage,
      mainImage,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Menggunakan data langsung dari MotorModel sesuai kolom tabel
    final safeImageUrl = widget.motor.fotoMotor ?? '';
    final safeDescription = widget.motor.deskripsi ?? 'Deskripsi belum tersedia untuk motor ini.';
    final safeCC = widget.motor.cc?.toString() ?? 'N/A';
    final safePrice = widget.motor.harga; // Langsung dari harga, sudah required
    final safeYear = widget.motor.tahunKeluaran?.toString() ?? 'N/A';
    final safeColor = widget.motor.warnaMotor ?? 'N/A';
    final isAvailable = widget.motor.isAvailable ?? true;
    
    final favoriteIcon = _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded;
    final favoriteColor = _isFavorite ? Colors.redAccent : Colors.white;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Luxury Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0F1C),
                    Color(0xFF0F172A),
                    Color(0xFF1A2337),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Main Content Structure
          Column(
            children: [
              // Header Section dengan image gallery
              Expanded(
                flex: 45,
                child: Stack(
                  children: [
                    // Image Gallery
                    Positioned.fill(
                      child: PageView.builder(
                        controller: _imageController,
                        itemCount: _motorImages.length,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return Hero(
                            tag: '${widget.motor.namaMotor}_$index',
                            child: _motorImages[index].startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: _motorImages[index],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: const Color(0xFF1E293B),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: const Color(0xFF1E293B),
                                      child: Center(
                                        child: Icon(
                                          Icons.motorcycle_rounded,
                                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                                          size: 120,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFF1E293B),
                                    child: Center(
                                      child: Icon(
                                        Icons.motorcycle_rounded,
                                        color: const Color(0xFFD4AF37).withOpacity(0.5),
                                        size: 120,
                                      ),
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),

                    // Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                              const Color(0xFF1E293B).withOpacity(0.9),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // App Bar
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Back Button
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                  padding: EdgeInsets.zero,
                                ),
                              ).animate().fadeIn(delay: 200.ms),

                              // Favorite Button
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: _isLoadingFavorite && userId != null
                                    ? Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        icon: Icon(favoriteIcon, color: favoriteColor, size: 22),
                                        onPressed: _toggleWishlist,
                                        padding: EdgeInsets.zero,
                                      ),
                              ).animate().fadeIn(delay: 300.ms),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Image Indicator
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_motorImages.length, (index) {
                          return Container(
                            width: _currentImageIndex == index ? 28 : 8,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index 
                                  ? const Color(0xFFD4AF37) 
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                if (_currentImageIndex == index)
                                  BoxShadow(
                                    color: const Color(0xFFD4AF37).withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                          ).animate().scale(delay: (index * 100).ms);
                        }),
                      ),
                    ),

                    // Availability Badge
                    if (!isAvailable)
                      Positioned(
                        top: 100,
                        left: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            "TIDAK TERSEDIA",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content Section
              Expanded(
                flex: 55,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 24, bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle Indicator
                        Center(
                          child: Container(
                            width: 60,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const Gap(24),

                        // Header Info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category & Name Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Category Badge
                                        FutureBuilder<String>(
                                          future: _getCategoryName(widget.motor.categoryId),
                                          builder: (context, snapshot) {
                                            final categoryName = snapshot.data ?? 
                                                (snapshot.connectionState == ConnectionState.waiting 
                                                    ? 'Loading...' : 'Error');

                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    const Color(0xFFD4AF37).withOpacity(0.2),
                                                    const Color(0xFFD4AF37).withOpacity(0.1),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: const Color(0xFFD4AF37).withOpacity(0.4),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                categoryName,
                                                style: GoogleFonts.poppins(
                                                  color: const Color(0xFFD4AF37),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const Gap(12),

                                        // Motor Name - langsung dari nama_motor
                                        Text(
                                          widget.motor.namaMotor,
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            height: 1.1,
                                            letterSpacing: -0.5,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Gap(16),

                                  // Price Tag - langsung dari harga
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFD4AF37).withOpacity(0.9),
                                          const Color(0xFFF4D03F),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFD4AF37).withOpacity(0.4),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "HARGA",
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF0F172A),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        Text(
                                          _formatRupiah(safePrice),
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(28),

                              // Specifications Grid - menggunakan data dari model
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildLuxurySpecItem(Icons.speed_rounded, "$safeCC CC", "Engine"),
                                    _buildLuxurySpecItem(Icons.calendar_month_rounded, safeYear, "Tahun"),
                                    _buildLuxurySpecItem(Icons.color_lens_rounded, safeColor, "Warna"),
                                    _buildLuxurySpecItem(Icons.engineering_rounded, isAvailable ? "Tersedia" : "Disewa", "Status"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Gap(32),

                        // Description Section - langsung dari deskripsi
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section Header
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFD4AF37),
                                          const Color(0xFFF4D03F),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const Gap(12),
                                  Text(
                                    "Deskripsi Motor",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(16),

                              // Description Text
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                child: Text(
                                  safeDescription,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: Colors.white.withOpacity(0.8),
                                    height: 1.7,
                                    letterSpacing: 0.2,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Gap(40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1E293B).withOpacity(0.0),
                    const Color(0xFF0F172A).withOpacity(0.8),
                    const Color(0xFF0A0F1C),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Price Information - langsung dari harga
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "HARGA SEWA / HARI",
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              _formatRupiah(safePrice),
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFD4AF37),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Gap(20),

                      // Book Now Button
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFD4AF37),
                                const Color(0xFFF4D03F),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isAvailable ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DocumentUploadPage(motor: widget.motor),
                                ),
                              );
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isAvailable ? "BOOK NOW" : "TIDAK TERSEDIA",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                if (isAvailable) ...[
                                  const Gap(8),
                                  const Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuxurySpecItem(IconData icon, String value, String label) {
    return Column(
      children: [
        // Icon Container
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD4AF37).withOpacity(0.15),
                const Color(0xFFD4AF37).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.3),
            ),
          ),
          child: Icon(icon, color: const Color(0xFFD4AF37), size: 26),
        ),
        const Gap(12),

        // Value
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Gap(4),

        // Label
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white54,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}