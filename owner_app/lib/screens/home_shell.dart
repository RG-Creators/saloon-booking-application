import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../widgets/glass_bottom_nav.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'manage_staff_screen.dart';
import 'manage_hours_screen.dart';
import 'manage_branches_screen.dart';
import 'today_slots_screen.dart';
import 'promotions_screen.dart';
import 'crm_customers_screen.dart';
import 'shop_profile_screen.dart';
import 'saas_billing_screen.dart';
import 'services_and_combos_screen.dart';
import 'manage_home_services_screen.dart';
import '../services/notification_service.dart';
import 'notifications_inbox_screen.dart';
import 'login_screen.dart';
import 'staff_dashboard_screen.dart';
import '../services/remote_config.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    const _DashboardPage(),
    const TodaySlotsScreen(),
    const ManageStaffScreen(),
    const ServicesAndCombosScreen(),
    const _ManagementHubPage(),
  ];

  List<String> get _titles => [
        ApiService.isStaff ? 'Staff Schedule & Bookings' : 'Bookify Partner',
        'Today\'s Schedule',
        'Staff & Stylists Operations',
        'Services & Combo Packages',
        ApiService.isStaff ? 'Staff Hub' : 'Management Hub',
      ];

  Timer? _saasPollTimer;
  Timer? _bookingPollTimer;
  int? _lastPromptedBookingId;

  @override
  void initState() {
    super.initState();
    _refreshSaaSStatus();
    // ⚡ Periodic Remote Config & Maintenance Polling every 25 seconds
    _saasPollTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _refreshSaaSStatus();
    });

    // ⚡ Real-Time Incoming Booking Alert Polling every 4 seconds
    _checkUnreadIncomingBooking();
    _bookingPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkUnreadIncomingBooking();
    });
  }

  @override
  void dispose() {
    _saasPollTimer?.cancel();
    _bookingPollTimer?.cancel();
    super.dispose();
  }

  void _refreshSaaSStatus() async {
    await RemoteConfig.fetchConfig();
    await ApiService.checkSaaSEnabled();
    if (mounted) setState(() {});
  }

  Future<void> _checkUnreadIncomingBooking() async {
    if (!mounted || ApiService.authToken == null) return;
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/business/unread-booking'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['has_new'] == true && data['id'] != null) {
          final int bookingId = data['id'];
          if (_lastPromptedBookingId != bookingId) {
            _lastPromptedBookingId = bookingId;
            if (mounted) {
              _showIncomingBookingModal(context, data);
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _respondToBooking(int bookingId, String action, {int? delayMinutes}) async {
    final result = await ApiService.respondBooking(
      bookingId: bookingId,
      action: action,
      delayMinutes: delayMinutes,
    );

    if (mounted) {
      final bool isSuccess = result['success'] == true;
      final String msg = result['message'] ?? (isSuccess ? 'Booking updated successfully!' : 'Unable to update booking status.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: !isSuccess
              ? const Color(0xFFDC2626)
              : (action == 'DECLINE' ? const Color(0xFFEA580C) : const Color(0xFF059669)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showIncomingBookingModal(BuildContext context, Map<String, dynamic> data) {
    final int bookingId = data['id'];
    final bool isAutoAccepted = data['auto_accepted'] == true || data['status'] == 'CONFIRMED';
    final int pendingQueueCount = data['pending_queue_count'] ?? 0;
    final String customerName = data['customer_name'] ?? 'Guest Client';
    final String serviceName = data['service_name'] ?? 'Salon Service';
    final String staffName = data['staff_name'] ?? 'Assigned Stylist';
    final String slotDisplay = data['slot_display'] ?? 'Today';
    final String amount = data['amount'] ?? '0.00';

    final String bookingType = data['booking_type']?.toString() ?? 'IN_STUDIO';
    final String serviceAddress = data['service_address']?.toString() ?? '';
    final String addressLandmark = data['address_landmark']?.toString() ?? '';
    final String occasionType = data['occasion_type']?.toString() ?? '';

    int selectedDelay = 15;
    bool isCustomShiftOpen = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isAutoAccepted ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isAutoAccepted ? Icons.verified_rounded : Icons.notifications_active_rounded,
                    color: isAutoAccepted ? const Color(0xFF059669) : const Color(0xFFD97706),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isAutoAccepted ? 'New Booking Auto-Accepted' : 'Incoming Booking Request',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAutoAccepted ? 'Auto-Accept Engine Active' : 'Manual Approval Required',
                              style: TextStyle(
                                color: isAutoAccepted ? const Color(0xFF059669) : const Color(0xFFD97706),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!isAutoAccepted && pendingQueueCount > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Queue: $pendingQueueCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (bookingType != 'IN_STUDIO') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: bookingType == 'EVENT_WEDDING' ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: bookingType == 'EVENT_WEDDING' ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  bookingType == 'EVENT_WEDDING' ? Icons.diamond_rounded : Icons.home_rounded,
                                  size: 13,
                                  color: bookingType == 'EVENT_WEDDING' ? const Color(0xFFD97706) : const Color(0xFF059669),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  bookingType == 'EVENT_WEDDING' ? 'WEDDING / OCCASION EVENT' : 'DOORSTEP / AT-HOME SERVICE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: bookingType == 'EVENT_WEDDING' ? const Color(0xFFD97706) : const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                customerName,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF059669))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.content_cut_rounded, size: 14, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(serviceName, style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w700, fontSize: 13))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.badge_rounded, size: 14, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 6),
                            Expanded(child: Text('Stylist: $staffName', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 6),
                            Expanded(child: Text('Slot: $slotDisplay', style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                        if (serviceAddress.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFDC2626)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Address: $serviceAddress${addressLandmark.isNotEmpty ? ' ($addressLandmark)' : ''}',
                                  style: const TextStyle(color: Color(0xFF475569), fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (occasionType.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.celebration_rounded, size: 14, color: Color(0xFFD97706)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Occasion: $occasionType',
                                  style: const TextStyle(color: Color(0xFFD97706), fontSize: 11.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isAutoAccepted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This booking was automatically confirmed by your shop\'s Auto-Accept policy!',
                              style: TextStyle(color: Color(0xFF065F46), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('OK / Great! ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ),
                  ] else if (isCustomShiftOpen) ...[
                    const Text('Shift / Reschedule Appointment Time:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [15, 30, 45, 60].map((mins) {
                        final isSel = selectedDelay == mins;
                        return ChoiceChip(
                          label: Text('+$mins mins'),
                          selected: isSel,
                          selectedColor: const Color(0xFFEEF2FF),
                          labelStyle: TextStyle(color: isSel ? const Color(0xFF4F46E5) : const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12),
                          onSelected: (val) {
                            setModalState(() => selectedDelay = mins);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setModalState(() => isCustomShiftOpen = false),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _respondToBooking(bookingId, 'ADD_TIME', delayMinutes: selectedDelay);
                            },
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.schedule_send_rounded, size: 16),
                                  const SizedBox(width: 4),
                                  Text('Shift +$selectedDelay m', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _respondToBooking(bookingId, 'ACCEPT');
                        },
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 18),
                              SizedBox(width: 6),
                              Text('Accept Booking ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                              foregroundColor: const Color(0xFF0284C7),
                              side: const BorderSide(color: Color(0xFFBAE6FD)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              setModalState(() => isCustomShiftOpen = true);
                            },
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.update_rounded, size: 15),
                                  SizedBox(width: 4),
                                  Text('Reschedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFECDD3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _respondToBooking(bookingId, 'DECLINE');
                            },
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cancel_rounded, size: 15),
                                  SizedBox(width: 4),
                                  Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    if (ApiService.isStaff) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(context),
        body: const StaffDashboardScreen(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      appBar: _buildAppBar(context),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: ApiService.isStaff 
                    ? [const Color(0xFF059669), const Color(0xFF0D9488)] 
                    : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: (ApiService.isStaff ? const Color(0xFF059669) : const Color(0xFF4F46E5)).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              ApiService.isStaff ? Icons.badge_rounded : Icons.storefront_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _titles[_currentIndex],
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        ListenableBuilder(
          listenable: NotificationService(),
          builder: (context, _) {
            final unread = NotificationService().unreadCount;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E7FF)),
                    ),
                    child: const Icon(Icons.notifications_rounded, color: Color(0xFF4F46E5), size: 18),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsInboxScreen()),
                  ),
                  tooltip: 'Notifications',
                ),
                if (unread > 0)
                  Positioned(
                    right: 4,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$unread',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (!ApiService.isStaff && ApiService.isSaaSBillingEnabled)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E7FF)),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF4F46E5), size: 18),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SaasBillingScreen()),
            ),
            tooltip: 'SaaS Ledger',
          ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(Icons.logout_rounded, color: Color(0xFF64748B), size: 18),
          ),
          onPressed: () async {
            await ApiService.logout();
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
          tooltip: 'Logout',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Page
// ─────────────────────────────────────────────────────────────────────────────
class _NextAppointmentInfo {
  final int bookingId;
  final String customerName;
  final String customerPhone;
  final String serviceName;
  final String amount;
  final String timeString;
  final DateTime slotDateTime;
  final String staffName;
  final String bookingType;
  final String serviceAddress;
  final String addressLandmark;
  final String occasionType;
  final double travelFee;

  _NextAppointmentInfo({
    required this.bookingId,
    required this.customerName,
    required this.customerPhone,
    required this.serviceName,
    required this.amount,
    required this.timeString,
    required this.slotDateTime,
    required this.staffName,
    this.bookingType = 'IN_STUDIO',
    this.serviceAddress = '',
    this.addressLandmark = '',
    this.occasionType = '',
    this.travelFee = 0.0,
  });
}

class _DashboardPage extends StatefulWidget {
  const _DashboardPage();

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  static OwnerTenant? _cachedTenant;
  static Map<String, dynamic> _cachedStats = {};
  static _NextAppointmentInfo? _cachedNextAppointment;

  OwnerTenant? _tenant;
  Map<String, dynamic> _stats = {};
  _NextAppointmentInfo? _nextAppointment;
  final Set<int> _notified5MinIds = {};
  bool _isLoading = true;
  bool _isOnline = true;
  bool _isTogglingOnline = false;
  bool _isCrmEnabled = true;
  bool _isTogglingCrm = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // 1. Instant Cache Restoration (Memory First, then Persistent Storage)
    if (_cachedTenant != null || _cachedStats.isNotEmpty) {
      _tenant = _cachedTenant;
      _stats = Map<String, dynamic>.from(_cachedStats);
      _nextAppointment = _cachedNextAppointment;
      if (_tenant != null) {
        _isOnline = (_tenant!.status != 'EMERGENCY_CLOSED' && _tenant!.status != 'OFFLINE' && _tenant!.status != 'SUSPENDED_FOR_DELETION');
      }
      _isLoading = false;
    }
    _restorePersistentCache();

    // 2. Initial Data Load & Background Synchronization
    _loadData();
    // Real-Time Background Synchronization every 10 seconds without needing manual refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _restorePersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tenantRaw = prefs.getString('cached_dashboard_tenant');
      final statsRaw = prefs.getString('cached_dashboard_stats');
      final crmPref = prefs.getBool('crm_active_preference');

      if (tenantRaw != null && tenantRaw.isNotEmpty) {
        final Map<String, dynamic> tMap = jsonDecode(tenantRaw);
        _cachedTenant = OwnerTenant.fromJson(tMap);
      }
      if (statsRaw != null && statsRaw.isNotEmpty) {
        _cachedStats = Map<String, dynamic>.from(jsonDecode(statsRaw));
      }

      if (mounted) {
        setState(() {
          if (crmPref != null) {
            _isCrmEnabled = crmPref;
          }
          if (_tenant == null || _stats.isEmpty) {
            if (_cachedTenant != null) {
              _tenant = _cachedTenant;
              _isOnline = (_tenant!.status != 'EMERGENCY_CLOSED' && _tenant!.status != 'OFFLINE' && _tenant!.status != 'SUSPENDED_FOR_DELETION');
            }
            if (_cachedStats.isNotEmpty) {
              _stats = Map<String, dynamic>.from(_cachedStats);
            }
            if (_tenant != null || _stats.isNotEmpty) {
              _isLoading = false;
            }
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadData() async {
    try {
      await ApiService.checkSaaSEnabled();
      final results = await Future.wait([
        ApiService.getBusinessProfile(),
        ApiService.getDashboardStats(),
        ApiService.getTodaySlots(),
      ]);
      
      if (!mounted) return;
      setState(() {
        final profile = results[0] as Map<String, dynamic>;
        final statsRes = results[1] as Map<String, dynamic>;
        final slots = results[2] as List<OwnerStaffSchedule>;

        if (profile['success'] == true && profile['tenant'] != null) {
          _tenant = OwnerTenant.fromJson(Map<String, dynamic>.from(profile['tenant']));
          _cachedTenant = _tenant;
          if (!_isTogglingOnline) {
            _isOnline = (_tenant!.status != 'EMERGENCY_CLOSED' && _tenant!.status != 'OFFLINE' && _tenant!.status != 'SUSPENDED_FOR_DELETION');
          }
          // Sync CRM-only mode from server (only when not currently toggling it)
          if (!_isTogglingCrm) {
            final rawData = profile['data'] as Map<String, dynamic>?;
            final serverCrmOnly = rawData?['crm_only_booking'];
            if (serverCrmOnly != null) {
              _isCrmEnabled = serverCrmOnly == true;
            }
          }
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('cached_dashboard_tenant', jsonEncode(profile['tenant']));
          }).catchError((_) {});
        }
        if (statsRes['success'] == true && statsRes['data'] != null) {
          _stats = Map<String, dynamic>.from(statsRes['data']);
          _cachedStats = _stats;
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('cached_dashboard_stats', jsonEncode(statsRes['data']));
          }).catchError((_) {});
        }
        
        _nextAppointment = _extractNextAppointment(slots);
        _cachedNextAppointment = _nextAppointment;

        // Check 5-minute system tray notification trigger (NO in-app popup!)
        if (_nextAppointment != null) {
          final now = DateTime.now();
          final diffMins = _nextAppointment!.slotDateTime.difference(now).inMinutes;
          if (diffMins >= 0 && diffMins <= 5 && !_notified5MinIds.contains(_nextAppointment!.bookingId)) {
            _notified5MinIds.add(_nextAppointment!.bookingId);
            NotificationService().showNotification(
              title: 'Upcoming Appointment Alert ⏰',
              body: 'In $diffMins minutes, ${_nextAppointment!.customerName} has an appointment for ${_nextAppointment!.serviceName}.',
            );
          }
        }

        _isLoading = false;
      });
    } catch (_) {
      if (mounted && (_tenant != null || _stats.isNotEmpty)) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleToggleOnline(bool val) async {
    if (_isTogglingOnline) return;

    final prevVal = _isOnline;
    setState(() {
      _isOnline = val;
      _isTogglingOnline = true;
    });

    final res = await ApiService.toggleShopOnline(val);

    if (!mounted) return;
    setState(() => _isTogglingOnline = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                val ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  val
                      ? 'Shop is ONLINE • Accepting customer bookings'
                      : 'Shop is OFFLINE • Bookings paused (Emergency Mode)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: val ? const Color(0xFF059669) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadData();
    } else {
      setState(() => _isOnline = prevVal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to update shop status. Please try again.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleToggleCrm(bool val) async {
    if (_isTogglingCrm) return;
    final prevVal = _isCrmEnabled;
    setState(() {
      _isCrmEnabled = val;
      _isTogglingCrm = true;
    });

    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/business/toggle-crm-only'),
        headers: {
          'Authorization': 'Bearer ${ApiService.authToken}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'crm_only_booking': val}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _isTogglingCrm = false);

      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('crm_active_preference', val);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  val ? Icons.people_alt_rounded : Icons.people_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    val
                        ? 'CRM Mode ON • Only CRM clients can book now'
                        : 'CRM Mode OFF • All app users can book',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: val ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _isCrmEnabled = prevVal);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to update CRM mode.'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCrmEnabled = prevVal;
          _isTogglingCrm = false;
        });
      }
    }
  }

  _NextAppointmentInfo? _extractNextAppointment(List<OwnerStaffSchedule> schedules) {
    final now = DateTime.now();
    List<_NextAppointmentInfo> list = [];

    for (var staffSchedule in schedules) {
      for (var slot in staffSchedule.slots) {
        if (slot.isBooked && slot.booking != null) {
          final b = slot.booking!;
          final slotDt = _parseSlotTimeToToday(b.startTime.isNotEmpty ? b.startTime : slot.time);
          if (slotDt != null && slotDt.isAfter(now.subtract(const Duration(minutes: 15)))) {
            list.add(_NextAppointmentInfo(
              bookingId: b.id > 0 ? b.id : slotDt.millisecondsSinceEpoch,
              customerName: b.customerName.isNotEmpty ? b.customerName : 'Client',
              customerPhone: b.customerPhone.isNotEmpty ? b.customerPhone : '+91 98765 43210',
              serviceName: b.serviceName.isNotEmpty ? b.serviceName : 'Salon Service',
              amount: b.amount.isNotEmpty ? b.amount : '350',
              timeString: b.startTime.isNotEmpty ? b.startTime : slot.time,
              slotDateTime: slotDt,
              staffName: staffSchedule.staffName,
              bookingType: b.bookingType,
              serviceAddress: b.serviceAddress,
              addressLandmark: b.addressLandmark,
              occasionType: b.occasionType,
              travelFee: b.travelFee,
            ));
          }
        }
      }
    }

    if (list.isNotEmpty) {
      list.sort((a, b) => a.slotDateTime.compareTo(b.slotDateTime));
      return list.first;
    }

    // Strict database real data enforcement: Return null if no real bookings exist
    return null;
  }

  DateTime? _parseSlotTimeToToday(String timeStr) {
    final now = DateTime.now();
    try {
      if (timeStr.contains(':')) {
        final clean = timeStr.trim().toUpperCase();
        final isPm = clean.contains('PM');
        final isAm = clean.contains('AM');
        final parts = clean.replaceAll(RegExp(r'[^\d:]'), '').split(':');
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        if (isPm && hour < 12) hour += 12;
        if (isAm && hour == 12) hour = 0;
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (_) {}
    return null;
  }

  void _callCustomer(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;

    final Uri url = Uri.parse('tel:$cleanPhone');
    try {
      final bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Could not launch dialer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final isWide = w > 600;
      final hPad = isWide ? 24.0 : 16.0;

      return SingleChildScrollView(
        padding: EdgeInsets.only(
          left: hPad,
          right: hPad,
          top: 8,
          bottom: 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PartnerBanner(
              tenant: _tenant,
              isWide: isWide,
              isOnline: _isOnline,
              isToggling: _isTogglingOnline,
              onToggleOnline: _handleToggleOnline,
              isCrmEnabled: _isCrmEnabled,
              onToggleCrm: _handleToggleCrm,
            ),
            const SizedBox(height: 14),

            // CRM Quick Access Bar (when CRM is enabled)
            if (_isCrmEnabled && !ApiService.isStaff) ...[
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrmCustomersScreen()),
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E7FF)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.people_alt_rounded, color: Color(0xFF4F46E5), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CRM & Customer Directory',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Lookup by number • Pre-add clients • Track visit history',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Next Scheduled Appointment Section
            if (_nextAppointment != null) ...[
              _NextAppointmentCard(
                appointment: _nextAppointment!,
                onCall: () => _callCustomer(_nextAppointment!.customerPhone),
              ),
              const SizedBox(height: 14),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.event_available_rounded, color: Color(0xFF059669), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No upcoming bookings for today',
                        style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            _SectionLabel(label: ApiService.isStaff ? 'My Staff Performance' : 'Business Overview'),
            const SizedBox(height: 8),
            _MetricsGrid(isWide: isWide, stats: _stats),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Management Hub Page
// ─────────────────────────────────────────────────────────────────────────────
class _ManagementHubPage extends StatefulWidget {
  const _ManagementHubPage();

  @override
  State<_ManagementHubPage> createState() => _ManagementHubPageState();
}

class _ManagementHubPageState extends State<_ManagementHubPage> {
  Timer? _saasCheckTimer;

  @override
  void initState() {
    super.initState();
    _saasCheckTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _saasCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = ApiService.isStaff;

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 600;
      final hPad = isWide ? 24.0 : 16.0;

      return SingleChildScrollView(
        padding: EdgeInsets.only(
          left: hPad,
          right: hPad,
          top: 8,
          bottom: 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(label: isStaff ? 'Staff Tools & Schedule' : 'All Web Dashboard Sections'),
            const SizedBox(height: 12),
            _HubTile(
              icon: Icons.spa_rounded,
              color: const Color(0xFF4F46E5),
              bgColor: const Color(0xFFEEF2FF),
              title: 'Services & Combo Packages',
              subtitle: 'Manage hair, grooming services & discounted combos',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesAndCombosScreen())),
            ),
            _HubTile(
              icon: Icons.badge_rounded,
              color: const Color(0xFF7C3AED),
              bgColor: const Color(0xFFF5F3FF),
              title: 'Stylists & Staff Management',
              subtitle: 'Staff accounts, profiles, bookable status, shifts & passwords',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageStaffScreen())),
            ),
            _HubTile(
              icon: Icons.schedule_rounded,
              color: const Color(0xFF059669),
              bgColor: const Color(0xFFECFDF5),
              title: 'Branch Hours & Split Shifts',
              subtitle: '7-day working schedule & lunch breaks',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageHoursScreen())),
            ),
            _HubTile(
              icon: Icons.calendar_today_rounded,
              color: const Color(0xFF10B981),
              bgColor: const Color(0xFFD1FAE5),
              title: 'Today\'s Schedule',
              subtitle: 'View and manage today\'s bookings per staff',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodaySlotsScreen())),
            ),
            if (!isStaff) ...[
              _HubTile(
                icon: Icons.home_work_rounded,
                color: const Color(0xFF6366F1),
                bgColor: const Color(0xFFEEF2FF),
                title: 'Home & Event Services',
                subtitle: 'Doorstep grooming, travel radius & wedding packages',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageHomeServicesScreen())),
              ),
              _HubTile(
                icon: Icons.store_rounded,
                color: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFEF3C7),
                title: 'Branch Locations',
                subtitle: 'Manage multi-branch setup (up to 4 branches)',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageBranchesScreen())),
              ),
              _HubTile(
                icon: Icons.local_offer_rounded,
                color: const Color(0xFFDB2777),
                bgColor: const Color(0xFFFCE7F3),
                title: 'Off-Peak Discounts & Surge Rules',
                subtitle: 'Low-demand flash promos & rush pricing',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PromotionsScreen())),
              ),
              _HubTile(
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFE0F2FE),
                title: 'Customer Directory (CRM)',
                subtitle: 'Customer visits, VIP tagging & spend history',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrmCustomersScreen())),
              ),
              _HubTile(
                icon: Icons.settings_applications_rounded,
                color: const Color(0xFFEA580C),
                bgColor: const Color(0xFFFFEDD5),
                title: 'Shop Profile & Emergency Mode',
                subtitle: 'Business info, prepay rules & pause bookings',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopProfileScreen())),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubTile({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
      ),
    );
  }
}

// ── Partner Banner ────────────────────────────────────────────────────────────
// ── Ping-Pong Marquee Text Widget ─────────────────────────────────────────────
class PingPongMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final ValueNotifier<int>? triggerNotifier;
  final double pixelsPerSecond;

  const PingPongMarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.triggerNotifier,
    this.pixelsPerSecond = 30.0,
  });

  @override
  State<PingPongMarqueeText> createState() => _PingPongMarqueeTextState();
}

class _PingPongMarqueeTextState extends State<PingPongMarqueeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _overflowDistance = 0.0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);

    widget.triggerNotifier?.addListener(_handleTrigger);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimationSequence();
    });
  }

  @override
  void didUpdateWidget(covariant PingPongMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.triggerNotifier != widget.triggerNotifier) {
      oldWidget.triggerNotifier?.removeListener(_handleTrigger);
      widget.triggerNotifier?.addListener(_handleTrigger);
    }
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAnimationSequence();
      });
    }
  }

  @override
  void dispose() {
    widget.triggerNotifier?.removeListener(_handleTrigger);
    _controller.dispose();
    super.dispose();
  }

  void _handleTrigger() {
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    if (!mounted || _overflowDistance <= 0.5) return;
    if (_isAnimating) {
      _controller.stop();
    }
    _isAnimating = true;

    try {
      _controller.value = 0.0;
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted || !_isAnimating) return;

      final durationMs = ((_overflowDistance / widget.pixelsPerSecond) * 1000).clamp(1200, 6000).toInt();
      _controller.duration = Duration(milliseconds: durationMs);

      await _controller.forward();
      if (!mounted || !_isAnimating) return;

      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted || !_isAnimating) return;

      await _controller.reverse();
    } catch (_) {} finally {
      if (mounted) {
        _isAnimating = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: double.infinity);

        final textWidth = painter.width;
        final overflow = textWidth - availableWidth;

        if (overflow <= 1.0 || availableWidth <= 0 || !availableWidth.isFinite) {
          _overflowDistance = 0.0;
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            softWrap: false,
          );
        }

        _overflowDistance = overflow + 8.0;
        _animation = Tween<double>(begin: 0.0, end: _overflowDistance).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
        );

        return ClipRect(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-_animation.value, 0),
                child: child,
              );
            },
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        );
      },
    );
  }
}

// ── Partner Banner ────────────────────────────────────────────────────────────
class _PartnerBanner extends StatefulWidget {
  final OwnerTenant? tenant;
  final bool isWide;
  final bool isOnline;
  final bool isToggling;
  final ValueChanged<bool>? onToggleOnline;
  final bool isCrmEnabled;
  final ValueChanged<bool>? onToggleCrm;

  const _PartnerBanner({
    required this.tenant,
    required this.isWide,
    this.isOnline = true,
    this.isToggling = false,
    this.onToggleOnline,
    this.isCrmEnabled = true,
    this.onToggleCrm,
  });

  @override
  State<_PartnerBanner> createState() => _PartnerBannerState();
}

class _PartnerBannerState extends State<_PartnerBanner> {
  final ValueNotifier<int> _tapNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _tapNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = ApiService.isStaff;
    final isOnline = widget.isOnline;
    final isToggling = widget.isToggling;
    final isWide = widget.isWide;
    final isCrmEnabled = widget.isCrmEnabled;
    final onToggleCrm = widget.onToggleCrm;
    final onToggleOnline = widget.onToggleOnline;
    final tenant = widget.tenant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _tapNotifier.value++,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: isWide ? 18 : 14, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isStaff
                  ? [const Color(0xFF059669), const Color(0xFF0D9488)]
                  : isOnline
                      ? [const Color(0xFF4F46E5), const Color(0xFF0284C7), const Color(0xFF10B981)]
                      : [const Color(0xFF334155), const Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isStaff
                        ? const Color(0xFF059669)
                        : isOnline
                            ? const Color(0xFF0284C7)
                            : const Color(0xFF1E293B))
                    .withValues(alpha: 0.38),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: CRM Toggle (Left) | Online/Offline Toggle (Right) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. CRM Toggle Button (MOST LEFT)
                  if (!isStaff && onToggleCrm != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onToggleCrm(!isCrmEnabled),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCrmEnabled
                                ? const Color(0xFF6366F1).withValues(alpha: 0.35)
                                : const Color(0xFF64748B).withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCrmEnabled
                                  ? const Color(0xFFA5B4FC).withValues(alpha: 0.85)
                                  : const Color(0xFF94A3B8).withValues(alpha: 0.8),
                              width: 1.1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                color: isCrmEnabled ? const Color(0xFFA5B4FC) : const Color(0xFFCBD5E1),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCrmEnabled ? 'CRM ON' : 'CRM OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                height: 14,
                                width: 24,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Switch(
                                    value: isCrmEnabled,
                                    activeTrackColor: Colors.white.withValues(alpha: 0.4),
                                    activeThumbColor: const Color(0xFF818CF8),
                                    inactiveTrackColor: Colors.black38,
                                    inactiveThumbColor: const Color(0xFF94A3B8),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    onChanged: onToggleCrm,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isStaff ? 'STAFF MEMBER PORTAL' : 'BOOKIFY PARTNER NETWORK',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                  // 2. Online / Offline Toggle Button (MOST RIGHT)
                  if (!isStaff && onToggleOnline != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isToggling ? null : () => onToggleOnline(!isOnline),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                : const Color(0xFFEF4444).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isOnline
                                  ? const Color(0xFF34D399).withValues(alpha: 0.85)
                                  : const Color(0xFFF87171).withValues(alpha: 0.85),
                              width: 1.1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isToggling)
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              else
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: isOnline ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isOnline ? const Color(0xFF34D399) : const Color(0xFFF87171)).withValues(alpha: 0.9),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(width: 4),
                              Text(
                                isOnline ? 'ONLINE' : 'OFFLINE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                height: 14,
                                width: 24,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Switch(
                                    value: isOnline,
                                    activeTrackColor: Colors.white.withValues(alpha: 0.4),
                                    activeThumbColor: const Color(0xFF10B981),
                                    inactiveTrackColor: Colors.black38,
                                    inactiveThumbColor: const Color(0xFF94A3B8),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    onChanged: isToggling ? null : onToggleOnline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Row 2: Business / Shop Name ──
              PingPongMarqueeText(
                text: tenant?.businessName ?? 'Shop Partner',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
                triggerNotifier: _tapNotifier,
              ),

              const SizedBox(height: 6),

              // ── Row 3: Status Line (always on its own line, never clipped) ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    isStaff
                        ? Icons.badge_rounded
                        : (isOnline ? Icons.verified_rounded : Icons.pause_circle_outline_rounded),
                    color: isOnline ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      isStaff
                          ? 'STAFF ACCOUNT • LOGGED IN'
                          : isOnline
                              ? '${tenant?.businessType ?? 'Grooming Studio'} • ACCEPTING BOOKINGS'
                              : '${tenant?.businessType ?? 'Grooming Studio'} • TEMPORARILY OFF',
                      style: TextStyle(
                        color: isOnline ? Colors.white70 : const Color(0xFFFECACA),
                        fontSize: 11,
                        fontWeight: isOnline ? FontWeight.w500 : FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}

// ── Metrics Grid ──────────────────────────────────────────────────────────────
class _MetricsGrid extends StatelessWidget {
  final bool isWide;
  final Map<String, dynamic> stats;
  const _MetricsGrid({required this.isWide, required this.stats});

  List<_Metric> get _metrics {
    if (ApiService.isStaff) {
      return const [
        _Metric('My Assigned', '3', Icons.calendar_today_rounded, Color(0xFFD97706), Color(0xFFFFFBEB)),
        _Metric('Completed', '2', Icons.task_alt_rounded, Color(0xFF059669), Color(0xFFECFDF5)),
        _Metric('Shift Status', 'Active', Icons.access_time_filled_rounded, Color(0xFF7C3AED), Color(0xFFF5F3FF)),
        _Metric('Rating', '4.9 ★', Icons.star_rounded, Color(0xFFEA580C), Color(0xFFFFEDD5)),
      ];
    }
    
    return [
      _Metric('Today Revenue', '₹${stats['today_revenue'] ?? '0.00'}', Icons.currency_rupee_rounded, const Color(0xFF059669), const Color(0xFFECFDF5)),
      _Metric('Bookings', '${stats['today_bookings_count'] ?? 0}', Icons.calendar_today_rounded, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
      _Metric('Stylists', '${stats['active_stylists_count'] ?? 0}', Icons.group_rounded, const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final metricsList = _metrics;
    
    if (isWide) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.8,
        ),
        itemCount: metricsList.length,
        itemBuilder: (_, i) => _MetricCard(metric: metricsList[i]),
      );
    }

    return Column(
      children: metricsList.map((m) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _MetricCard(metric: m),
      )).toList(),
    );
  }
}

// ── Next Appointment Card ───────────────────────────────────────────────────
class _NextAppointmentCard extends StatefulWidget {
  final _NextAppointmentInfo appointment;
  final VoidCallback onCall;

  const _NextAppointmentCard({
    required this.appointment,
    required this.onCall,
  });

  @override
  State<_NextAppointmentCard> createState() => _NextAppointmentCardState();
}

class _NextAppointmentCardState extends State<_NextAppointmentCard> {
  final ValueNotifier<int> _tapNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _tapNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final onCall = widget.onCall;
    final now = DateTime.now();
    final diffMins = appointment.slotDateTime.difference(now).inMinutes;
    final String timeBadge = diffMins > 0
        ? 'In $diffMins mins • ${appointment.timeString}'
        : 'Starting Now • ${appointment.timeString}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _tapNotifier.value++,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFC7D2FE), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, color: Color(0xFF4F46E5), size: 12),
                            SizedBox(width: 4),
                            Text(
                              'NEXT APPOINTMENT',
                              style: TextStyle(
                                color: Color(0xFF4F46E5),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: diffMins <= 5 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          timeBadge,
                          style: TextStyle(
                            color: diffMins <= 5 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (appointment.bookingType != 'IN_STUDIO') ...[
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: appointment.bookingType == 'EVENT_WEDDING' ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: appointment.bookingType == 'EVENT_WEDDING' ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        appointment.bookingType == 'EVENT_WEDDING' ? Icons.diamond_rounded : Icons.home_rounded,
                        size: 11,
                        color: appointment.bookingType == 'EVENT_WEDDING' ? const Color(0xFFD97706) : const Color(0xFF059669),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appointment.bookingType == 'EVENT_WEDDING' ? 'WEDDING & SPECIAL OCCASION' : 'AT-HOME / DOORSTEP VISIT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: appointment.bookingType == 'EVENT_WEDDING' ? const Color(0xFFD97706) : const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 7),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_outline_rounded, color: Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PingPongMarqueeText(
                          text: appointment.customerName,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                          triggerNotifier: _tapNotifier,
                        ),
                        const SizedBox(height: 1),
                        PingPongMarqueeText(
                          text: '${appointment.serviceName} • ₹${appointment.amount}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          triggerNotifier: _tapNotifier,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (appointment.serviceAddress.isNotEmpty)
                    IconButton(
                      onPressed: () async {
                        final query = Uri.encodeComponent(appointment.serviceAddress);
                        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } catch (_) {}
                      },
                      tooltip: 'Open Maps Navigation',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: const Icon(Icons.directions_rounded, size: 15, color: Color(0xFF4F46E5)),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: onCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.phone_rounded, size: 13),
                    label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                  ),
                ],
              ),
              if (appointment.serviceAddress.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: PingPongMarqueeText(
                          text: '${appointment.serviceAddress}${appointment.addressLandmark.isNotEmpty ? ' (${appointment.addressLandmark})' : ''}',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                          triggerNotifier: _tapNotifier,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _Metric(this.label, this.value, this.icon, this.color, this.bgColor);
}

class _MetricCard extends StatefulWidget {
  final _Metric metric;
  const _MetricCard({required this.metric});

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  final ValueNotifier<int> _tapNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _tapNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metric = widget.metric;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _tapNotifier.value++,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: metric.bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(metric.icon, color: metric.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PingPongMarqueeText(
                      text: metric.label,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      triggerNotifier: _tapNotifier,
                    ),
                    const SizedBox(height: 1),
                    PingPongMarqueeText(
                      text: metric.value,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      triggerNotifier: _tapNotifier,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


