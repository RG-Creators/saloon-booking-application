import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class CrmCustomersScreen extends StatefulWidget {
  const CrmCustomersScreen({super.key});

  @override
  State<CrmCustomersScreen> createState() => _CrmCustomersScreenState();
}

class _CrmCustomersScreenState extends State<CrmCustomersScreen> {
  List<OwnerCustomerCRM> _allCustomers = [];
  List<OwnerCustomerCRM> _filteredCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _activeFilter = 'ALL'; // ALL, VIP, BOOKED, PRE_ADDED

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getCustomers();
    if (!mounted) return;
    setState(() {
      _allCustomers = list;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    List<OwnerCustomerCRM> res = List.from(_allCustomers);

    // Apply Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      res = res.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q) ||
            c.notes.toLowerCase().contains(q);
      }).toList();
    }

    // Apply Filter Chips
    if (_activeFilter == 'VIP') {
      res = res.where((c) => c.isVip).toList();
    } else if (_activeFilter == 'BOOKED') {
      res = res.where((c) => c.totalBookings > 0).toList();
    } else if (_activeFilter == 'PRE_ADDED') {
      res = res.where((c) => c.source == 'PRE_ADDED' || c.source == 'MANUAL').toList();
    }

    setState(() {
      _filteredCustomers = res;
    });
  }

  void _callNumber(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FAB BOTTOM ACTION SHEET: SHORT TEXT & 3-BUTTON NAV SAFE
  // ─────────────────────────────────────────────────────────────────────────────
  void _showAddCustomerActionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewPadding.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Customer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Option 1: Manual Add
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddEditCustomerModal();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF4F46E5), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Manually',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'By phone lookup or new profile',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Option 2: Add from Bookings
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showUnaddedBookingsModal();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.history_edu_rounded, color: Color(0xFF059669), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add from Bookings',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Import past appointment clients',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL: ADD FROM PAST BOOKINGS (SHOWS ALL CLIENTS NOT YET IN CRM)
  // ─────────────────────────────────────────────────────────────────────────────
  void _showUnaddedBookingsModal() {
    final Set<int> selectedIndices = {};
    bool isSubmittingBatch = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: FutureBuilder<Map<String, dynamic>>(
                future: ApiService.getUnaddedBookingClients(),
                builder: (context, snapshot) {
                  final isLoading = snapshot.connectionState == ConnectionState.waiting;
                  final data = snapshot.data;
                  final List clients = (data?['data'] as List?) ?? [];

                  return Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      // Header with Close Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.history_edu_rounded, color: Color(0xFF059669), size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                clients.isNotEmpty ? 'Past Booking Clients (${clients.length})' : 'Past Booking Clients',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                            ),
                            if (clients.isNotEmpty)
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    if (selectedIndices.length == clients.length) {
                                      selectedIndices.clear();
                                    } else {
                                      selectedIndices.addAll(List.generate(clients.length, (i) => i));
                                    }
                                  });
                                },
                                child: Text(
                                  selectedIndices.length == clients.length ? 'Deselect All' : 'Select All',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // List
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                            : clients.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                                            child: const Icon(Icons.check_circle_outline_rounded, size: 36, color: Color(0xFF059669)),
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'All Past Clients are in CRM!',
                                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'There are no unadded booking customers at this moment.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                                    itemCount: clients.length,
                                    itemBuilder: (context, i) {
                                      final c = clients[i] as Map<String, dynamic>;
                                      final String name = c['name'] ?? 'Client';
                                      final String phone = c['phone'] ?? '';
                                      final String lastService = c['last_service'] ?? 'Salon Service';
                                      final int totalBookings = c['total_bookings'] ?? 1;
                                      final double totalSpent = double.tryParse(c['total_spent'].toString()) ?? 0.0;
                                      final isSelected = selectedIndices.contains(i);

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            setModalState(() {
                                              if (isSelected) {
                                                selectedIndices.remove(i);
                                              } else {
                                                selectedIndices.add(i);
                                              }
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(14),
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Checkbox(
                                                  value: isSelected,
                                                  activeColor: const Color(0xFF4F46E5),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                  onChanged: (val) {
                                                    setModalState(() {
                                                      if (val == true) {
                                                        selectedIndices.add(i);
                                                      } else {
                                                        selectedIndices.remove(i);
                                                      }
                                                    });
                                                  },
                                                ),
                                                CircleAvatar(
                                                  radius: 17,
                                                  backgroundColor: const Color(0xFFE0E7FF),
                                                  child: Text(
                                                    name.isNotEmpty ? name[0].toUpperCase() : 'C',
                                                    style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w800, fontSize: 13),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                                                      ),
                                                      const SizedBox(height: 1),
                                                      Text(
                                                        phone.isNotEmpty ? phone : 'No phone',
                                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        'Last: $lastService • $totalBookings visits • ₹${totalSpent.toStringAsFixed(0)}',
                                                        style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),

                      // Sticky Bottom Bar
                      if (clients.isNotEmpty)
                        Container(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 12,
                            bottom: MediaQuery.of(context).viewPadding.bottom + 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(top: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: (selectedIndices.isEmpty || isSubmittingBatch)
                                  ? null
                                  : () async {
                                      setModalState(() => isSubmittingBatch = true);
                                      final selectedList = selectedIndices.map((idx) => clients[idx] as Map<String, dynamic>).toList();
                                      final res = await ApiService.batchAddBookingClients(selectedList);

                                      if (!ctx.mounted) return;
                                      Navigator.pop(ctx);
                                      _fetchCustomers();

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(res['message'] ?? 'Customers added to CRM!'),
                                          backgroundColor: const Color(0xFF059669),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                              child: isSubmittingBatch
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      selectedIndices.isEmpty
                                          ? 'Select Clients to Add'
                                          : 'Add ${selectedIndices.length} Selected Client(s) to CRM',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ADD / EDIT CUSTOMER MODAL WITH LIVE PHONE LOOKUP & OVERFLOW-PROOF GENDER
  // ─────────────────────────────────────────────────────────────────────────────
  void _showAddEditCustomerModal({OwnerCustomerCRM? customer}) {
    final isEditing = customer != null;
    final phoneCtrl = TextEditingController(text: isEditing ? customer.phone : '');
    final nameCtrl = TextEditingController(text: isEditing ? customer.name : '');
    final emailCtrl = TextEditingController(text: isEditing ? customer.email : '');
    final notesCtrl = TextEditingController(text: isEditing ? customer.notes : '');
    String selectedGender = isEditing && customer.gender.isNotEmpty ? customer.gender : 'Unspecified';
    bool isVip = isEditing ? customer.isVip : false;

    bool isLookingUp = false;
    bool isSaving = false;
    Map<String, dynamic>? lookupResult;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> performLookup(String phone) async {
            final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
            if (clean.length < 7) return;

            setModalState(() => isLookingUp = true);
            final res = await ApiService.lookupCustomerByPhone(phone);
            if (!ctx.mounted) return;

            setModalState(() {
              isLookingUp = false;
              lookupResult = res;
              if (res['success'] == true && res['customer'] != null) {
                final cust = res['customer'];
                if (nameCtrl.text.isEmpty && (cust['name']?.toString().isNotEmpty ?? false)) {
                  nameCtrl.text = cust['name'];
                }
                if (emailCtrl.text.isEmpty && (cust['email']?.toString().isNotEmpty ?? false)) {
                  emailCtrl.text = cust['email'];
                }
                if (cust['is_vip'] == true) {
                  isVip = true;
                }
                if (notesCtrl.text.isEmpty && (cust['notes']?.toString().isNotEmpty ?? false)) {
                  notesCtrl.text = cust['notes'];
                }
              }
            });
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Header with Close Button
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person_add_rounded, color: Color(0xFF4F46E5), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit Customer Profile' : 'Add Customer Profile',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Phone Number Field with Lookup Button
                      const Text('Mobile Phone Number *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                              onChanged: (val) {
                                if (val.replaceAll(RegExp(r'[^\d]'), '').length == 10 && !isEditing) {
                                  performLookup(val);
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'e.g. 9876543210',
                                prefixIcon: const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF64748B)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: isLookingUp ? null : () => performLookup(phoneCtrl.text),
                            child: isLookingUp
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.search_rounded, size: 16),
                                      SizedBox(width: 4),
                                      Text('Lookup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Lookup Status Feedback Banner
                      if (lookupResult != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: lookupResult!['found'] == true ? const Color(0xFFECFDF5) : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: lookupResult!['found'] == true ? const Color(0xFFA7F3D0) : const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                lookupResult!['found'] == true ? Icons.verified_user_rounded : Icons.info_outline_rounded,
                                color: lookupResult!['found'] == true ? const Color(0xFF059669) : const Color(0xFF16A34A),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lookupResult!['found'] == true
                                      ? 'Server account found! Details auto-filled below.'
                                      : 'New client! Pre-adding will auto-link upon register.',
                                  style: TextStyle(
                                    color: lookupResult!['found'] == true ? const Color(0xFF065F46) : const Color(0xFF166534),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Customer Name Field
                      const Text('Customer Full Name *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                      const SizedBox(height: 4),
                      TextField(
                        controller: nameCtrl,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'e.g. Rahul Sharma',
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Email Field (Optional)
                      const Text('Email Address (Optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                      const SizedBox(height: 4),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'e.g. rahul@example.com',
                          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 16, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Gender Selection (Zero-Overflow Wrap Chips)
                      const Text('Gender', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: ['Unspecified', 'Male', 'Female', 'Other'].map((g) {
                          final isSel = selectedGender == g;
                          return ChoiceChip(
                            label: Text(
                              g,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                color: isSel ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                              ),
                            ),
                            selected: isSel,
                            selectedColor: const Color(0xFFEEF2FF),
                            backgroundColor: const Color(0xFFF8FAFC),
                            side: BorderSide(
                              color: isSel ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                              width: isSel ? 1.5 : 1,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            showCheckmark: false,
                            onSelected: (val) {
                              if (val) setModalState(() => selectedGender = g);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // VIP Toggle Card (Full Width & Clean)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isVip ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isVip ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star_rounded, color: isVip ? const Color(0xFFD97706) : const Color(0xFF94A3B8), size: 22),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'VIP Client Status',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isVip ? const Color(0xFF92400E) : const Color(0xFF334155),
                                      ),
                                    ),
                                    Text(
                                      isVip ? 'Priority client styling' : 'Standard client profile',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isVip ? const Color(0xFFB45309) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: isVip,
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFFD97706),
                              inactiveThumbColor: const Color(0xFF94A3B8),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (val) => setModalState(() => isVip = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Notes / Preferences Field
                      const Text('Preferences & Notes (Optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                      const SizedBox(height: 4),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'e.g. Prefers tea, sensitive skin, likes fade haircut',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final name = nameCtrl.text.trim();
                                  final phone = phoneCtrl.text.trim();
                                  if (name.isEmpty || phone.isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text('Please provide customer name and phone number.')),
                                    );
                                    return;
                                  }

                                  setModalState(() => isSaving = true);
                                  final data = {
                                    'name': name,
                                    'phone': phone,
                                    'email': emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                                    'gender': selectedGender,
                                    'notes': notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                                    'is_vip': isVip,
                                  };

                                  if (isEditing) {
                                    await ApiService.updateCustomer(customer.id, data);
                                  } else {
                                    await ApiService.createCustomer(data);
                                  }

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _fetchCustomers();
                                },
                          child: isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  isEditing ? 'Save Changes' : 'Save Customer to CRM',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                ),
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
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CUSTOMER DETAILS & HISTORY MODAL
  // ─────────────────────────────────────────────────────────────────────────────
  void _showCustomerDetailsBottomSheet(OwnerCustomerCRM customer) {
    int selectedMonths = 6;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              top: false,
              child: FutureBuilder<Map<String, dynamic>>(
                future: ApiService.getCustomerDetails(customer.id, months: selectedMonths),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final bool isDetailsLoading = snapshot.connectionState == ConnectionState.waiting;
                  final details = data?['customer'] ?? {};
                  final history = (data?['history'] as List?) ?? [];

                  return Column(
                    children: [
                      // Handle Bar
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // Header with Close
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFEEF2FF),
                              child: Text(
                                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                style: GoogleFonts.inter(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          details['name'] ?? customer.name,
                                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (details['is_vip'] == true || customer.isVip) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFFBEB),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFFDE68A)),
                                          ),
                                          child: const Text('VIP', style: TextStyle(color: Color(0xFFD97706), fontSize: 9.5, fontWeight: FontWeight.w800)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    details['mobile'] ?? customer.phone,
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.phone_rounded, color: Color(0xFF059669), size: 16),
                              ),
                              onPressed: () => _callNumber(details['mobile'] ?? customer.phone),
                              tooltip: 'Call',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Time Filters
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                        child: Row(
                          children: [
                            const Text('Filter: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                            const SizedBox(width: 6),
                            Wrap(
                              spacing: 6,
                              children: [3, 6, 12].map((m) {
                                final isSel = selectedMonths == m;
                                return ChoiceChip(
                                  label: Text('$m Months', style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: isSel ? const Color(0xFF4F46E5) : const Color(0xFF64748B))),
                                  selected: isSel,
                                  selectedColor: const Color(0xFFEEF2FF),
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: isSel ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  showCheckmark: false,
                                  onSelected: (val) {
                                    if (val) setSheetState(() => selectedMonths = m);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      // Content Body
                      Expanded(
                        child: isDetailsLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                            : ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  // Stats Row
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Total Bookings', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${details['total_bookings'] ?? customer.totalBookings}',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Total Spent', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Text(
                                                '₹${details['total_spent'] ?? customer.totalSpent.toStringAsFixed(0)}',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Notes / Preferences Card
                                  if (customer.notes.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFBEB),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFFDE68A)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.sticky_note_2_rounded, size: 16, color: Color(0xFFD97706)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Client Notes & Preferences', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF92400E))),
                                                const SizedBox(height: 2),
                                                Text(customer.notes, style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  const Text('Past Visit History', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A))),
                                  const SizedBox(height: 8),

                                  if (history.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'No visit history recorded in this period.',
                                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    )
                                  else
                                    ...history.map((h) {
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.event_note_rounded, size: 18, color: Color(0xFF4F46E5)),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(h['service_name'] ?? 'Salon Service', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${h['booking_date'] ?? ''} • ${h['start_time'] ?? ''} • ${h['staff_name'] ?? 'Staff'}',
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text('₹${h['amount'] ?? '0'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF059669))),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // REMOVE CUSTOMER CONFIRMATION
  // ─────────────────────────────────────────────────────────────────────────────
  void _confirmRemoveCustomer(OwnerCustomerCRM customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove from CRM?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('Are you sure you want to remove "${customer.name}" from your CRM directory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await ApiService.removeCustomerFromCrm(customer.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res['message'] ?? 'Customer removed.'),
                  backgroundColor: res['success'] == true ? const Color(0xFF059669) : const Color(0xFFDC2626),
                ),
              );
              _fetchCustomers();
            },
            child: const Text('Remove'),
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
        title: const Text('Customer CRM & Directory', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A), size: 22),
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'crm_add_fab',
        onPressed: _showAddCustomerActionSheet,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
            : Column(
                children: [
                  // Search & Filter Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    color: Colors.white,
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (val) {
                            _searchQuery = val;
                            _applyFilter();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by client name, mobile or notes...',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      _searchQuery = '';
                                      _applyFilter();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Filter Chips Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('ALL', 'All (${_allCustomers.length})'),
                              const SizedBox(width: 6),
                              _buildFilterChip('VIP', 'VIP Clients'),
                              const SizedBox(width: 6),
                              _buildFilterChip('BOOKED', 'With Bookings'),
                              const SizedBox(width: 6),
                              _buildFilterChip('PRE_ADDED', 'Pre-Added'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Customer List
                  Expanded(
                    child: _filteredCustomers.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _fetchCustomers,
                            child: ListView(
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                                          child: const Icon(Icons.people_outline_rounded, size: 40, color: Color(0xFF4F46E5)),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text('No CRM Customers Found', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Tap "+ Add Customer" below to add clients manually or import from past bookings.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchCustomers,
                            color: const Color(0xFF4F46E5),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                              itemCount: _filteredCustomers.length,
                              itemBuilder: (_, i) {
                                final c = _filteredCustomers[i];
                                return _buildCustomerCard(c);
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSel = _activeFilter == key;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: isSel ? Colors.white : const Color(0xFF475569))),
      selected: isSel,
      selectedColor: const Color(0xFF4F46E5),
      backgroundColor: const Color(0xFFF8FAFC),
      side: BorderSide(color: isSel ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      showCheckmark: false,
      onSelected: (_) {
        setState(() {
          _activeFilter = key;
          _applyFilter();
        });
      },
    );
  }

  Widget _buildCustomerCard(OwnerCustomerCRM c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFEEF2FF),
                  child: Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                    style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & VIP Tag
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                          if (c.isVip)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: const Text('VIP Client', style: TextStyle(color: Color(0xFFD97706), fontSize: 9.5, fontWeight: FontWeight.w800)),
                            ),
                          if (c.source == 'PRE_ADDED' || c.source == 'MANUAL')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: const Text('Pre-Added', style: TextStyle(color: Color(0xFF16A34A), fontSize: 9.5, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Phone Row
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              c.phone.isNotEmpty ? c.phone : 'No mobile registered',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Direct Call Button
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.phone_rounded, color: Color(0xFF059669), size: 16),
                  ),
                  onPressed: () => _callNumber(c.phone),
                  tooltip: 'Call',
                ),
              ],
            ),

            if (c.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'Note: ${c.notes}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Card Footer: Stats & Actions (Responsive & Zero Overflow)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                // Left Stats
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_available_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      '${c.totalBookings} visits',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.currency_rupee_rounded, size: 13, color: Color(0xFF059669)),
                    Text(
                      '${c.totalSpent.toStringAsFixed(0)} spent',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                    ),
                  ],
                ),
                // Right Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _showCustomerDetailsBottomSheet(c),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('History', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _showAddEditCustomerModal(customer: c),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 15, color: Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _confirmRemoveCustomer(c),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFDC2626)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
