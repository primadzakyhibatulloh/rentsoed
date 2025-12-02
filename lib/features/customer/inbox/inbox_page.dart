import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  // Helper: Format waktu agar mudah dibaca
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return '-';
    }
  }

  // Fungsi untuk menandai notifikasi sebagai sudah dibaca
  Future<void> _markAsRead(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint("Gagal menandai notif sebagai dibaca: $e");
    }
  }

  // --- FUNGSI BARU: MENGHAPUS NOTIFIKASI ---
  Future<void> _deleteNotification(
    String notificationId,
    BuildContext context,
  ) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notifikasi berhasil dihapus.")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menghapus: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- FUNGSI BARU: DIALOG KONFIRMASI ---
  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B), // Warna Navy Card
          title: Text(
            "Hapus Notifikasi?",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Apakah kamu yakin akan menghapus notifikasi ini?",
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Batal
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Hapus
              child: const Text(
                "Hapus",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          "Inbox Notifikasi",
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userId == null
          ? const Center(
              child: Text(
                "Silakan login untuk melihat notifikasi.",
                style: TextStyle(color: Colors.white54),
              ),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('notifications')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', userId)
                  .order('is_read', ascending: true)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  );
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Tidak ada notifikasi baru.",
                          style: GoogleFonts.poppins(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isRead = notif['is_read'] as bool;
                    final notifId = notif['id'];

                    // --- WRAP DENGAN DISMISSIBLE UNTUK FITUR SWIPE-TO-DELETE ---
                    return Dismissible(
                      key: Key(notifId),
                      direction:
                          DismissDirection.endToStart, // Geser Kanan ke Kiri
                      // Background Merah saat digeser
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),

                      // Dialog Konfirmasi sebelum hapus
                      confirmDismiss: (direction) async {
                        return await _showDeleteConfirmation(context);
                      },

                      // Aksi Hapus jika dikonfirmasi
                      onDismissed: (direction) {
                        _deleteNotification(notifId, context);
                      },

                      // Item UI Asli
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isRead
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () {
                            if (!isRead) {
                              _markAsRead(notifId);
                            }
                          },
                          leading: Icon(
                            isRead
                                ? Icons.mark_email_read_outlined
                                : Icons.mark_email_unread_outlined,
                            color: isRead
                                ? Colors.white54
                                : const Color(0xFFD4AF37),
                          ),
                          title: Text(
                            notif['title'],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            notif['message'],
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            _formatDate(notif['created_at']),
                            style: GoogleFonts.poppins(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
