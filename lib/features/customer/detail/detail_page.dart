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
        const SnackBar(
          content: Text("Anda harus login untuk menambahkan favorit."),
        ),
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

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Dihapus dari favorit.")));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  String _formatRupiah(int? price) {
    if (price == null) return "Rp 0";
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final safeImageUrl = widget.motor.fotoMotor ?? '';
    final safeDescription =
        widget.motor.deskripsi ?? 'Deskripsi belum tersedia untuk motor ini.';
    final safeCC = widget.motor.cc?.toString() ?? 'N/A';
    final safePrice = widget.motor.harga;
    final safeYear = widget.motor.tahunKeluaran?.toString() ?? 'N/A';
    final safeColor = widget.motor.warnaMotor ?? 'N/A';
    final isAvailable = widget.motor.isAvailable ?? true;

    final favoriteIcon = _isFavorite
        ? Icons.favorite_rounded
        : Icons.favorite_border_rounded;
    final favoriteColor = _isFavorite ? Colors.redAccent : Colors.white;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          // Header Section dengan SliverAppBar
          SliverAppBar(
            expandedHeight: size.height * 0.4,
            stretch: true,
            backgroundColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: _isLoadingFavorite && userId != null
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : IconButton(
                          icon: Icon(favoriteIcon, color: favoriteColor),
                          onPressed: _toggleWishlist,
                        ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                children: [
                  // Main Image
                  Positioned.fill(
                    child: safeImageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: safeImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFF1E293B),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: const Color(0xFFD4AF37),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFF1E293B),
                              child: Center(
                                child: Icon(
                                  Icons.motorcycle,
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withOpacity(0.5),
                                  size: 100,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF1E293B),
                            child: Center(
                              child: Icon(
                                Icons.motorcycle,
                                color: const Color(0xFFD4AF37).withOpacity(0.5),
                                size: 100,
                              ),
                            ),
                          ),
                  ),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF0F172A).withOpacity(0.9),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Availability Badge
                  if (!isAvailable)
                    Positioned(
                      top: 100,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
          ),

          // Content Section
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category & Price Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FutureBuilder<String>(
                              future: _getCategoryName(widget.motor.categoryId),
                              builder: (context, snapshot) {
                                final categoryName = snapshot.data ?? 'LOADING';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFD4AF37,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFD4AF37,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    categoryName,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFD4AF37),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Text(
                              _formatRupiah(safePrice),
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD4AF37),
                              ),
                            ),
                          ],
                        ),
                        const Gap(8),

                        // Motor Name
                        Text(
                          widget.motor.namaMotor,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          "Harga per hari",
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Specifications Grid
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "SPESIFIKASI",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFD4AF37),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Gap(20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSpecItem(Icons.speed, "$safeCC CC", "Engine"),
                            _buildSpecItem(
                              Icons.calendar_today,
                              safeYear,
                              "Tahun",
                            ),
                          ],
                        ),
                        const Gap(16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSpecItem(
                              Icons.color_lens,
                              safeColor,
                              "Warna",
                            ),
                            _buildSpecItem(
                              Icons.inventory_2,
                              isAvailable ? "Tersedia" : "Disewa",
                              "Status",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Description Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Deskripsi Motor",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            safeDescription,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Spacing untuk tombol
                  const Gap(100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Fixed Bottom Button
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Price Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "HARGA SEWA / HARI",
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatRupiah(safePrice),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Book Button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isAvailable
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DocumentUploadPage(motor: widget.motor),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAvailable
                        ? const Color(0xFFD4AF37)
                        : Colors.grey,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAvailable ? "BOOK NOW" : "TIDAK TERSEDIA",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isAvailable) ...[
                        const Gap(8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
              ),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 24),
          ),
          const Gap(8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(4),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
