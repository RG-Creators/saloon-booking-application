import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'booking_checkout_screen.dart';

class SalonDetailsScreen extends StatefulWidget {
  final SalonBranch branch;

  const SalonDetailsScreen({super.key, required this.branch});

  @override
  State<SalonDetailsScreen> createState() => _SalonDetailsScreenState();
}

class _SalonDetailsScreenState extends State<SalonDetailsScreen> {
  late SalonBranch _salon;
  bool _isLoading = true;
  String _selectedModality = 'ALL'; // ALL, IN_STUDIO, AT_HOME, EVENT_WEDDING

  @override
  void initState() {
    super.initState();
    _salon = widget.branch;
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    setState(() => _isLoading = true);
    final details = await ApiService.getShopDetails(_salon.id);
    if (!mounted) return;

    if (details != null) {
      _salon = details;
    }
    setState(() => _isLoading = false);
  }

  void _callSalon() async {
    final phone = _salon.contactMobile;
    if (phone != null && phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  void _showHoursModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_rounded, color: Color(0xFF4F46E5), size: 22),
                const SizedBox(width: 10),
                Text('Weekly Working Hours', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17)),
              ],
            ),
            const SizedBox(height: 16),
            ..._salon.workingHours.map((wh) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(wh.dayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A))),
                  wh.isOpen && wh.openTime != null && wh.closeTime != null
                      ? Text(
                          '${wh.openTime} - ${wh.closeTime}',
                          style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700, fontSize: 13),
                        )
                      : const Text('Closed', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  List<ServiceItem> get _filteredServices {
    if (_selectedModality == 'ALL') return _salon.services;
    if (_selectedModality == 'IN_STUDIO') {
      return _salon.services.where((s) => s.serviceType == 'IN_STUDIO' || s.serviceType == 'ANY').toList();
    }
    if (_selectedModality == 'AT_HOME') {
      return _salon.services.where((s) => s.serviceType == 'AT_HOME' || s.serviceType == 'ANY' || _salon.features.homeServiceEnabled).toList();
    }
    if (_selectedModality == 'EVENT_WEDDING') {
      return _salon.services.where((s) => s.serviceType == 'EVENT_WEDDING' || s.serviceType == 'ANY' || _salon.features.eventWeddingEnabled).toList();
    }
    return _salon.services;
  }

  @override
  Widget build(BuildContext context) {
    final status = _salon.status;
    final features = _salon.features;
    final services = _filteredServices;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Hero Sliver AppBar
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3730A3), Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _salon.businessName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_salon.businessType} � ${_salon.city}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (_salon.contactMobile != null)
                IconButton(
                  icon: const Icon(Icons.phone_rounded, color: Colors.white),
                  onPressed: _callSalon,
                ),
            ],
          ),

          // Salon Info Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Location Row Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: status.statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 7, height: 7, decoration: BoxDecoration(color: status.statusColor, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text(
                                    status.statusLabel,
                                    style: TextStyle(color: status.statusColor, fontWeight: FontWeight.w800, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _showHoursModal,
                              child: const Row(
                                children: [
                                  Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF4F46E5)),
                                  SizedBox(width: 4),
                                  Text('View Hours', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_salon.address}, ${_salon.city}${_salon.pinCode != null ? ' - ${_salon.pinCode}' : ''}',
                          style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.4),
                        ),
                        if (_salon.distanceKm != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.near_me_rounded, size: 14, color: Color(0xFF4F46E5)),
                              const SizedBox(width: 4),
                              Text(
                                '${_salon.distanceText} from your location',
                                style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Policy Rules Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFF4F46E5), size: 18),
                            const SizedBox(width: 8),
                            Text('Salon Booking & Cancellation Policy', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: const Color(0xFF312E81))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Free cancellation up to ${features.cancellationBufferMinutes >= 60 ? "${(features.cancellationBufferMinutes / 60).toStringAsFixed(0)} hour(s)" : "${features.cancellationBufferMinutes} mins"} before appointment.',
                                style: const TextStyle(color: Color(0xFF1E1B4B), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.payment_rounded, size: 14, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                features.bookingPolicy == 'PAY_AT_SALON'
                                    ? 'Payment: Pay at salon after your appointment.'
                                    : features.bookingPolicy == 'PREBOOKING_TOKEN_FEE'
                                        ? 'Token Advance: ?${features.prebookingTokenAmount.toStringAsFixed(0)} token required to reserve slot.'
                                        : features.bookingPolicy == 'CRM_EXEMPT_PREPAYMENT'
                                            ? 'Payment: Free direct booking for CRM clients (Advance for others).'
                                            : 'Payment: Online advance payment required.',
                                style: const TextStyle(color: Color(0xFF1E1B4B), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Modality Filters
                  Text('Choose Service Modality', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildModalityChip('ALL', '? All Services'),
                        const SizedBox(width: 8),
                        _buildModalityChip('IN_STUDIO', '?? In-Studio Visit'),
                        if (features.homeServiceEnabled) ...[
                          const SizedBox(width: 8),
                          _buildModalityChip('AT_HOME', '?? Doorstep Home Visit (+?${features.homeServiceTravelFee.toStringAsFixed(0)})'),
                        ],
                        if (features.eventWeddingEnabled) ...[
                          const SizedBox(width: 8),
                          _buildModalityChip('EVENT_WEDDING', '?? Bridal & Wedding Events'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Services Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Services Menu', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A))),
                      Text('${services.length} items', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Services Menu List
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF4F46E5)))),
                )
              : services.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No services available in this category.'))),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final service = services[index];
                            return _buildServiceCard(context, service);
                          },
                          childCount: services.length,
                        ),
                      ),
                    ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildModalityChip(String key, String label) {
    final isSelected = _selectedModality == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF4F46E5),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF334155),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      showCheckmark: false,
      onSelected: (val) {
        if (val) setState(() => _selectedModality = key);
      },
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceItem service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${service.durationMinutes} mins � ${service.category}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '?${service.price.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingCheckoutScreen(
                    branch: _salon,
                    service: service,
                    initialModality: _selectedModality == 'ALL' ? 'IN_STUDIO' : _selectedModality,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            child: const Text('Book Slot', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
