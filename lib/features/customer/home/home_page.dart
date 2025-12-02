import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Import Halaman & Model
import 'package:rentsoed_app/features/customer/detail/detail_page.dart';
import 'package:rentsoed_app/models/motor_model.dart';
import 'package:rentsoed_app/models/category_model.dart';
import 'package:rentsoed_app/widgets/custom_drawer.dart';
import 'package:rentsoed_app/features/customer/inbox/inbox_page.dart';
import 'package:rentsoed_app/features/customer/voucher/promo_list_page.dart';

// ✅ IMPORT Payment Page
import 'package:rentsoed_app/features/customer/payment/payment_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- STATE VARIABLES ---
  String _selectedCategoryId = 'all';
  String _searchQuery = '';

  // ✅ State untuk mengontrol visibilitas kartu pembayaran
  bool _showPaymentCard = true;

  // --- CAROUSEL VARIABLES ---
  final PageController _pageController = PageController();
  int _currentPromoIndex = 0;
  Timer? _carouselTimer;

  // --- STREAMS ---
  late final Stream<List<Map<String, dynamic>>> _categoriesStream;
  late final Stream<List<Map<String, dynamic>>> _motorsStream;
  late final Stream<List<Map<String, dynamic>>> _promosStream;
  late final Stream<List<Map<String, dynamic>>> _pendingPaymentStream;

  // --- THEME COLORS ---
  final Color gold = const Color(0xFFD4AF37);
  final Color navy = const Color(0xFF0F172A);
  final Color cardColor = const Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;

    // 1. STREAM KATEGORI
    _categoriesStream = Supabase.instance.client
        .from('categories')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows.map((e) => Map<String, dynamic>.from(e)).toList();
          list.sort(
            (a, b) => a['nama_kategori'].toString().toLowerCase().compareTo(
              b['nama_kategori'].toString().toLowerCase(),
            ),
          );
          final hasAll = list.any((e) => e['id'] == 'all');
          if (!hasAll) {
            list.insert(0, {'id': 'all', 'nama_kategori': 'All'});
          }
          return list;
        });

    // 2. STREAM MOTOR
    _motorsStream = Supabase.instance.client
        .from('motors')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows.map((e) => Map<String, dynamic>.from(e)).toList();
          return list.where((m) {
            return m['is_available'] == true ||
                m['is_available'].toString() == 'true';
          }).toList();
        });

    // 3. STREAM PROMO
    _promosStream = Supabase.instance.client
        .from('promos')
        .stream(primaryKey: ['id'])
        .order('id')
        .map((rows) {
          // Filter is_active manual di sini
          return rows.where((r) => r['is_active'] == true).toList();
        });

    // 4. STREAM PENDING PAYMENT
    if (userId != null) {
      _pendingPaymentStream = Supabase.instance.client
          .from('bookings')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false) // Order didukung
          .map((data) {
            return data.where((booking) {
              return booking['user_id'] == userId &&
                  booking['status'] == 'Menunggu Pembayaran';
            }).toList();
          });
    } else {
      _pendingPaymentStream = const Stream.empty();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  // --- LOGIC AUTO PLAY CAROUSEL ---
  void _startAutoPlay(int itemCount) {
    _carouselTimer?.cancel();
    if (itemCount > 1) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_pageController.hasClients) {
          int nextPage = _pageController.page!.toInt() + 1;
          if (nextPage >= itemCount) {
            nextPage = 0;
          }
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  // --- HELPER FUNCTIONS ---
  String formatRupiah(int number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  List<CategoryModel> _toCategoryModels(List<Map<String, dynamic>> rows) {
    return rows.map((r) {
      try {
        return CategoryModel.fromJson(r);
      } catch (_) {
        return CategoryModel(
          id: r['id'].toString(),
          namaKategori: r['nama_kategori']?.toString() ?? 'Unknown',
        );
      }
    }).toList();
  }

  List<MotorModel> _toMotorModels(List<Map<String, dynamic>> rows) {
    return rows.map((r) {
      try {
        return MotorModel.fromJson(r);
      } catch (_) {
        return MotorModel(
          id: r['id']?.toString() ?? '',
          namaMotor: r['nama_motor']?.toString() ?? '',
          harga: int.tryParse(r['harga']?.toString() ?? '0') ?? 0,
          categoryId: r['category_id']?.toString() ?? '',
          fotoMotor: r['foto_motor']?.toString(),
        );
      }
    }).toList();
  }

  // --- EVENT HANDLERS ---
  void _onCategorySelected(String categoryId) {
    setState(() => _selectedCategoryId = categoryId);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _navigateToInbox() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InboxPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ??
        'Pelanggan';

    return Scaffold(
      backgroundColor: navy,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "RENTSOED",
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: gold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _navigateToInbox,
            icon: const Icon(Icons.notifications_none, color: Colors.white54),
          ),
          const Gap(8),
        ],
      ),

      body: Stack(
        children: [
          // LAYER 1: KONTEN UTAMA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome Back,",
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                Text(
                  userName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Gap(20),

                // HEADER PROMO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Promo Spesial",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PromoListPage(),
                        ),
                      ),
                      child: Text(
                        "Lihat Semua",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(10),

                _buildPromoCarouselStream(),
                const Gap(20),

                _buildSearchBar(),
                const Gap(16),

                // CATEGORY LIST
                SizedBox(
                  height: 50,
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _categoriesStream,
                    builder: (context, snapCat) {
                      if (snapCat.connectionState == ConnectionState.waiting)
                        return _buildCategoryShimmer();
                      final categories = _toCategoryModels(snapCat.data ?? []);
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) => _buildCategoryChip(
                          categories[i],
                          _selectedCategoryId == categories[i].id,
                        ),
                      );
                    },
                  ),
                ),
                const Gap(16),

                // MOTORS GRID
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _motorsStream,
                    builder: (context, snapMotors) {
                      if (snapMotors.connectionState == ConnectionState.waiting)
                        return _buildLoadingGrid();
                      if (snapMotors.hasError)
                        return Center(
                          child: Text(
                            "Error memuat data",
                            style: GoogleFonts.poppins(color: Colors.red),
                          ),
                        );

                      final rawData = snapMotors.data ?? [];
                      final allMotors = _toMotorModels(rawData);

                      final filteredMotors = allMotors.where((motor) {
                        final matchCategory =
                            _selectedCategoryId == 'all' ||
                            motor.categoryId == _selectedCategoryId;
                        final matchSearch = motor.namaMotor
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                        return matchCategory && matchSearch;
                      }).toList();

                      filteredMotors.sort(
                        (a, b) => a.namaMotor.compareTo(b.namaMotor),
                      );

                      if (filteredMotors.isEmpty) return _buildEmptyState();

                      return GridView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: filteredMotors.length,
                        itemBuilder: (context, index) =>
                            _buildMotorCard(filteredMotors[index], index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // LAYER 2: FLOATING PAYMENT CARD
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _pendingPaymentStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.data!.isEmpty ||
                  !_showPaymentCard) {
                return const SizedBox.shrink();
              }

              final booking = snapshot.data!.first;
              final bookingId = booking['id'];
              final motorName = booking['motor_name'] ?? 'Motor';
              final totalPrice = booking['total_price'] as int? ?? 0;

              return Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child:
                    Dismissible(
                          key: Key(bookingId),
                          direction: DismissDirection.horizontal,
                          onDismissed: (direction) {
                            setState(() {
                              _showPaymentCard = false;
                            });
                          },
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentPage(
                                    bookingId: bookingId,
                                    totalPrice: totalPrice,
                                    motorName: motorName,
                                  ),
                                ),
                              );
                            },
                            // --- ANIMASI 1: SHIMMER BERULANG (LOOP) ---
                            // Kita taruh di Container agar hanya efek kilaunya yang berulang
                            child:
                                Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.shade700,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.4,
                                            ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.access_time_filled,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Gap(16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  "Menunggu Pembayaran!",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  "Selesaikan sewa $motorName.",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    )
                                    .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(), // ✅ MEMBUAT LOOP
                                    )
                                    .shimmer(
                                      delay:
                                          2000.ms, // Jeda 2 detik setiap kilau
                                      duration: 1500.ms, // Durasi kilau lewat
                                      color: Colors.white.withOpacity(
                                        0.4,
                                      ), // Warna kilau
                                    ),
                          ),
                        )
                        // --- ANIMASI 2: SLIDE UP (SEKALI SAJA) ---
                        // Ditaruh di luar Container (di Dismissible) agar kartunya muncul cantik dari bawah
                        .animate()
                        .slideY(
                          begin: 1, // Mulai dari bawah
                          end: 0, // Ke posisi asli
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGET PROMO CAROUSEL ---
  Widget _buildPromoCarouselStream() {
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _promosStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(18),
              ),
            ).animate().shimmer(duration: 1000.ms);
          }

          final promos = snapshot.data ?? [];

          if (promos.isEmpty) {
            return _buildDefaultPromoBanner();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_carouselTimer == null || !_carouselTimer!.isActive) {
              _startAutoPlay(promos.length);
            }
          });

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: promos.length,
                onPageChanged: (index) {
                  setState(() => _currentPromoIndex = index);
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PromoListPage(),
                        ),
                      );
                    },
                    child: _buildPromoCard(promos[index]),
                  );
                },
              ),
              if (promos.length > 1)
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Row(
                    children: List.generate(promos.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: _currentPromoIndex == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentPromoIndex == index
                              ? gold
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    final code = promo['code'] ?? '';
    final description = promo['description'] ?? '';
    final discountType = promo['discount_type'] ?? 'fixed';
    final discountValue = promo['discount_value'] ?? 0;

    String discountText = '';
    if (discountType == 'percentage') {
      discountText = "$discountValue%";
    } else {
      discountText = formatRupiah(discountValue);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [gold.withOpacity(0.25), const Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    code,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                ),
                const Gap(8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Gap(4),
                Text(
                  "Hemat hingga $discountText",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Icon(
                  discountType == 'percentage'
                      ? Icons.percent
                      : Icons.attach_money,
                  size: 40,
                  color: gold.withOpacity(0.90),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white10,
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Center(
        child: Text(
          "Belum ada promo saat ini.",
          style: GoogleFonts.poppins(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(CategoryModel category, bool isSelected) {
    return GestureDetector(
      onTap: () => _onCategorySelected(category.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [gold.withOpacity(0.95), const Color(0xFFC49B2A)],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? gold : Colors.white.withOpacity(0.06),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gold.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            category.namaKategori,
            style: GoogleFonts.poppins(
              color: isSelected ? navy : Colors.white,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFFD4AF37)),
          const Gap(12),
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration.collapsed(
                hintText: "Cari motor impian Anda...",
                hintStyle: TextStyle(color: Colors.white38),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotorCard(MotorModel motor, int index) {
    final safeImageUrl = motor.fotoMotor ?? '';
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => FadeTransition(
              opacity: anim,
              child: DetailPage(motor: motor),
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Hero(
                tag: motor.id + (motor.namaMotor),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white10,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: safeImageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: safeImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFD4AF37),
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(
                                Icons.motorcycle,
                                color: Colors.white24,
                                size: 48,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.motorcycle,
                              size: 56,
                              color: Colors.white24,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const Gap(12),
            Text(
              "TERSEDIA",
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(4),
            Text(
              motor.namaMotor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(10),
            Row(
              children: [
                Text(
                  formatRupiah(motor.harga),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(4),
                Text(
                  '/hari',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget _buildCategoryShimmer() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, __) => Container(
        width: 80,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 50, color: Colors.white24),
          const Gap(10),
          Text(
            "Motor tidak ditemukan.",
            style: GoogleFonts.poppins(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
