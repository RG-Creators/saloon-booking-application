import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CustomerBooking> _upcoming = [];
  List<CustomerBooking> _past = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getCustomerBookings();
    if (!mounted) return;
    setState(() {
      _upcoming = res['upcoming'] ?? [];
      _past = res['past'] ?? [];
      _isLoading = false;
    });
  }

  void _callSalon(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showCancelDialog(CustomerBooking booking) {
    if (!booking.canCancel) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 22),
              const SizedBox(width: 8),
              const Text('Cancellation Notice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'The cancellation cutoff window for this appointment has passed.\n\nSalon Policy: ${booking.cancellationPolicyText}\n\nPlease contact ${booking.salonName} directly at ${booking.salonPhone} for changes.',
            style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Appointment?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Are you sure you want to cancel your appointment with ${booking.salonName} on ${booking.bookingDate} at ${booking.startTime}?\n\nThis slot will be released immediately.',
          style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Appointment', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await ApiService.cancelBooking(booking.id);
              if (!mounted) return;
              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment cancelled successfully.'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
                _loadBookings();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Failed to cancel'),
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                );
              }
            },
            child: const Text('Yes, Cancel Slot'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text("My Appointments", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A))),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4F46E5),
          indicatorWeight: 3,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: [
            Tab(text: 'Upcoming (${_upcoming.length})'),
            Tab(text: 'Past / History (${_past.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList(_upcoming, isUpcoming: true),
                _buildBookingList(_past, isUpcoming: false),
              ],
            ),
    );
  }

  Widget _buildBookingList(List<CustomerBooking> list, {required bool isUpcoming}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                child: const Center(child: Icon(Icons.calendar_month_rounded, size: 36, color: Color(0xFF4F46E5))),
              ),
              const SizedBox(height: 16),
              Text(
                isUpcoming ? 'No Upcoming Appointments' : 'No Past Bookings',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                isUpcoming
                    ? 'Explore nearby salons and book your next grooming session!'
                    : 'Your completed or cancelled bookings will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: const Color(0xFF4F46E5),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final booking = list[i];
          return _buildBookingCard(booking, isUpcoming: isUpcoming);
        },
      ),
    );
  }

  Widget _buildBookingCard(CustomerBooking b, {required bool isUpcoming}) {
    final statusColor = b.status == 'CONFIRMED'
        ? const Color(0xFF059669)
        : b.status == 'PENDING' || b.status == 'LOCKED'
            ? const Color(0xFFD97706)
            : b.status == 'CANCELLED'
                ? const Color(0xFFDC2626)
                : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Salon Name + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    b.salonName,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    b.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Service Name + Modality Tag
            Row(
              children: [
                Text(
                  b.serviceName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF334155)),
                ),
                if (b.bookingType != 'IN_STUDIO') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      b.bookingType == 'EVENT_WEDDING' ? '?? Wedding Event' : '?? Doorstep Visit',
                      style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),

            if (b.serviceAddress.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${b.serviceAddress}${b.addressLandmark.isNotEmpty ? ' (${b.addressLandmark})' : ''}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),

            // Details Row: Date/Time + Stylist + Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 6),
                        Text(
                          '${b.bookingDate} at ${b.startTime}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text(
                          'Stylist: ${b.staffName}',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '?${b.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 17, color: const Color(0xFF4F46E5)),
                ),
              ],
            ),

            if (isUpcoming && (b.status == 'CONFIRMED' || b.status == 'PENDING')) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _callSalon(b.salonPhone),
                    icon: const Icon(Icons.phone_rounded, size: 14),
                    label: const Text('Call Salon'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showCancelDialog(b),
                    child: Text(
                      'Cancel Booking',
                      style: TextStyle(
                        color: b.canCancel ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
