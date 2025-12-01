import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rentsoed_app/models/motor_model.dart';
import 'package:rentsoed_app/models/insurance_model.dart';
import 'package:rentsoed_app/models/promo_model.dart';
import 'package:rentsoed_app/features/main_page.dart';

class BookingPage extends StatefulWidget {
  final MotorModel motor;
  const BookingPage({super.key, required this.motor});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  int _totalDays = 0;
  int _motorSubtotal = 0;
  int _insuranceDailyCost = 0;
  int _insuranceTotalCost = 0;
  bool _isSaving = false;

  // State untuk Promo
  final _promoController = TextEditingController();
  PromoModel? _appliedPromo;
  int _discountAmount = 0;
  String? _promoError;

  String? _selectedInsuranceId;
  List<InsuranceModel> _availableInsurances = [];
  bool _isLoadingInsurance = true;

  // ✅ FIX: Deklarasi variabel Future yang hilang
  late Future<void> _fetchDataFuture;

  // Getter untuk total harga akhir
  int get finalPrice => _motorSubtotal + _insuranceTotalCost - _discountAmount;

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = _fetchInsurances();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  // --- FUNGSI 1: AMBIL DATA ASURANSI ---
  Future<void> _fetchInsurances() async {
    try {
      final response = await Supabase.instance.client
          .from('insurance')
          .select('*');

      if (mounted) {
        setState(() {
          _availableInsurances = response
              .map((data) => InsuranceModel.fromJson(data))
              .toList();
          _isLoadingInsurance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInsurance = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat asuransi: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- FUNGSI 2: VALIDASI & APLIKASI PROMO ---
  Future<void> _applyPromo() async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _discountAmount = 0;
      _appliedPromo = null;
      _promoError = null;
      _isSaving = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('promos')
          .select('*')
          .eq('code', code)
          .maybeSingle();

      if (response == null) {
        throw Exception("Kode promo tidak valid.");
      }

      final promo = PromoModel.fromJson(response);

      // Cek tanggal kadaluarsa
      if (promo.expiryDate.isBefore(DateTime.now())) {
        throw Exception("Kode promo sudah kadaluarsa.");
      }

      // Jika semua valid, hitung diskon
      final currentSubtotal = _motorSubtotal + _insuranceTotalCost;
      int discount = 0;

      if (promo.discountType == 'percentage') {
        discount = (currentSubtotal * promo.discountValue / 100).round();
      } else if (promo.discountType == 'fixed') {
        discount = promo.discountValue;
      }

      // Pastikan diskon tidak lebih besar dari total harga
      if (discount > currentSubtotal) {
        discount = currentSubtotal;
      }

      if (mounted) {
        setState(() {
          _appliedPromo = promo;
          _discountAmount = discount;
          _promoError = "Promo berhasil diterapkan!";
        });
        _calculateFinalPrice();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _promoError = "Gagal: ${e.toString().split(':')[1].trim()}";
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- FUNGSI 3: PILIH TANGGAL & HITUNG ---
  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart ? now : (_startDateTime ?? now);

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) => _luxuryTheme(child!),
    );
    if (date == null) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) => _luxuryTheme(child!),
    );
    if (time == null) return;

    final DateTime result = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _startDateTime = result;
        if (_endDateTime != null && _endDateTime!.isBefore(_startDateTime!)) {
          _endDateTime = null;
          _totalDays = 0;
          _motorSubtotal = 0;
        }
      } else {
        if (_startDateTime != null && result.isBefore(_startDateTime!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Waktu kembali harus setelah waktu ambil!"),
            ),
          );
          return;
        }
        _endDateTime = result;

        if (_startDateTime != null) {
          final difference = _endDateTime!.difference(_startDateTime!);
          _totalDays = (difference.inHours / 24).ceil();
          if (_totalDays <= 0) _totalDays = 1;
          _motorSubtotal = _totalDays * widget.motor.harga;
        }
      }
      _calculateFinalPrice();
    });
  }

  // Hitung Total Harga
  void _calculateFinalPrice() {
    int newInsuranceDailyCost = 0;

    if (_selectedInsuranceId != null && _availableInsurances.isNotEmpty) {
      try {
        final selectedIns = _availableInsurances.firstWhere(
          (i) => i.id == _selectedInsuranceId!,
        );
        newInsuranceDailyCost = selectedIns.dailyCost;
      } catch (e) {
        newInsuranceDailyCost = 0;
      }
    }

    setState(() {
      _insuranceDailyCost = newInsuranceDailyCost;
      _insuranceTotalCost = newInsuranceDailyCost * _totalDays;

      // ⚠️ Hitung ulang diskon jika subtotal berubah
      if (_appliedPromo != null) {
        final currentSubtotal = _motorSubtotal + _insuranceTotalCost;
        int newDiscount = 0;
        if (_appliedPromo!.discountType == 'percentage') {
          newDiscount = (currentSubtotal * _appliedPromo!.discountValue / 100)
              .round();
        } else {
          newDiscount = _appliedPromo!.discountValue;
        }
        if (newDiscount > currentSubtotal) {
          newDiscount = currentSubtotal;
        }
        _discountAmount = newDiscount;
      } else {
        _discountAmount = 0;
      }
    });
  }

  // --- FUNGSI 4: SUBMIT BOOKING & INVOICE ---
  Future<void> _submitBooking() async {
    if (_startDateTime == null || _endDateTime == null || _totalDays == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih periode sewa yang valid!")),
      );
      return;
    }

    setState(() => _isSaving = true);
    final finalTotal = _motorSubtotal + _insuranceTotalCost - _discountAmount;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) throw Exception("Sesi habis, silakan login kembali.");

      // 1. INSERT KE TABEL 'bookings'
      final bookingData = {
        'user_id': user.id,
        'email': user.email,
        'motor_id': widget.motor.id,
        'motor_name': widget.motor.namaMotor,
        'motor_image': widget.motor.fotoMotor ?? '',
        'start_date': _startDateTime!.toIso8601String(),
        'end_date': _endDateTime!.toIso8601String(),
        'total_days': _totalDays,
        'total_price': finalPrice,
        'status': 'Menunggu Pembayaran',
      };

      final response = await supabase
          .from('bookings')
          .insert(bookingData)
          .select('id')
          .single();

      final bookingId = response['id'];

      // 2. INSERT KE TABEL 'invoices'
      final invoiceData = {
        'booking_id': bookingId,
        'subtotal': _motorSubtotal + _insuranceTotalCost,
        'insurance_fee': _insuranceTotalCost,
        'promo_code_used': _appliedPromo?.code,
        'discount_used': _discountAmount,
        'final_total': finalPrice,
        'is_paid': false,
      };

      await supabase.from('invoices').insert(invoiceData);

      // 3. UPDATE MOTOR → SET is_available = false
      await supabase
          .from('motors')
          .update({'is_available': false})
          .eq('id', widget.motor.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Booking berhasil! Motor telah dikunci."),
            backgroundColor: Colors.green,
          ),
        );

        // Redirect to Main Page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menyimpan booking: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- WIDGETS & HELPERS ---

  Widget _luxuryTheme(Widget child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          onPrimary: Color(0xFF0F172A),
          surface: Color(0xFF1E293B),
          onSurface: Colors.white,
        ),
      ),
      child: child,
    );
  }

  String formatRupiah(int number) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(number);

  String formatDateTime(DateTime? date) {
    if (date == null) return "Pilih Waktu";
    return DateFormat('dd MMM, HH:mm').format(date);
  }

  // WIDGET OPSI ASURANSI
  Widget _buildInsuranceList() {
    if (_isLoadingInsurance) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      );
    }
    if (_availableInsurances.isEmpty) {
      return Text(
        "Tidak ada opsi asuransi tersedia.",
        style: GoogleFonts.poppins(color: Colors.white38),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _availableInsurances.map((insurance) {
        final isSelected = _selectedInsuranceId == insurance.id;
        final insCostTotal =
            insurance.dailyCost * (_totalDays > 0 ? _totalDays : 1);

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedInsuranceId = isSelected ? null : insurance.id;
            });
            _calculateFinalPrice();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFD4AF37).withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? const Color(0xFFD4AF37) : Colors.white10,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? const Color(0xFFD4AF37)
                            : Colors.white38,
                        size: 22,
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insurance.name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              insurance.coverage ?? 'Proteksi standar',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _totalDays > 0
                      ? "+ ${formatRupiah(insCostTotal)}"
                      : "${formatRupiah(insurance.dailyCost)}/hari",
                  style: GoogleFonts.poppins(
                    color: isSelected
                        ? const Color(0xFFD4AF37)
                        : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool isBold = false,
    Color color = Colors.white,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.white70)),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 18 : 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final finalTotal = _motorSubtotal + _insuranceTotalCost - _discountAmount;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          "Booking Detail",
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<void>(
        future: _fetchDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Gagal memuat opsi asuransi. Cek koneksi atau data DB: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. KARTU MOTOR RINGKAS ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.motorcycle,
                        size: 40,
                        color: Color(0xFFD4AF37),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.motor.namaMotor,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "${formatRupiah(widget.motor.harga)} / 24 Jam",
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(30),

                // --- 2. PILIHAN WAKTU ---
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimePicker(
                        label: "Waktu Ambil",
                        date: _startDateTime,
                        onTap: () => _pickDateTime(isStart: true),
                        icon: Icons.login,
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: _buildDateTimePicker(
                        label: "Waktu Kembali",
                        date: _endDateTime,
                        onTap: () => _pickDateTime(isStart: false),
                        icon: Icons.logout,
                      ),
                    ),
                  ],
                ),
                const Gap(30),

                // --- 3. PILIHAN ASURANSI (OPSI PROTEKSI) ---
                Text(
                  "Opsi Proteksi",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Gap(10),

                _buildInsuranceList(), // Daftar opsi asuransi

                const Gap(30),

                // --- 4. INPUT KODE PROMO ---
                Text(
                  "Kode Promo",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Gap(10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Masukkan Kode",
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        onSubmitted: (_) => _applyPromo(),
                      ),
                    ),
                    const Gap(10),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _applyPromo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "APPLY",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                // Pesan Feedback Promo
                if (_promoError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _promoError!,
                      style: GoogleFonts.poppins(
                        color: _appliedPromo != null
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const Gap(30),

                // --- 5. SUMMARY BIAYA ---
                if (_totalDays > 0)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        _row(
                          "Subtotal Sewa (${_totalDays} Hari)",
                          formatRupiah(_motorSubtotal),
                        ),
                        _row(
                          "Biaya Asuransi",
                          formatRupiah(_insuranceTotalCost),
                        ),
                        // Tampilkan Diskon
                        if (_discountAmount > 0)
                          _row(
                            "Diskon Promo (${_appliedPromo!.code})",
                            "- ${formatRupiah(_discountAmount)}",
                            color: Colors.greenAccent,
                          ),

                        const Divider(color: Colors.white10),
                        const Gap(10),
                        _row(
                          "Total Biaya Akhir",
                          formatRupiah(finalTotal),
                          isBold: true,
                          color: const Color(0xFFD4AF37),
                        ),
                      ],
                    ),
                  ),
                const Gap(80), // Padding untuk tombol CONFIRM
              ],
            ),
          );
        },
      ),

      // --- TOMBOL KONFIRMASI (FIXED BOTTOM) ---
      bottomSheet: Container(
        color: const Color(0xFF0F172A),
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_totalDays > 0 && !_isSaving) ? _submitBooking : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.withOpacity(0.2),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "CONFIRM BOOKING",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    // Logic date time picker
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? const Color(0xFFD4AF37) : Colors.white24,
            width: date != null ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.white54),
                const Gap(6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const Gap(8),
            Text(
              formatDateTime(date),
              style: GoogleFonts.poppins(
                color: date != null ? Colors.white : Colors.white30,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
