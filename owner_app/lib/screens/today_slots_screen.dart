import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class TodaySlotsScreen extends StatefulWidget {
  const TodaySlotsScreen({super.key});

  @override
  State<TodaySlotsScreen> createState() => _TodaySlotsScreenState();
}

class _TodaySlotsScreenState extends State<TodaySlotsScreen>
    with SingleTickerProviderStateMixin {
  static List<OwnerStaffSchedule> _cachedSchedule = [];

  List<OwnerStaffSchedule> _schedule = [];
  bool _isLoading = true;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    if (_cachedSchedule.isNotEmpty) {
      _schedule = List.from(_cachedSchedule);
      _tabController = TabController(length: _schedule.length, vsync: this);
      _isLoading = false;
    }
    _fetchSlots();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    if (_schedule.isEmpty) {
      setState(() => _isLoading = true);
    }
    var schedule = await ApiService.getTodaySlots();
    if (!mounted) return;

    if (ApiService.isStaff) {
      final staffStats = await ApiService.getStaffStats();
      final myName = staffStats['data']?['staff_name']?.toString().toLowerCase() ?? '';
      if (myName.isNotEmpty) {
        final filtered = schedule.where((s) => s.staffName.toLowerCase() == myName).toList();
        if (filtered.isNotEmpty) {
          schedule = filtered;
        }
      }
    }

    _cachedSchedule = List.from(schedule);
    _tabController?.dispose();
    _tabController = schedule.isNotEmpty
        ? TabController(length: schedule.length, vsync: this)
        : null;
    setState(() {
      _schedule = schedule;
      _isLoading = false;
    });
  }

  String _formatTime(String t) {
    if (t.isEmpty) return '';
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1].padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $suffix';
  }

  void _showBookingDetail(BuildContext context, OwnerSlotBooking booking, String slotTime) {
    final statusColor = booking.status == 'CONFIRMED'
        ? const Color(0xFF059669)
        : booking.status == 'PENDING'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF64748B);
    final statusBg = booking.status == 'CONFIRMED'
        ? const Color(0xFFECFDF5)
        : booking.status == 'PENDING'
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFF1F5F9);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF4F46E5), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking #${booking.id}',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        'Slot: ${_formatTime(slotTime)}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.person_rounded, label: 'Customer', value: booking.customerName),
            if (booking.customerPhone.isNotEmpty)
              _DetailRow(icon: Icons.phone_rounded, label: 'Phone', value: booking.customerPhone),
            if (booking.bookingType != 'IN_STUDIO')
              _DetailRow(
                icon: booking.bookingType == 'EVENT_WEDDING'
                    ? Icons.diamond_rounded
                    : Icons.home_rounded,
                label: 'Modality',
                value: booking.bookingType == 'EVENT_WEDDING'
                    ? '?? Wedding & Events'
                    : '?? At-Home / Doorstep Visit',
                valueStyle: TextStyle(
                  color: booking.bookingType == 'EVENT_WEDDING'
                      ? const Color(0xFFD97706)
                      : const Color(0xFF059669),
                  fontWeight: FontWeight.w800,
                ),
              ),
            _DetailRow(icon: Icons.spa_rounded, label: 'Service', value: booking.serviceName),
            if (booking.serviceAddress.isNotEmpty)
              _DetailRow(
                icon: Icons.location_on_rounded,
                label: 'Address',
                value: '${booking.serviceAddress}${booking.addressLandmark.isNotEmpty ? ' (${booking.addressLandmark})' : ''}',
              ),
            if (booking.occasionType.isNotEmpty)
              _DetailRow(
                icon: Icons.celebration_rounded,
                label: 'Occasion',
                value: booking.occasionType,
                valueStyle: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w700),
              ),
            _DetailRow(
              icon: Icons.access_time_rounded,
              label: 'Time',
              value: '${_formatTime(booking.startTime)}${booking.endTime != null ? ' ? ${_formatTime(booking.endTime!)}' : ''}',
            ),
            _DetailRow(
              icon: Icons.currency_rupee_rounded,
              label: 'Amount',
              value: '?${booking.amount}',
              valueStyle: const TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            if (booking.status == 'PENDING') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetCtx);
                        await ApiService.respondBooking(bookingId: booking.id, action: 'DECLINE');
                        _fetchSlots();
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetCtx);
                        await ApiService.respondBooking(bookingId: booking.id, action: 'CONFIRM');
                        _fetchSlots();
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
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

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${days[today.weekday - 1]}, ${today.day} ${months[today.month - 1]}';
    final bottomPad = MediaQuery.of(context).padding.bottom;

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
            const Text(
              "Today's Schedule",
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(dateStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
            tooltip: 'Refresh',
            onPressed: _fetchSlots,
          ),
          const SizedBox(width: 4),
        ],
        bottom: (!_isLoading && _schedule.isNotEmpty && _tabController != null)
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: const Color(0xFF4F46E5),
                indicatorWeight: 3,
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: const Color(0xFF94A3B8),
                dividerColor: const Color(0xFFE2E8F0),
                tabs: _schedule.map((s) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        s.staffName.split(' ').first,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${s.bookedCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : _schedule.isEmpty
              ? _buildEmptyState()
              : TabBarView(
                  controller: _tabController,
                  children: _schedule.map((staff) => _buildStaffTab(staff, bottomPad)).toList(),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.calendar_today_rounded, size: 44, color: Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Schedule Today',
            style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add bookable staff members to see their daily slot schedule here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchSlots,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffTab(OwnerStaffSchedule staff, double bottomPad) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryChip(label: 'Booked', count: staff.bookedCount, color: const Color(0xFF4F46E5), bgColor: const Color(0xFFEEF2FF)),
              Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
              _SummaryChip(label: 'Free', count: staff.availableCount, color: const Color(0xFF059669), bgColor: const Color(0xFFECFDF5)),
              Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
              _SummaryChip(label: 'Total', count: staff.slots.length, color: const Color(0xFF64748B), bgColor: const Color(0xFFF1F5F9)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottomPad),
            itemCount: staff.slots.length,
            itemBuilder: (_, i) {
              final slot = staff.slots[i];
              final booked = slot.isBooked;
              return GestureDetector(
                onTap: booked ? () => _showBookingDetail(context, slot.booking!, slot.time) : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: booked ? const Color(0xFF4F46E5) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: booked ? const Color(0xFF4338CA) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: booked
                        ? [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          _formatTime(slot.time),
                          style: TextStyle(
                            color: booked ? Colors.white70 : const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: booked ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      Expanded(
                        child: booked && slot.booking != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          slot.booking!.customerName,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (slot.booking!.bookingType != 'IN_STUDIO')
                                        Container(
                                          margin: const EdgeInsets.only(left: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            slot.booking!.bookingType == 'EVENT_WEDDING' ? '?? Event' : '?? Home',
                                            style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    slot.booking!.serviceName,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              )
                            : const Text('Available', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      if (booked && slot.booking != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('?${slot.booking!.amount}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 18),
                          ],
                        )
                      else
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bgColor;

  const _SummaryChip({required this.label, required this.count, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
          child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({required this.icon, required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF4F46E5), size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: valueStyle ??
                        const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
