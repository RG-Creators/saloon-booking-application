import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({super.key});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  final _nameController = TextEditingController(text: 'Royal Grooming Studio');
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  final _addressController = TextEditingController(text: 'Connaught Place Block A, New Delhi');

  bool _isLoading = true;
  bool _isSaving = false;
  bool _autoAcceptBookings = false;
  String _selectedPolicy = 'PAY_AT_SALON';
  int _cancellationBufferMinutes = 120;
  final _tokenAmountController = TextEditingController(text: '50.00');

  @override
  void initState() {
    super.initState();
    _loadProfileSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _tokenAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileSettings() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getBusinessProfile();
    if (!mounted) return;

    if (res['success'] == true && res['tenant'] != null) {
      final tenant = res['tenant'] as Map<String, dynamic>;
      final policy = tenant['booking_policy'] ?? 'PAY_AT_SALON';
      _nameController.text = tenant['business_name'] ?? 'Royal Grooming Studio';
      _phoneController.text = tenant['phone'] ?? tenant['mobile'] ?? '+91 98765 43210';
      _addressController.text = tenant['address'] ?? 'Connaught Place Block A, New Delhi';
      _cancellationBufferMinutes = (tenant['cancellation_buffer_minutes'] is int)
          ? tenant['cancellation_buffer_minutes']
          : 120;
      _tokenAmountController.text = (tenant['prebooking_token_amount'] != null)
          ? tenant['prebooking_token_amount'].toString()
          : '50.00';

      setState(() {
        _selectedPolicy = policy;
        _autoAcceptBookings = (policy == 'AUTO_ACCEPT');
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final tokenAmt = double.tryParse(_tokenAmountController.text) ?? 50.00;

    final policyToSave = _autoAcceptBookings ? 'AUTO_ACCEPT' : _selectedPolicy;

    final res = await ApiService.updateBookingPolicy(
      bookingPolicy: policyToSave,
      cancellationBufferMinutes: _cancellationBufferMinutes,
      prebookingTokenAmount: tokenAmt,
      consecutiveDeclinesLimit: 3,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    final success = res['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Shop booking rules & cancellation policies saved successfully!'
              : (res['message'] ?? 'Failed to update settings. Please try again.'),
        ),
        backgroundColor: success ? const Color(0xFF059669) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _requestAccountDeletionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Compact Top Icon Header
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFFDC2626), size: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  'Account Closure & Data Erasure',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review mandatory platform conditions before requesting account deletion.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),

                // Policy Compact Cards
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildPolicyRow(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'SaaS Dues Clearance',
                        subtitle: 'Zero unpaid balance required prior to closure.',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Divider(color: Color(0xFFE2E8F0), height: 1),
                      ),
                      _buildPolicyRow(
                        icon: Icons.calendar_month_outlined,
                        title: '30-Day Tenure Rule',
                        subtitle: 'Shop must be active for at least 30 days.',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Divider(color: Color(0xFFE2E8F0), height: 1),
                      ),
                      _buildPolicyRow(
                        icon: Icons.hourglass_top_rounded,
                        title: '15-Day Grace Suspension',
                        subtitle: '15-day suspension phase before permanent purge.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Keep Account',
                              style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            _processAccountDeletionRequest();
                          },
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Submit Request',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
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
        ),
      ),
    );
  }

  Widget _buildPolicyRow({required IconData icon, required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), height: 1.2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _processAccountDeletionRequest() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
    );

    final res = await ApiService.requestAccountDeletion();
    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (res['success'] == true) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Account Suspended for Deletion',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    res['message'] ?? 'Account suspended for 15 days prior to permanent deletion.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Understand', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      final isDues = res['due_blocked'] == true;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDues ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDues ? Icons.gavel_rounded : Icons.block_rounded,
                      color: isDues ? const Color(0xFFD97706) : const Color(0xFFDC2626),
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isDues ? 'Outstanding Dues Notice' : 'Request Blocked',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    res['message'] ?? 'Unable to process deletion request.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDues ? const Color(0xFFD97706) : const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        isDues ? 'Acknowledge Dues Notice' : 'Understand',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Shop Profile & Settings', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: const Color(0xFFF8FAFC),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Disabled Business Information Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Business Information',
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFF64748B)),
                              SizedBox(width: 4),
                              Text('Read-Only', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      enabled: false,
                      maxLines: null,
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Shop / Salon Name',
                        prefixIcon: Icon(Icons.business_rounded, color: Color(0xFF94A3B8)),
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      enabled: false,
                      maxLines: null,
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_rounded, color: Color(0xFF94A3B8)),
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      enabled: false,
                      maxLines: null,
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Branch Address',
                        prefixIcon: Icon(Icons.location_on_rounded, color: Color(0xFF94A3B8)),
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Booking Controls & Policy Rules Section
                    Text('Booking Rules & Cancellation Policies', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Auto-Accept Toggle
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Auto-Accept Incoming Bookings', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              _autoAcceptBookings
                                  ? 'ON: Instant auto-confirmation without manual popup'
                                  : 'OFF: Requires manual Accept / Decline / Reschedule modal',
                              style: TextStyle(
                                color: _autoAcceptBookings ? const Color(0xFF059669) : const Color(0xFFD97706),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            value: _autoAcceptBookings,
                            activeTrackColor: const Color(0xFF059669),
                            onChanged: (val) => setState(() => _autoAcceptBookings = val),
                          ),
                          const Divider(color: Color(0xFFE2E8F0), height: 20),

                          // 2. Booking Payment Policy Dropdown
                          const Text('Customer Payment Requirement', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedPolicy,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'PAY_AT_SALON', child: Text('💵 Pay at Salon (Standard)', overflow: TextOverflow.ellipsis, maxLines: 1)),
                              DropdownMenuItem(value: 'PREPAYMENT_REQUIRED_ALL', child: Text('💳 Full Advance Prepayment Required', overflow: TextOverflow.ellipsis, maxLines: 1)),
                              DropdownMenuItem(value: 'PREBOOKING_TOKEN_FEE', child: Text('🎟️ Partial Pre-Booking Token Fee', overflow: TextOverflow.ellipsis, maxLines: 1)),
                              DropdownMenuItem(value: 'CRM_EXEMPT_PREPAYMENT', child: Text('⭐ CRM VIP Direct (Non-CRM Prepay)', overflow: TextOverflow.ellipsis, maxLines: 1)),
                            ],
                            onChanged: (val) => setState(() => _selectedPolicy = val ?? 'PAY_AT_SALON'),
                          ),

                          // Token Amount field if token fee selected
                          if (_selectedPolicy == 'PREBOOKING_TOKEN_FEE') ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _tokenAmountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Pre-Booking Token Amount (₹)',
                                prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],

                          const Divider(color: Color(0xFFE2E8F0), height: 20),

                          // 3. Customer Cancellation Window Cutoff
                          const Text('Customer Self-Cancellation Cutoff', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Customers can cancel up until this timeframe before appointment time.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: _cancellationBufferMinutes,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                            items: const [
                              DropdownMenuItem(value: 15, child: Text('⚡ Up to 15 Minutes before slot', overflow: TextOverflow.ellipsis, maxLines: 1)),
                              DropdownMenuItem(value: 60, child: Text('🕒 Up to 1 Hour before slot', overflow: TextOverflow.ellipsis, maxLines: 1)),
                              DropdownMenuItem(value: 120, child: Text('⏰ Up to 2 Hours before slot (Standard)', overflow: TextOverflow.ellipsis, maxLines: 1)),
                              DropdownMenuItem(value: 240, child: Text('⏳ Up to 4 Hours before slot', overflow: TextOverflow.ellipsis, maxLines: 1)),
                              DropdownMenuItem(value: 1440, child: Text('📅 Up to 24 Hours (1 Day) before slot', overflow: TextOverflow.ellipsis, maxLines: 1)),
                            ],
                            onChanged: (val) => setState(() => _cancellationBufferMinutes = val ?? 120),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Profile Settings Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save Profile Settings',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Request Account & Data Deletion Danger Zone
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Danger Zone: Account & Data Deletion',
                                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFFDC2626), fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Request permanent deletion of your shop account and all customer booking records. Subject to SaaS dues clearance & 15-day suspension policy.',
                            style: GoogleFonts.inter(color: const Color(0xFF7F1D1D), fontSize: 11, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _requestAccountDeletionDialog,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.warning_amber_rounded, size: 20),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Request Account & Data Deletion',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                              ),
                            ),
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
