import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'manage_services_screen.dart';
import 'manage_combos_screen.dart';
import 'manage_staff_screen.dart';
import 'manage_hours_screen.dart';
import 'manage_branches_screen.dart';
import 'today_slots_screen.dart';
import 'login_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  OwnerTenant? _tenant;
  List<OwnerService> _services = [];
  bool _isLoading = true;
  bool _isOnline = true;
  bool _isTogglingOnline = false;
  Map<String, dynamic> _stats = {
    'today_revenue': '0.00',
    'today_bookings_count': 0,
    'active_stylists_count': 0,
    'fee_balance': '0.00',
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() async {
    _tenant ??= OwnerTenant(
      id: 1,
      businessName: 'Royal Grooming Studio',
      businessType: 'Grooming Studio',
      status: 'VERIFIED',
      bookingPolicy: 'PAY_AT_SALON',
      phone: '+91 98765 43210',
      address: 'MG Road, Sector 14, City Center',
      cancellationPolicy: 'Free cancellation up to 2 hours before slot',
    );

    try {
      final results = await Future.wait([
        ApiService.getBusinessProfile(),
        ApiService.getServices(),
        ApiService.getDashboardStats(),
      ]).timeout(const Duration(seconds: 4));

      final profile = results[0] as Map<String, dynamic>;
      final services = results[1] as List<OwnerService>;
      final statsRes = results[2] as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        if (profile['success'] == true && profile['tenant'] != null) {
          final tMap = profile['tenant'];
          _tenant = OwnerTenant.fromJson(Map<String, dynamic>.from(tMap));
          if (!_isTogglingOnline) {
            _isOnline = (_tenant!.status != 'EMERGENCY_CLOSED' && _tenant!.status != 'OFFLINE' && _tenant!.status != 'SUSPENDED_FOR_DELETION');
          }
        }
        _services = services;
        if (statsRes['success'] == true && statsRes['data'] != null) {
          _stats = Map<String, dynamic>.from(statsRes['data']);
        }
      });
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    } finally {
      if (mounted) {
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
      _loadDashboardData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(_tenant?.businessName ?? 'Bookify Partner'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Partner Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isOnline
                            ? [const Color(0xFF4F46E5), const Color(0xFF0284C7), const Color(0xFF10B981)]
                            : [const Color(0xFF334155), const Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (_isOnline ? const Color(0xFF0284C7) : const Color(0xFF1E293B)).withValues(alpha: 0.38),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BOOKIFY PARTNER NETWORK',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _tenant?.businessName ?? 'Royal Grooming Studio',
                                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isOnline
                                        ? 'Type: ${_tenant?.businessType ?? 'Grooming Studio'} • ONLINE'
                                        : 'Type: ${_tenant?.businessType ?? 'Grooming Studio'} • OFFLINE',
                                    style: TextStyle(
                                      color: _isOnline ? Colors.white70 : const Color(0xFFFECACA),
                                      fontSize: 11,
                                      fontWeight: _isOnline ? FontWeight.normal : FontWeight.w600,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.visible,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isTogglingOnline ? null : () => _handleToggleOnline(!_isOnline),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _isOnline
                                          ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                          : const Color(0xFFEF4444).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _isOnline
                                            ? const Color(0xFF34D399).withValues(alpha: 0.7)
                                            : const Color(0xFFF87171).withValues(alpha: 0.7),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isTogglingOnline)
                                          const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        else
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: _isOnline ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isOnline ? 'ONLINE' : 'OFFLINE',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          height: 16,
                                          width: 28,
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: Switch(
                                              value: _isOnline,
                                              activeColor: const Color(0xFF10B981),
                                              activeTrackColor: Colors.white38,
                                              inactiveThumbColor: const Color(0xFF94A3B8),
                                              inactiveTrackColor: Colors.black38,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              onChanged: _isTogglingOnline ? null : _handleToggleOnline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Business Overview',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Today Revenue', '₹${_stats['today_revenue'] ?? '0.00'}', Icons.currency_rupee, const Color(0xFF10B981))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Today Bookings', '${_stats['today_bookings_count'] ?? 0}', Icons.schedule, Colors.amber)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Active Stylists', '${_stats['active_stylists_count'] ?? 0}', Icons.group, Colors.purple)),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()), // Empty spacer for alignment
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Action Hub
                  const Text(
                    'Partner Management Hub',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    children: [
                      _buildNavCard('Services Menu', Icons.content_cut, Colors.blueAccent, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageServicesScreen()));
                      }),
                      _buildNavCard('Combos & Deals', Icons.layers, Colors.amber, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCombosScreen()));
                      }),
                      _buildNavCard('Staff Stylists', Icons.badge, Colors.purpleAccent, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageStaffScreen()));
                      }),
                      _buildNavCard('Business Hours', Icons.access_time_filled, Colors.tealAccent, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageHoursScreen()));
                      }),
                      _buildNavCard("Today's Schedule", Icons.calendar_today_rounded, Colors.greenAccent, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TodaySlotsScreen()));
                      }),
                      _buildNavCard('Branch Locations', Icons.store_rounded, Colors.orangeAccent, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageBranchesScreen()));
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Active Services List',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _services.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No custom services configured.', style: TextStyle(color: Color(0xFF94A3B8)))))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final s = _services[index];
                            return Card(
                              color: const Color(0xFF1E293B),
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF334155),
                                  child: Icon(Icons.content_cut, color: Colors.blueAccent, size: 20),
                                ),
                                title: Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text('${s.durationMinutes} mins • ${s.category}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                trailing: Text('₹${s.price.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
