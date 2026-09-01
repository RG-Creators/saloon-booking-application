import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({super.key});

  @override
  State<NotificationsInboxScreen> createState() => _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  final _service = NotificationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
    _refresh();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await ApiService.fetchNotifications();
    if (mounted) setState(() => _isLoading = false);
  }

  void _showDetailDialog(AppNotificationItem n) {
    _service.markAsRead(n.id);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF4F46E5), size: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(n.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Text(n.body, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5)),
              const SizedBox(height: 16),
              Text(
                DateFormat('MMM d, y � h:mm a').format(n.timestamp),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _service.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifications', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A))),
            if (_service.unreadCount > 0)
              Text('${_service.unreadCount} unread update(s)', style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          if (list.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF0F172A)),
              onSelected: (val) {
                if (val == 'read_all') {
                  _service.markAllAsRead();
                  ApiService.markNotificationsRead();
                } else if (val == 'clear') {
                  _service.clearAll();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'read_all', child: Text('Mark all as read')),
                const PopupMenuItem(value: 'clear', child: Text('Clear inbox')),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                          child: const Center(child: Icon(Icons.notifications_none_rounded, size: 40, color: Color(0xFF4F46E5))),
                        ),
                        const SizedBox(height: 18),
                        Text('No Notifications Yet', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17, color: const Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        const Text(
                          'You will receive instant updates here when your bookings are confirmed or scheduled.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: const Color(0xFF4F46E5),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final item = list[i];
                      return GestureDetector(
                        onTap: () => _showDetailDialog(item),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: item.isRead ? Colors.white : const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: item.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFC7D2FE)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: item.isRead ? const Color(0xFFF1F5F9) : const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.notifications_active_rounded,
                                  size: 18,
                                  color: item.isRead ? const Color(0xFF64748B) : const Color(0xFF4F46E5),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                              fontSize: 14,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        if (!item.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.body,
                                      style: const TextStyle(color: Color(0xFF475569), fontSize: 12.5),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      DateFormat('h:mm a � MMM d').format(item.timestamp),
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
