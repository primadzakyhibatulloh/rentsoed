import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

class TestimonialPage extends StatefulWidget {
  const TestimonialPage({super.key});

  @override
  State<TestimonialPage> createState() => _TestimonialPageState();
}

class _TestimonialPageState extends State<TestimonialPage> with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _reviewsFuture;
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'all'; // Nilai bisa: 'all', '5_star', '4_star', ..., '1_star'
  
  // Data opsi Dropdown
  final List<Map<String, String>> _ratingOptions = [
    {'label': 'Semua Bintang', 'value': 'all'},
    {'label': '⭐ 5 Bintang', 'value': '5_star'},
    {'label': '⭐ 4 Bintang', 'value': '4_star'},
    {'label': '⭐ 3 Bintang', 'value': '3_star'},
    {'label': '⭐ 2 Bintang', 'value': '2_star'},
    {'label': '⭐ 1 Bintang', 'value': '1_star'},
  ];


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _scrollController.addListener(_onScroll);
    _fetchReviews();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Logika ini tidak lagi diperlukan karena AppBar tidak collapsible
    // setState(() { _showAppBarShadow = _scrollController.offset > 50; }); 
  }

  void _fetchReviews() {
    setState(() {
      _reviewsFuture = _getReviewsData();
    });
  }

  Future<List<Map<String, dynamic>>> _getReviewsData() async {
    try {
      final supabase = Supabase.instance.client;
      
      String selectQuery = 
          'rating, comment, created_at, '
          'bookings:booking_id(motor_id, user_id, '
            'motors(nama_motor, foto_motor), '
            'profiles(full_name, avatar_url)'
          ')';

      // FIX RLS/TYPE ERROR: Menggunakan dynamic untuk variabel query
      dynamic query = supabase
          .from('reviews')
          .select(selectQuery);

      // 1. Terapkan filter di sisi database berdasarkan bintang yang dipilih
      if (_selectedFilter.endsWith('_star')) {
        final ratingValue = int.tryParse(_selectedFilter.split('_').first);
        if (ratingValue != null && ratingValue >= 1 && ratingValue <= 5) {
            query = query.eq('rating', ratingValue);
        }
      }

      // 2. Terapkan transformasi (ORDER dan LIMIT)
      query = query.order('created_at', ascending: false);
      
      final reviewsResponse = await query.limit(50);
      
      if (reviewsResponse.isEmpty) {
        return [];
      }

      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      
      List<Map<String, dynamic>> processedReviews = [];

      // 3. Proses, Filter Lokal (Filter 'recent' - logic ini dipertahankan) dan Flatten Data
      for (final review in reviewsResponse) {
        final bookingData = review['bookings'] as Map<String, dynamic>?;
        if (bookingData == null) continue; 

        final motorData = bookingData['motors'] as Map<String, dynamic>?;
        final profileData = bookingData['profiles'] as Map<String, dynamic>?;
        
        final createdAtStr = review['created_at'] as String?;
        if (createdAtStr == null) continue;

        // Filter 'recent' (logic ini dipertahankan sebagai safeguard jika diperlukan)
        if (_selectedFilter == 'recent') {
          final reviewDate = DateTime.parse(createdAtStr);
          if (reviewDate.isBefore(oneWeekAgo)) {
            continue; 
          }
        }
        
        // Gabungkan/Flatten data
        processedReviews.add({
          // Data Review
          'rating': review['rating'] as int,
          'comment': review['comment'] as String?,
          'created_at': createdAtStr,
          
          // Data User (Nama Pelanggan ASLI)
          'full_name': profileData?['full_name'] ?? 'Pelanggan',
          'avatar_url': profileData?['avatar_url'],

          // Data Motor
          'motor_name': motorData?['nama_motor'] ?? 'Motor',
          'motor_image': motorData?['foto_motor'],
        });
      }

      return processedReviews;
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      throw Exception('Gagal memuat testimoni. Pastikan RLS di tabel reviews, bookings, profiles, dan motors sudah diatur.');
    }
  }

  void _applyFilter(String filter) {
    if (_selectedFilter == filter) return; 
    
    setState(() {
      _selectedFilter = filter;
      _reviewsFuture = _getReviewsData();
    });
    // Scroll ke atas saat filter diterapkan
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }
  
  // --- HELPER FUNCTIONS (getTimeAgo, getRatingDescription, etc.) tetap sama ---
  String _getTimeAgo(String dateStr) {
    try {
      final postedTime = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().toLocal().difference(postedTime);

      if (diff.inDays > 30) {
        final months = (diff.inDays / 30).floor();
        return '$months ${months > 1 ? 'bulan' : 'bulan'} lalu';
      } else if (diff.inDays > 0) {
        return '${diff.inDays} ${diff.inDays > 1 ? 'hari' : 'hari'} lalu';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} ${diff.inHours > 1 ? 'jam' : 'jam'} lalu';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} ${diff.inMinutes > 1 ? 'menit' : 'menit'} lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return 'Tanggal tidak valid';
    }
  }

  String _getRatingDescription(double rating) {
    switch (rating.round()) {
      case 5: return 'Sangat Memuaskan';
      case 4: return 'Memuaskan';
      case 3: return 'Cukup Baik';
      case 2: return 'Kurang Memuaskan';
      case 1: return 'Tidak Memuaskan';
      default: return 'Belum Dinilai';
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.greenAccent;
    if (rating >= 3) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  void _showReviewDetail(Map<String, dynamic> review) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => _buildReviewDetailSheet(review),
    );
  }

  // --- WIDGET DETAIL REVIEW (MODAL BOTTOM SHEET) ---
  Widget _buildReviewDetailSheet(Map<String, dynamic> review) {
    final reviewerName = review['full_name'] as String? ?? 'Pelanggan';
    final motorName = review['motor_name'] as String? ?? 'Motor';
    final avatarUrl = review['avatar_url'];
    final rating = (review['rating'] as int?)?.toDouble() ?? 0.0;
    final comment = review['comment'] as String? ?? 'Tidak ada komentar';
    final timeAgo = _getTimeAgo(review['created_at']);
    final motorImage = review['motor_image'];

    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detail Testimoni',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              ],
            ),
            const Gap(20),

            // User Info
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                    image: avatarUrl != null && avatarUrl.toString().isNotEmpty
                        ? DecorationImage(
                              image: CachedNetworkImageProvider(avatarUrl.toString()),
                              fit: BoxFit.cover,
                            )
                        : null,
                  ),
                  child: avatarUrl == null || avatarUrl.toString().isEmpty
                      ? const Icon(Icons.person_rounded, color: Colors.white54, size: 24)
                      : null,
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewerName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(20),

            // Rating
            Row(
              children: [
                RatingBar.builder(
                  initialRating: rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 24,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                  itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: Colors.amber),
                  onRatingUpdate: (rating) {},
                  ignoreGestures: true,
                ),
                const Gap(12),
                Text(
                  _getRatingDescription(rating),
                  style: GoogleFonts.poppins(
                    color: _getRatingColor(rating),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Gap(20),

            // Motor Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  // Motor Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.02),
                      image: motorImage != null && motorImage.toString().startsWith('http')
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(motorImage.toString()),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: motorImage == null || !motorImage.toString().startsWith('http')
                        ? const Icon(Icons.motorcycle_rounded, color: Colors.white54, size: 24)
                        : null,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Motor yang Disewa',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          motorName,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFD4AF37),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),

            // Comment
            Text(
              'Ulasan',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                comment,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
            const Gap(30),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DROPDOWN BARU (Menggantikan Filter Chips) ---
  Widget _buildRatingDropdown() {
    // Tentukan label yang akan ditampilkan saat dropdown tertutup
    final currentLabel = _ratingOptions.firstWhere(
      (option) => option['value'] == _selectedFilter,
      orElse: () => _ratingOptions.first,
    )['label']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Navy Terang
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5), // Border Emas
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          isExpanded: true,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4AF37)),
          
          hint: Text(currentLabel, style: GoogleFonts.poppins(color: Colors.white)),

          items: _ratingOptions.map((Map<String, String> option) {
            return DropdownMenuItem<String>(
              value: option['value'],
              child: Text(option['label']!, style: GoogleFonts.poppins(color: Colors.white)),
            );
          }).toList(),
          
          onChanged: (String? newValue) {
            if (newValue != null) {
              _applyFilter(newValue);
            }
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      // --- APP BAR (Tombol Back) ---
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Testimoni Pelanggan",
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Header besar saat belum scroll
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(10), // Memberi sedikit jarak dari AppBar
                    Text(
                      "Testimoni Pelanggan",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      "Lihat pengalaman nyata dari pelanggan kami",
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const Gap(20),
                  ],
                ),
              ),
            ),
            
            // --- DROPDOWN FILTER BARU ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: _buildRatingDropdown(),
              ),
            ),
            const SliverToBoxAdapter(child: Gap(16)), // Spacer di bawah filter
          ];
        },
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _reviewsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, 
                        color: Colors.redAccent, size: 60),
                    const Gap(16),
                    Text(
                      "Gagal memuat testimoni",
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontSize: 16,
                      ),
                    ),
                    const Gap(8),
                    TextButton(
                      onPressed: _fetchReviews,
                      child: Text(
                        "Coba Lagi",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_outline_rounded, 
                        color: Colors.white24, size: 80),
                    const Gap(16),
                    Text(
                      _selectedFilter != 'all' 
                          ? "Tidak ada testimoni untuk filter ini"
                          : "Belum ada testimoni dari pelanggan",
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_selectedFilter != 'all') ...[
                      const Gap(8),
                      TextButton(
                        onPressed: () => _applyFilter('all'),
                        child: Text(
                          "Lihat Semua Testimoni",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            final reviews = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _buildReviewCard(review, index);
              },
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET YANG SUDAH TIDAK DIGUNAKAN (FILTER CHIP) SUDAH DIHAPUS ---

  // --- WIDGET REVIEW CARD ---
  Widget _buildReviewCard(Map<String, dynamic> review, int index) {
    final reviewerName = review['full_name'] as String? ?? 'Pelanggan';
    final motorName = review['motor_name'] as String? ?? 'Motor';
    final avatarUrl = review['avatar_url'];
    final rating = (review['rating'] as int?)?.toDouble() ?? 0.0;
    final comment = review['comment'] as String? ?? 'Tidak ada komentar';
    final timeAgo = _getTimeAgo(review['created_at']);

    return Animate(
      effects: [
        FadeEffect(duration: 500.ms, delay: (100 * index).ms),
        SlideEffect(begin: const Offset(0, 0.3), end: Offset.zero, duration: 500.ms, delay: (100 * index).ms)
      ],
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: const Color(0xFF1E293B), // Navy Terang
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        elevation: 4,
        child: InkWell(
          onTap: () => _showReviewDetail(review),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER (Avatar, Nama, Waktu)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                        image: avatarUrl != null && avatarUrl.toString().isNotEmpty
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(avatarUrl.toString()),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: avatarUrl == null || avatarUrl.toString().isEmpty
                          ? const Icon(Icons.person_rounded, color: Colors.white54, size: 18)
                          : null,
                    ),
                    const Gap(12),
                    // Nama & Rating
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewerName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          RatingBar.builder(
                            initialRating: rating,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: false,
                            itemCount: 5,
                            itemSize: 16,
                            itemPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                            itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: Colors.amber),
                            onRatingUpdate: (rating) {},
                            ignoreGestures: true,
                          ),
                        ],
                      ),
                    ),
                    // Waktu
                    Text(
                      timeAgo,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
                const Gap(16),

                // 2. COMMENT BODY
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    comment,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Gap(16),

                // 3. MOTOR INFO
                Row(
                  children: [
                    const Icon(Icons.motorcycle_rounded, color: Color(0xFFD4AF37), size: 16),
                    const Gap(8),
                    Text(
                      motorName,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFD4AF37),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}