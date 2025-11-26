import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:rentsoed_app/features/admin/transactions/booking_detail_page.dart';

class ManageBookingsPage extends StatefulWidget {
  const ManageBookingsPage({super.key});

  @override
  State<ManageBookingsPage> createState() => _ManageBookingsPageState();
}

class _ManageBookingsPageState extends State<ManageBookingsPage> {
  // Opsi Status sesuai permintaan user
  String _selectedStatus = 'Semua';
  final List<String> _statusOptions = [
    'Semua',
    'Menunggu Verifikasi',
    'Dibatalkan',
    'Selesai',
  ];

  // Helper untuk memetakan status UI ke status DB internal (TIDAK LAGI DIGUNAKAN UNTUK QUERY)
  String _getDbStatus(String uiStatus) {
    if (uiStatus == 'Menunggu Verifikasi') {
      return 'Menunggu Pembayaran'; 
    }
    return uiStatus; 
  }
  
  // ✅ FIX UTAMA: Hanya mengembalikan Stream dasar yang diurutkan
  Stream<List<Map<String, dynamic>>> _getRawBookingsStream() {
    // Mengambil SEMUA data bookings dan diurutkan
    return Supabase.instance.client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("Kelola Transaksi", style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // --- FILTER DROPDOWN ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  dropdownColor: const Color(0xFF1E293B),
                  isExpanded: true,
                  style: GoogleFonts.poppins(color: Colors.white),
                  items: _statusOptions.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // ✅ FIX: Memanggil Stream dasar yang aman
              stream: _getRawBookingsStream(), 
                  
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                }
                if (snapshot.hasError) {
                   return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
                }
                
                final allBookings = snapshot.data ?? [];
                
                // 1. Filter Berdasarkan Status yang Dipilih
                final filteredByStatus = _selectedStatus == 'Semua'
                    ? allBookings
                    : allBookings.where((b) => b['status'] == _getDbStatus(_selectedStatus)).toList();

                // 2. Filter Bukti Bayar HANYA JIKA status adalah 'Menunggu Verifikasi'
                final bookings = (_selectedStatus == 'Menunggu Verifikasi') 
                  ? filteredByStatus.where((b) => b['payment_proof_url'] != null).toList()
                  : filteredByStatus;


                if (bookings.isEmpty) {
                  return Center(child: Text("Tidak ada transaksi dengan status '$_selectedStatus'.", style: const TextStyle(color: Colors.white70)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    
                    final motorName = booking['motor_name'] ?? 'Motor'; 
                    final userEmail = booking['email'] ?? 'Email Tidak Ada';
                    final totalPrice = booking['total_price'] as int? ?? 0;
                    final paymentProof = booking['payment_proof_url'] != null;
                    final status = booking['status'] as String? ?? 'Unknown';

                    Color statusColor = _getStatusColor(status);

                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => BookingDetailPage(bookingData: booking))
                        );
                      },
                      contentPadding: const EdgeInsets.all(12),
                      tileColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
                      ),
                      
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Icon(Icons.receipt, color: statusColor),
                      ),
                      
                      title: Text(motorName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Oleh: $userEmail", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                          Text("Total: Rp ${NumberFormat('#,##0', 'id_ID').format(totalPrice)}", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          Text("Status: $status ${paymentProof ? '(Bukti Bayar Ada)' : ''}", 
                            style: GoogleFonts.poppins(color: statusColor, fontSize: 11)),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Dibayar':
        return Colors.green; // Status internal
      case 'Selesai':
        return Colors.teal;
      case 'Menunggu Verifikasi': // Status di UI
      case 'Menunggu Pembayaran':
        return Colors.orangeAccent;
      case 'Dibatalkan':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }
}