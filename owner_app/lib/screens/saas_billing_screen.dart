import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/api_service.dart';

class SaasBillingScreen extends StatefulWidget {
  const SaasBillingScreen({super.key});

  @override
  State<SaasBillingScreen> createState() => _SaasBillingScreenState();
}

class _SaasBillingScreenState extends State<SaasBillingScreen> {
  bool _isLoading = true;
  bool _isPaymentLoading = false;
  double _pendingBalance = 0.00;
  double _settledBalance = 0.00;
  String _razorpayKey = '';
  List<dynamic> _ledgerItems = [];

  // Active order details for this payment session
  String? _activeOrderId;

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchLedgerData();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Fetch ledger data from backend
  // ─────────────────────────────────────────────────────────────────────
  Future<void> _fetchLedgerData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/business/ledger'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (ApiService.authToken != null)
            'Authorization': 'Bearer ${ApiService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _pendingBalance =
                double.tryParse(data['pending_balance']?.toString() ?? '0') ??
                    0.0;
            _settledBalance =
                double.tryParse(data['settled_balance']?.toString() ?? '0') ??
                    0.0;
            _razorpayKey = data['razorpay_key'] ?? '';
            _ledgerItems = (data['data'] as List?) ?? [];
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Group Ledger Items strictly by Date (Today, Yesterday, 17 Aug 2026...)
  // ─────────────────────────────────────────────────────────────────────
  Map<String, List<dynamic>> _groupLedgerItemsByDate(List<dynamic> items) {
    final Map<String, List<dynamic>> groups = {};
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr =
        "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    for (var item in items) {
      final String rawDate =
          item['created_at']?.toString() ?? item['date']?.toString() ?? '';
      String dateKey = 'Past Transactions';

      if (rawDate.isNotEmpty) {
        try {
          final dt = DateTime.parse(rawDate).toLocal();
          final ymd =
              "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

          if (ymd == todayStr) {
            dateKey = 'Today';
          } else if (ymd == yesterdayStr) {
            dateKey = 'Yesterday';
          } else {
            final months = [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec'
            ];
            dateKey = "${dt.day} ${months[dt.month - 1]} ${dt.year}";
          }
        } catch (_) {
          if (rawDate.length >= 10) {
            dateKey = rawDate.substring(0, 10);
          }
        }
      }

      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(item);
    }
    return groups;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Step 1: Create Razorpay Order on backend, then open checkout
  // ─────────────────────────────────────────────────────────────────────
  Future<void> _initiatePayment() async {
    if (_pendingBalance <= 0 || _isPaymentLoading) return;

    setState(() => _isPaymentLoading = true);

    try {
      final orderRes = await http.post(
        Uri.parse('${ApiService.baseUrl}/business/ledger/order'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (ApiService.authToken != null)
            'Authorization': 'Bearer ${ApiService.authToken}',
        },
      );

      final orderData = jsonDecode(orderRes.body);

      if (orderRes.statusCode != 200 || orderData['success'] != true) {
        if (!mounted) return;
        _showStatusToast(
          orderData['message'] ?? 'Failed to initiate Razorpay order.',
          isError: true,
        );
        setState(() => _isPaymentLoading = false);
        return;
      }

      _activeOrderId = orderData['order_id'];

      final String rzpKey = orderData['key'] ?? _razorpayKey;
      final int amountInPaise = orderData['amount_in_paise'] ?? 0;
      final String shopName =
          orderData['business_name'] ?? 'SaaS Commission Payment';
      final String contactEmail = orderData['contact_email'] ?? '';
      final String contactPhone = orderData['contact_mobile'] ?? '9999999999';

      final options = <String, dynamic>{
        'key': rzpKey,
        'amount': amountInPaise,
        'currency': 'INR',
        'order_id': _activeOrderId,
        'name': 'Glamora SaaS',
        'description':
            'SaaS Commission Settlement – ₹${_pendingBalance.toStringAsFixed(2)}',
        'prefill': {
          'name': shopName,
          'email': contactEmail,
          'contact': contactPhone,
        },
        'theme': {
          'color': '#4F46E5',
        },
        'modal': {
          'confirm_close': true,
        },
      };

      setState(() => _isPaymentLoading = false);
      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPaymentLoading = false);
      _showStatusToast('Error initiating payment: $e', isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Step 2a: Handle SUCCESS — verify on backend and update ledger
  // ─────────────────────────────────────────────────────────────────────
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final String paymentId = response.paymentId ?? '';
    final String orderId = response.orderId ?? _activeOrderId ?? '';
    final String signature = response.signature ?? '';

    if (!mounted) return;
    setState(() => _isPaymentLoading = true);

    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/business/ledger/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (ApiService.authToken != null)
            'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode({
          'razorpay_payment_id': paymentId,
          'razorpay_order_id': orderId,
          'razorpay_signature': signature,
        }),
      );

      final data = jsonDecode(res.body);

      if (!mounted) return;
      setState(() => _isPaymentLoading = false);

      if (res.statusCode == 200 && data['success'] == true) {
        _showPaymentSuccessDialog(
            paymentId, data['message'] ?? '✅ Payment recorded and ledger settled!');
        await _fetchLedgerData();
      } else {
        _showStatusToast(
          data['message'] ?? 'Payment verification failed on server.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPaymentLoading = false);
      _showStatusToast('Network error verifying payment: $e', isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Step 2b: Handle ERROR
  // ─────────────────────────────────────────────────────────────────────
  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    final desc = response.message ?? 'Payment cancelled or failed.';
    _showStatusToast('Payment failed: $desc', isError: true);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Step 2c: Handle EXTERNAL WALLET
  // ─────────────────────────────────────────────────────────────────────
  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    _showStatusToast(
      'External wallet selected: ${response.walletName}. Complete payment in wallet.',
      isError: false,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Success Dialog
  // ─────────────────────────────────────────────────────────────────────
  void _showPaymentSuccessDialog(String paymentId, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      size: 16, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment ID: $paymentId',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'View Updated Ledger',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Download Invoice & Save to device Downloads folder directly
  // ─────────────────────────────────────────────────────────────────────
  Future<void> _downloadAndSaveInvoice(int ledgerId, String invoiceNo) async {
    try {
      final invoiceUrl =
          '${ApiService.baseUrl}/business/ledger/$ledgerId/invoice';
      final res = await http.get(
        Uri.parse(invoiceUrl),
        headers: {
          if (ApiService.authToken != null)
            'Authorization': 'Bearer ${ApiService.authToken}',
        },
      );

      if (res.statusCode == 200) {
        String? saveDirPath;

        // Target public Downloads folder on Android
        if (Platform.isAndroid) {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            saveDirPath = downloadDir.path;
          }
        }

        if (saveDirPath == null) {
          try {
            final dir = await getDownloadsDirectory();
            if (dir != null) saveDirPath = dir.path;
          } catch (_) {}
        }

        if (saveDirPath == null) {
          final docs = await getApplicationDocumentsDirectory();
          saveDirPath = docs.path;
        }

        final fileName = '$invoiceNo.html';
        final filePath = '$saveDirPath/$fileName';
        final file = File(filePath);

        await file.writeAsBytes(res.bodyBytes);

        _showStatusToast(
          '⚡ Invoice $fileName saved in Downloads folder!\nPath: $filePath',
          isError: false,
        );
      } else {
        _showStatusToast(
          'Failed to download invoice (HTTP ${res.statusCode})',
          isError: true,
        );
      }
    } catch (e) {
      _showStatusToast('Error saving invoice: $e', isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Toast Snackbar
  // ─────────────────────────────────────────────────────────────────────
  void _showStatusToast(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF059669),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: Duration(seconds: isError ? 6 : 4),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Invoice Download Preview Modal
  // ─────────────────────────────────────────────────────────────────────
  void _openInvoiceModal(int ledgerId, String title, String amount) async {
    final String invoiceNo =
        'INV-GLAMORA-${ledgerId.toString().padLeft(6, '0')}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Color(0xFF4F46E5), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tax Invoice Receipt',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        invoiceNo,
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Billing Status:',
                          style:
                              TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('SETTLED ✓',
                            style: TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Paid:',
                          style:
                              TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      Text('₹$amount',
                          style: const TextStyle(
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.w900,
                              fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _downloadAndSaveInvoice(ledgerId, invoiceNo);
                    },
                    icon: const Icon(Icons.file_download_rounded, size: 18),
                    label: const Text('Download',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final groupedLedgers = _groupLedgerItemsByDate(_ledgerItems);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('SaaS Billing & Platform Ledger'),
        backgroundColor: const Color(0xFFF8FAFC),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
            onPressed: _fetchLedgerData,
            tooltip: 'Refresh Ledger',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
            : LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final hPad = isWide ? 32.0 : 16.0;
                final isSettled = _pendingBalance <= 0;

                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                      left: hPad, right: hPad, top: 16, bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Balance Card ────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSettled
                                ? [
                                    const Color(0xFF059669),
                                    const Color(0xFF047857)
                                  ]
                                : [
                                    const Color(0xFF4F46E5),
                                    const Color(0xFF7C3AED)
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (isSettled
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF4F46E5))
                                  .withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSettled
                                  ? 'ALL CLEAR ✓ NO DUE'
                                  : 'OUTSTANDING SAAS BALANCE',
                              style: TextStyle(
                                color: isSettled
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFC7D2FE),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '₹${_pendingBalance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Flat ₹1.00/booking • Total Settled: ₹${_settledBalance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: isSettled
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF4F46E5),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: (isSettled || _isPaymentLoading)
                                    ? null
                                    : _initiatePayment,
                                icon: _isPaymentLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFF4F46E5),
                                        ),
                                      )
                                    : Icon(isSettled
                                        ? Icons.check_circle_rounded
                                        : Icons.payment_rounded),
                                label: Text(
                                  _isPaymentLoading
                                      ? 'Opening Payment Gateway...'
                                      : isSettled
                                          ? 'Fully Settled ✓'
                                          : 'Pay ₹${_pendingBalance.toStringAsFixed(2)} via Razorpay',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ─── Ledger Header ──────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ledger History',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Past 6 Months',
                              style: TextStyle(
                                color: Color(0xFF4F46E5),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ─── Grouped Ledger List ─────────────────────────
                      if (_ledgerItems.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(
                            child: Text(
                              'No ledger transactions in the past 6 months.',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ),
                        )
                      else
                        ...groupedLedgers.entries.map((entry) {
                          final dateLabel = entry.key;
                          final groupItems = entry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 📅 Date Group Section Header Badge
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 10, bottom: 10, left: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      dateLabel == 'Today'
                                          ? Icons.today_rounded
                                          : dateLabel == 'Yesterday'
                                              ? Icons.history_rounded
                                              : Icons.calendar_month_rounded,
                                      size: 16,
                                      color: const Color(0xFF4F46E5),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      dateLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF475569),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${groupItems.length}',
                                        style: const TextStyle(
                                          color: Color(0xFF334155),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Group Items
                              ...groupItems.map((item) {
                                final dynamic rawId = item['id'];
                                final int id = rawId is int
                                    ? rawId
                                    : int.tryParse(rawId?.toString() ?? '0') ??
                                        0;
                                final double amountVal = double.tryParse(
                                        item['amount']?.toString() ?? '0') ??
                                    0.0;
                                final amount = amountVal.toStringAsFixed(2);
                                final description = item['description']
                                        ?.toString() ??
                                    'Bookify Commission Fee';
                                final status =
                                    item['status']?.toString() ?? 'PENDING';
                                final isItemSettled = status == 'SETTLED';
                                final dateStr =
                                    item['created_at']?.toString() ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A)
                                            .withValues(alpha: 0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: isItemSettled
                                                  ? const Color(0xFFECFDF5)
                                                  : const Color(0xFFFFFBEB),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              isItemSettled
                                                  ? Icons.receipt_long_rounded
                                                  : Icons
                                                      .pending_actions_rounded,
                                              color: isItemSettled
                                                  ? const Color(0xFF059669)
                                                  : const Color(0xFFD97706),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  description,
                                                  style: const TextStyle(
                                                    color: Color(0xFF0F172A),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  dateStr.length >= 16
                                                      ? dateStr.substring(0, 16)
                                                      : dateStr,
                                                  style: const TextStyle(
                                                    color: Color(0xFF94A3B8),
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text('₹$amount',
                                                  style: const TextStyle(
                                                    color: Color(0xFF0F172A),
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  )),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isItemSettled
                                                      ? const Color(0xFFECFDF5)
                                                      : const Color(0xFFFFFBEB),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isItemSettled
                                                      ? 'SETTLED ✓'
                                                      : 'DUE',
                                                  style: TextStyle(
                                                    color: isItemSettled
                                                        ? const Color(0xFF059669)
                                                        : const Color(
                                                            0xFFD97706),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (isItemSettled) ...[
                                        const Divider(
                                            height: 16,
                                            color: Color(0xFFF1F5F9)),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () => _openInvoiceModal(
                                                id, description, amount),
                                            icon: const Icon(
                                                Icons.file_download_rounded,
                                                size: 16,
                                                color: Color(0xFF4F46E5)),
                                            label: const Text(
                                              'Download Invoice',
                                              style: TextStyle(
                                                color: Color(0xFF4F46E5),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                    ],
                  ),
                );
              }),
      ),
    );
  }
}
