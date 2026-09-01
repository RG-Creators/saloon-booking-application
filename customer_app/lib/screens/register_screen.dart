import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'customer_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _termsAccepted = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      setState(() {
        _errorMessage = 'Please accept the Terms of Service & Privacy Policy to register.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CustomerShell()),
        (route) => false,
      );
    } else {
      final msg = (result['message'] ?? 'Registration failed').toString();
      final displayMsg = (msg.toLowerCase().contains('socketexception') ||
              msg.toLowerCase().contains('clientexception') ||
              msg.toLowerCase().contains('connection timed out') ||
              msg.toLowerCase().contains('errno = 110') ||
              msg.toLowerCase().contains('network connection error'))
          ? "Couldn't reach the server. Please check your internet connection or server status."
          : msg;

      setState(() => _errorMessage = displayMsg);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMsg),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showPolicyDialog(String title) {
    const String privacyText = '''
**1. Information We Collect**
• **Account Details**: Your name, email address, and mobile number for authentication, notifications, and booking confirmations.
• **Location & Doorstep Address**: When you request GPS discovery or book At-Home / Doorstep services, we securely record your designated service location.
• **Booking History**: Time slots, selected salon stylists, combos, and status updates to manage your appointment lifecycle.

**2. Data Security & Encryption**
• All customer data is transmitted over secure SSL/TLS channels and encrypted at rest using industry-standard AES-256 encryption.
• Your financial transaction credentials are processed exclusively via PCI-DSS compliant payment gateways; Bookify never stores full credit/debit card numbers.
• Access to customer records is restricted through multi-tenant role-based safeguards.

**3. Sharing & Privacy Guarantees**
• We **NEVER** sell or lease your personal information, booking habits, or contact lists to third-party advertisers.
• Partner salons only receive details strictly necessary to fulfill your appointment (name, phone, booked service, and doorstep address if applicable).

**4. Your Privacy Rights**
• You have the right to review, update, or request the permanent deletion of your customer account at any time.
• You can manage your push notification preferences directly in the app settings.

By using Bookify, you consent to our data collection and privacy practices as described herein.''';

    const String termsText = '''
**1. Booking & Salon Appointments**
• By booking a service through Bookify, you agree to honor your scheduled time slot and arrive at the salon punctually.
• For Doorstep and Bridal/Event bookings, ensure a safe, clean, and accessible environment for the visiting beauty specialist.

**2. Cancellations & Policy Cutoffs**
• Each salon partner defines their own cancellation cutoff buffer (e.g., up to 15 minutes, 1 hour, or 2 hours prior to the slot).
• Self-cancellations within the allowed buffer instantly release the time slot. Cancellations requested after the cutoff timeframe are subject to salon approval.

**3. Fair Usage & 3-Strike Rule**
• To safeguard salon specialists from phantom bookings, repeated unexcused decline/no-show strikes (3 consecutive declines) may restrict automated instant bookings with that specific salon partner.

**4. Code of Conduct & Respect**
• Bookify upholds a strict zero-tolerance policy against harassment, abuse, or discrimination toward beauty professionals and salon staff. Violations will result in immediate permanent account termination.

**5. Service Quality & Disputes**
• Service execution is performed directly by the independent salon or stylist. While Bookify assists in dispute resolution, salons remain responsible for service quality.''';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              height: 5,
              width: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    title == 'Privacy Policy' ? Icons.privacy_tip_rounded : Icons.gavel_rounded,
                    color: const Color(0xFF4F46E5),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE2E8F0), thickness: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Updated: August 2026',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    _buildFormattedPolicyText(title == 'Privacy Policy' ? privacyText : termsText),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedPolicyText(String text) {
    final List<Widget> children = [];
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 10));
      } else if (line.startsWith('**')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            line.replaceAll('**', ''),
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF0F172A)),
          ),
        ));
      } else if (line.startsWith('•')) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF4F46E5), fontWeight: FontWeight.w900)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  line.substring(1).trim(),
                  style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF475569), height: 1.45, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            line,
            style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF475569), height: 1.45, fontWeight: FontWeight.w500),
          ),
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTall = constraints.maxHeight > 700;
            final isWide = constraints.maxWidth > 500;

            return Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 20,
                  vertical: isTall ? 20 : 12,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isTall ? 26 : 22,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Join Bookify to schedule appointments with top salons & stylists',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: isTall ? 24 : 16),

                        // Error Banner (if any)
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFB91C1C),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        Container(
                          padding: EdgeInsets.all(isWide ? 26 : 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Full Name
                              TextFormField(
                                controller: _nameController,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Enter your full name' : null,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Mobile Number
                              TextFormField(
                                controller: _mobileController,
                                keyboardType: TextInputType.phone,
                                validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid 10-digit mobile' : null,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  labelText: 'Mobile Number',
                                  labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                                  prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF94A3B8)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                                  prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Color(0xFF94A3B8)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF94A3B8)),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Terms & Conditions Acceptance Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: _termsAccepted,
                                      activeColor: const Color(0xFF4F46E5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                      onChanged: (val) => setState(() => _termsAccepted = val ?? false),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text('I accept the ', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12)),
                                        GestureDetector(
                                          onTap: () => _showPolicyDialog('Terms of Service'),
                                          child: Text(
                                            'Terms of Service',
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF4F46E5),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                        Text(' & ', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12)),
                                        GestureDetector(
                                          onTap: () => _showPolicyDialog('Privacy Policy'),
                                          child: Text(
                                            'Privacy Policy',
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF4F46E5),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text('Create Account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

