import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'my_bookings_screen.dart';

class BookingCheckoutScreen extends StatefulWidget {
  final SalonBranch branch;
  final ServiceItem service;
  final String initialModality;

  const BookingCheckoutScreen({
    super.key,
    required this.branch,
    required this.service,
    this.initialModality = 'IN_STUDIO',
  });

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  late String _bookingType; // IN_STUDIO, AT_HOME, EVENT_WEDDING
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  Staff? _selectedStaff;
  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isLocking = false;
  String? _errorMessage;

  // At-Home / Event Form Controllers
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  String _occasionType = 'Personal / Regular';

  final List<String> _occasions = [
    'Personal / Regular',
    '?? Wedding / Bridal',
    '?? Party / Reception',
    '?? Photoshoot / Media',
    '? Festival & Special Event',
  ];

  @override
  void initState() {
    super.initState();
    _bookingType = widget.initialModality;
    if (_bookingType == 'AT_HOME') {
      _addressController.text = 'Flat 402, Green Valley Apartments, Central';
    }
    if (widget.branch.staff.isNotEmpty) {
      _selectedStaff = widget.branch.staff.first;
    }
    _fetchSlots();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTime = null;
    });

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final slots = await ApiService.getAvailableSlots(
      branchId: widget.branch.id,
      serviceId: widget.service.id,
      date: dateStr,
      staffId: _selectedStaff?.id,
    );

    if (!mounted) return;

    // If slots empty, provide default mock business hours slots for demo
    final effectiveSlots = slots.isNotEmpty ? slots : [
      '10:00', '10:30', '11:00', '11:30', '12:00', '14:00', '14:30', '15:00', '16:00', '17:00', '18:00'
    ];

    setState(() {
      _availableSlots = effectiveSlots;
      _isLoadingSlots = false;
      if (_availableSlots.isNotEmpty) {
        _selectedTime = _availableSlots.first;
      }
    });
  }

  double get _travelFee {
    if (_bookingType == 'AT_HOME') {
      return widget.branch.features.homeServiceTravelFee;
    }
    if (_bookingType == 'EVENT_WEDDING') {
      return 200.0;
    }
    return 0.0;
  }

  double get _totalPrice => widget.service.price + _travelFee;

  void _handleConfirmBooking() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an appointment time slot.')),
      );
      return;
    }

    if (_bookingType == 'AT_HOME' && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your doorstep service address.')),
      );
      return;
    }

    setState(() {
      _isLocking = true;
      _errorMessage = null;
    });

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final staffId = _selectedStaff?.id ?? (widget.branch.staff.isNotEmpty ? widget.branch.staff.first.id : 1);

    // 1. Lock slot atomically (5-minute pessimistic DB lock)
    final lockResult = await ApiService.lockSlot(
      branchId: widget.branch.id,
      serviceId: widget.service.id,
      staffId: staffId,
      date: dateStr,
      time: _selectedTime!,
      bookingType: _bookingType,
      serviceAddress: _addressController.text.trim(),
      addressLandmark: _landmarkController.text.trim(),
      occasionType: _occasionType,
      travelFee: _travelFee,
    );

    if (lockResult['success'] == true) {
      final bookingId = lockResult['booking_id'] as int;

      // 2. Confirm booking
      final confirmResult = await ApiService.confirmBooking(bookingId);

      if (!mounted) return;
      setState(() => _isLocking = false);

      if (confirmResult['success'] == true) {
        _showSuccessDialog(bookingId);
      } else {
        setState(() => _errorMessage = confirmResult['message'] ?? 'Booking confirmation failed.');
      }
    } else {
      if (!mounted) return;
      setState(() {
        _isLocking = false;
        _errorMessage = lockResult['message'] ?? 'Slot reservation failed.';
      });
    }
  }

  void _showSuccessDialog(int bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 48),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Appointment Confirmed! ??',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking #$bookingId for ${widget.service.name} has been placed with ${widget.branch.businessName} on ${DateFormat('EEE, MMM d').format(_selectedDate)} at ${_formatSlotTime(_selectedTime!)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                    '?${_totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF4F46E5)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('View My Bookings', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSlotTime(String t) {
    try {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = parts[1];
      final suffix = h >= 12 ? 'PM' : 'AM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return '$h12:$m $suffix';
    } catch (_) {
      return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = widget.branch.features;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Booking Checkout', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: const Color(0xFFF8FAFC),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(Icons.spa_rounded, color: Color(0xFF4F46E5), size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service.name,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.branch.businessName} � ${widget.service.durationMinutes} mins',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '?${widget.service.price.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF4F46E5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Modality Selection
            Text('Appointment Modality', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF0F172A))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildModalityButton('IN_STUDIO', '?? In-Studio', 'Salon Visit'),
                ),
                if (features.homeServiceEnabled) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModalityButton('AT_HOME', '?? Doorstep', '+?${features.homeServiceTravelFee.toStringAsFixed(0)} fee'),
                  ),
                ],
                if (features.eventWeddingEnabled) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModalityButton('EVENT_WEDDING', '?? Wedding', 'Event Service'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Doorstep Address fields (if At-Home or Wedding)
            if (_bookingType != 'IN_STUDIO') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _bookingType == 'EVENT_WEDDING' ? '?? Wedding & Venue Location' : '?? Doorstep Service Address',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Complete Address',
                        prefixIcon: const Icon(Icons.home_outlined, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _landmarkController,
                      decoration: InputDecoration(
                        labelText: 'Landmark / Building Name (Optional)',
                        prefixIcon: const Icon(Icons.near_me_outlined, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                    if (_bookingType == 'EVENT_WEDDING') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _occasionType,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Occasion Type',
                          prefixIcon: const Icon(Icons.celebration_outlined, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: _occasions.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 1))).toList(),
                        onChanged: (v) => setState(() => _occasionType = v!),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Date Selector (7 Days)
            Text('Select Date', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF0F172A))),
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final date = DateTime.now().add(Duration(days: i));
                  final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(_selectedDate);
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = date);
                      _fetchSlots();
                    },
                    child: Container(
                      width: 58,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                        boxShadow: isSelected
                            ? [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE').format(date).toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white70 : const Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d').format(date),
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Time Slots Grid
            Text('Available Time Slots', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF0F172A))),
            const SizedBox(height: 10),
            _isLoadingSlots
                ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF4F46E5))))
                : _availableSlots.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: const Center(child: Text('No slots available on this date. Please pick another date.')),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableSlots.map((time) {
                          final isSelected = _selectedTime == time;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedTime = time),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                _formatSlotTime(time),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
            const SizedBox(height: 24),

            // Error Banner
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Bill Breakdown & Policy
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price Breakdown', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.service.name, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Text('?${widget.service.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                  if (_travelFee > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Doorstep Travel / Setup Fee', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        Text('?${_travelFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ],
                  const Divider(color: Color(0xFFF1F5F9), height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Payable', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text('?${_totalPrice.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF4F46E5))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            features.cancellationBufferMinutes >= 60
                                ? 'Free cancellation up to ${(features.cancellationBufferMinutes / 60).toStringAsFixed(0)} hr(s) before slot.'
                                : 'Free cancellation up to ${features.cancellationBufferMinutes} mins before slot.',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLocking ? null : _handleConfirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLocking
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        features.bookingPolicy == 'PREBOOKING_TOKEN_FEE'
                            ? 'Pay Token ?${features.prebookingTokenAmount.toStringAsFixed(0)} & Lock Slot'
                            : features.bookingPolicy == 'PREPAYMENT_REQUIRED_ALL'
                                ? 'Pay ?${_totalPrice.toStringAsFixed(0)} & Confirm Slot'
                                : 'Lock & Confirm Appointment',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalityButton(String type, String title, String subtitle) {
    final isSelected = _bookingType == type;
    return GestureDetector(
      onTap: () => setState(() => _bookingType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
