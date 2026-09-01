import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/api_service.dart';
import '../services/remote_config.dart';
import 'home_shell.dart';
import 'register_shop_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  bool _termsAccepted = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    RemoteConfig.fetchConfig();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final bool loggedOut = prefs.getBool('user_logged_out') ?? false;
    if (loggedOut) return;

    final expiry = prefs.getInt('remember_expiry');
    final email = prefs.getString('remember_email');
    final password = prefs.getString('remember_password');

    if (expiry != null && DateTime.now().millisecondsSinceEpoch < expiry && email != null && email.isNotEmpty && password != null && password.isNotEmpty) {
      _emailController.text = email;
      _passwordController.text = password;
      _handleLogin(email: email, password: password, isAutoLogin: true);
    } else {
      prefs.remove('remember_email');
      prefs.remove('remember_password');
      prefs.remove('remember_expiry');
    }
  }

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  void _handleLogin({String? email, String? password, bool isAutoLogin = false}) async {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final secondsLeft = _lockoutUntil!.difference(DateTime.now()).inSeconds;
      setState(() {
        _errorMessage = 'Too many failed attempts. Try again in $secondsLeft seconds.';
      });
      return;
    }

    if (!_termsAccepted) {
      setState(() {
        _errorMessage = 'Please accept the Terms of Service & Privacy Policy to sign in.';
      });
      return;
    }

    final loginEmail = (email ?? _emailController.text).trim().toLowerCase();
    final loginPassword = (password ?? _passwordController.text).trim();

    if (loginEmail.isEmpty || loginPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both your email/phone and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.login(loginEmail, loginPassword);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _failedAttempts = 0;
      _lockoutUntil = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_logged_out', false);
      await prefs.setString('remember_email', loginEmail);
      await prefs.setString('remember_password', loginPassword);
      await prefs.setInt('remember_expiry', DateTime.now().add(const Duration(days: 45)).millisecondsSinceEpoch);

      ApiService.detectLocation();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else {
      if (!isAutoLogin) {
        _failedAttempts++;
        if (_failedAttempts >= 5) {
          _lockoutUntil = DateTime.now().add(const Duration(seconds: 60));
        }
      }
      final msg = (result['message'] ?? 'Login failed. Check your credentials.').toString();
      final displayMsg = (msg.toLowerCase().contains('socketexception') ||
              msg.toLowerCase().contains('clientexception') ||
              msg.toLowerCase().contains('connection timed out') ||
              msg.toLowerCase().contains('errno = 110') ||
              msg.toLowerCase().contains('network connection error'))
          ? "Couldn't reach the server. Please check your internet connection or server status."
          : msg;
      setState(() => _errorMessage = displayMsg);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showPolicyDialog(String title) {
    final String privacyText = '''
**1. Information Collection**
• We collect your business name, contact details, and location for onboarding.
• We securely store your bank details if billing/payouts are enabled.
• We monitor app usage and analytics to improve our booking algorithms.

**2. Data Security & Encryption**
• All sensitive shop data, including revenue and customer lists, is encrypted at rest using industry-standard AES-256 encryption.
• Your data is transmitted over secure SSL/TLS connections at all times.
• We strictly enforce role-based access control so unauthorized staff cannot see your financial dashboards.

**3. Third-Party Sharing**
• We DO NOT sell your shop data, customer list, or revenue metrics to any third-party advertisers.
• We may share necessary transaction data with our verified payment gateway partners strictly to process payments and payouts.
• In the event of a legal subpoena, we will comply with law enforcement agencies as required by local jurisdiction.

**4. Your Rights**
• You have the right to request a complete export of your customer data at any time.
• You can request the deletion of your account, which will permanently erase your data from our active databases within 30 days.

By using the Bookify platform, you explicitly consent to these privacy terms and our secure data handling protocols.''';

    final String termsText = '''
**1. Platform Usage & Shop Onboarding**
• By joining the Bookify Partner Network, you guarantee that all provided business details, licenses, and service menus are 100% accurate.
• You must honor all confirmed bookings made through the app. Frequent cancellations or no-shows from the shop's side may result in account suspension.
• The platform is designed strictly for salon, spa, and beauty services. Any misuse or violation of local laws will result in immediate termination.

**2. Future Monetization & Fees**
• Currently, Bookify is completely free to use for early partners!
• To sustain the platform, we reserve the right to introduce a transparent commission model or SaaS subscription fee in the future.
• We pledge to notify you at least 30 days in advance before any fees are activated. You will always have the option to opt-out.

**3. Liability & Indemnity**
• Bookify acts solely as a technological bridge between you and your clients. We are not responsible for client behavior, disputes over service quality, or direct financial losses.
• You agree to indemnify Bookify against any legal claims arising from services performed at your establishment.
• Bookify does not guarantee 100% server uptime, though we strive for 99.9% reliability. We are not liable for lost revenue due to temporary network outages.

**4. Account Termination**
• You may terminate your partnership and delete your account at any time without penalty.
• Bookify reserves the right to deactivate any partner account that receives consistent negative feedback or violates these terms.''';

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
                    const SizedBox(height: 24),
                    _buildFormattedPolicyText(title == 'Privacy Policy' ? privacyText : termsText),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildDefaultColorlessFlutterLogo() {
    return SvgPicture.string(
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 166 202">
  <path d="M100.3 0L0 100.3l30.1 30.1L160.5 0h-60.2z" fill="white" fill-opacity="0.95"/>
  <path d="M100.3 67.8L38.4 129.7l30.1 30.1 61.9-61.9h-30.1z" fill="white" fill-opacity="0.8"/>
  <path d="M68.5 159.8L100.3 191.6l60.2-60.2h-60.2l-31.8 28.4z" fill="white" fill-opacity="0.55"/>
  <path d="M100.3 131.4l28.4-28.4h60.2L128.7 163l-28.4-31.6z" fill="white" fill-opacity="0.9"/>
</svg>''',
      fit: BoxFit.contain,
    );
  }

  Widget _buildFormattedPolicyText(String text) {
    List<Widget> children = [];
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 12));
      } else if (line.startsWith('**')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            line.replaceAll('**', ''),
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A)),
          ),
        ));
      } else if (line.startsWith('•')) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF4F46E5), fontWeight: FontWeight.w900)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  line.substring(1).trim(),
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569), height: 1.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569), height: 1.5, fontWeight: FontWeight.w500),
          ),
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  // ============== NEW BUILD METHOD ==============

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // soft light gray
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ========== ANIMATED HEADER ==========
            ClipPath(
              clipper: _ElegantHeaderClipper(),
              child: Container(
                width: double.infinity,
                // Removed fixed height to prevent vertical overflows on small screens
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  left: 32,
                  right: 32,
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 60, // Large bottom padding allows the curve to draw safely
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Dynamic Server Logo or Default Colorless Flutter Logo
                    Expanded(
                      flex: 3,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: (RemoteConfig.appLogoUrl != null && RemoteConfig.appLogoUrl!.isNotEmpty)
                            ? (RemoteConfig.appLogoUrl!.toLowerCase().endsWith('.svg')
                                ? SvgPicture.network(
                                    RemoteConfig.appLogoUrl!,
                                    fit: BoxFit.contain,
                                    placeholderBuilder: (_) => _buildDefaultColorlessFlutterLogo(),
                                  )
                                : Image.network(
                                    RemoteConfig.appLogoUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => _buildDefaultColorlessFlutterLogo(),
                                  ))
                            : _buildDefaultColorlessFlutterLogo(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 7,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Welcome Back',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Sign in to continue',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
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
            const SizedBox(height: 16),

            // ========== FORM CARD ==========
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 440 : double.infinity),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimationConfiguration.staggeredList(
                    position: 0,
                    duration: const Duration(milliseconds: 600),
                    child: SlideAnimation(
                      verticalOffset: 50,
                      child: FadeInAnimation(
                        child: Card(
                          elevation: 8,
                          shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Error message with fade animation
                                if (_errorMessage != null)
                                  TweenAnimationBuilder(
                                    duration: const Duration(milliseconds: 300),
                                    tween: Tween<double>(begin: 0, end: 1),
                                    builder: (context, double opacity, child) {
                                      return Opacity(
                                        opacity: opacity,
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF2F2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFFECACA)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.error_outline_rounded,
                                                  color: Color(0xFFDC2626), size: 18),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage!,
                                                  style: GoogleFonts.inter(
                                                    color: const Color(0xFFDC2626),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 4,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                if (_errorMessage != null) const SizedBox(height: 16),

                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email or Phone',
                                    labelStyle: GoogleFonts.inter(
                                      color: const Color(0xFF4F46E5),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: const Icon(Icons.person_outline,
                                        color: Color(0xFF4F46E5)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0), width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF4F46E5), width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 16),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscure,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: GoogleFonts.inter(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: const Icon(Icons.lock_outline,
                                        color: Color(0xFF94A3B8)),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0), width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF4F46E5), width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 16),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Unified Terms & Conditions Agreement Card
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _termsAccepted
                                        ? const Color(0xFFEEF2FF)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _termsAccepted
                                          ? const Color(0xFFC7D2FE)
                                          : const Color(0xFFE2E8F0),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _termsAccepted,
                                          onChanged: (val) {
                                            setState(() {
                                              _termsAccepted = val ?? false;
                                            });
                                          },
                                          activeColor: const Color(0xFF4F46E5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF94A3B8),
                                            width: 1.5,
                                          ),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _termsAccepted = !_termsAccepted;
                                            });
                                          },
                                          child: Text(
                                            'I agree to the terms and policies',
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF334155),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Login Button with Shimmer-like animation (using SimpleAnimations)
                                Center(
                                  child: SizedBox(
                                    width: 180,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : () => _handleLogin(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4F46E5),
                                        foregroundColor: Colors.white,
                                        shape: const StadiumBorder(),
                                        elevation: 4,
                                        shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: _isLoading
                                          ? const SpinKitFadingCircle(
                                              color: Colors.white,
                                              size: 28,
                                            )
                                          : Text(
                                              'Log In',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                                letterSpacing: 0.5,
                                                height: 1.2,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Register Link
                                Center(
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const RegisterShopScreen()),
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF64748B),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        children: const [
                                          TextSpan(text: 'New Partner? '),
                                          TextSpan(
                                            text: 'Register Your Shop',
                                            style: TextStyle(
                                              color: Color(0xFF4F46E5),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Policy Links
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () => _showPolicyDialog('Privacy Policy'),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Privacy Policy',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF94A3B8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '•',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF94A3B8),
                                          fontSize: 12,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _showPolicyDialog('Terms & Conditions'),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Terms & Conditions',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF94A3B8),
                                            fontSize: 12,
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ========== ELEGANT HEADER CLIPPER ==========
class _ElegantHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width * 0.15, size.height + 20, size.width * 0.4, size.height - 10);
    path.quadraticBezierTo(size.width * 0.65, size.height - 40, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}