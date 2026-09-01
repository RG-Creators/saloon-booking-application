import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'add_edit_staff_screen.dart';

class ManageStaffScreen extends StatefulWidget {
  const ManageStaffScreen({super.key});

  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen> {
  List<OwnerStaff> _staffList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getStaff();
    if (!mounted) return;
    setState(() {
      _staffList = list;
      _isLoading = false;
    });
  }

  void _showServicesPopup(BuildContext context, OwnerStaff staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.format_list_bulleted_rounded, color: Color(0xFF4F46E5), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Services for ${staff.name}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    staff.services.isEmpty
                        ? 'No services assigned'
                        : '${staff.services.length} assigned service${staff.services.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: staff.services.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 28, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 8),
                      Text(
                        'No specific services attached to ${staff.name}.',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Tap on this staff card to edit and attach salon services.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: staff.services.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (_, i) {
                      final s = staff.services[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4F46E5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                  if (s.category.isNotEmpty)
                                    Text(
                                      s.category,
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${s.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF059669)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF4F46E5))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    final filteredList = _staffList.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = s.name.toLowerCase();
      final role = s.role.toLowerCase();
      final email = (s.email ?? '').toLowerCase();
      final mobile = (s.mobile ?? '').toLowerCase();
      return name.contains(q) || role.contains(q) || email.contains(q) || mobile.contains(q);
    }).toList();

    final activeCount = _staffList.where((s) => s.isBookable).length;
    final totalCount = _staffList.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: canPop
          ? AppBar(
              title: const Text(
                'Staff & Stylists Roster',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0F172A)),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: canPop ? 14 : 92),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: 'manage_staff_fab',
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditStaffScreen()),
              );
              if (res == true) _fetchStaff();
            },
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text(
              'Add Staff',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.2),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchStaff,
          color: const Color(0xFF4F46E5),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5), strokeWidth: 2.5))
              : ListView(
                  padding: EdgeInsets.only(
                    left: 14,
                    right: 14,
                    top: 10,
                    bottom: canPop ? 30 : 110,
                  ),
                  children: [
                    // Compact Header Status Summary Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF0284C7), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.badge_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Team Members & Stylists',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$activeCount of $totalCount accepting bookings • Tap card to edit',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Compact Search Bar
                    if (_staffList.length > 2) ...[
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Search staff by name, role or mobile...',
                            hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1), size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                                    onPressed: () => setState(() => _searchQuery = ''),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Staff List
                    if (filteredList.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.people_outline_rounded, size: 28, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No staff found matching "$_searchQuery"'
                                  : 'No staff members registered yet.',
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try checking for typos or searching by phone'
                                  : 'Tap "+ Add Staff" to onboard your first team stylist.',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...filteredList.map((staff) => _StaffCard(
                            staff: staff,
                            onShowServices: () => _showServicesPopup(context, staff),
                            onEdit: () async {
                              final Map<String, dynamic> staffMap = {
                                'id': staff.id,
                                'name': staff.name,
                                'role': staff.role,
                                'is_bookable': staff.isBookable,
                                'email': staff.email,
                                'mobile': staff.mobile,
                                'is_active': staff.isActive,
                                'services': staff.services.map((s) => {'id': s.id, 'name': s.name, 'category': s.category, 'price': s.price}).toList(),
                              };
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddEditStaffScreen(staff: staffMap)),
                              );
                              if (res == true) _fetchStaff();
                            },
                            onToggle: (val) async {
                              final index = _staffList.indexWhere((s) => s.id == staff.id);
                              if (index != -1) {
                                setState(() {
                                  _staffList[index] = OwnerStaff(
                                    id: staff.id,
                                    name: staff.name,
                                    role: staff.role,
                                    isBookable: val,
                                    email: staff.email,
                                    mobile: staff.mobile,
                                    isActive: staff.isActive,
                                    services: staff.services,
                                  );
                                });
                              }
                              await ApiService.updateStaff(staff.id, {'is_bookable': val});
                            },
                          )),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final OwnerStaff staff;
  final VoidCallback onEdit;
  final VoidCallback onShowServices;
  final ValueChanged<bool> onToggle;

  const _StaffCard({
    required this.staff,
    required this.onEdit,
    required this.onShowServices,
    required this.onToggle,
  });

  static const List<Color> _colors = [
    Color(0xFF4F46E5),
    Color(0xFF0D9488),
    Color(0xFFEA580C),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFF0284C7),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[staff.id % _colors.length];
    final initial = staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.85), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Main Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Staff Name + Status Switch
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              staff.name,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Switch & Status Pill
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: staff.isBookable ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: staff.isBookable ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      staff.isBookable ? 'Active' : 'Off',
                                      style: TextStyle(
                                        color: staff.isBookable ? const Color(0xFF059669) : const Color(0xFF64748B),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                height: 20,
                                width: 34,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Switch(
                                    value: staff.isBookable,
                                    activeThumbColor: const Color(0xFF059669),
                                    activeTrackColor: const Color(0xFF059669).withValues(alpha: 0.35),
                                    inactiveThumbColor: const Color(0xFF94A3B8),
                                    inactiveTrackColor: const Color(0xFFE2E8F0),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    onChanged: onToggle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Second Row: Role Badge + Clickable Services Popup Badge
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: color.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              staff.role,
                              style: TextStyle(
                                color: color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          // Clickable Services Badge
                          InkWell(
                            onTap: onShowServices,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: staff.services.isNotEmpty ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: staff.services.isNotEmpty ? const Color(0xFFDDD6FE) : const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    staff.services.length >= 4
                                        ? '⭐ All-Rounder (${staff.services.length})'
                                        : staff.services.isNotEmpty
                                            ? '${staff.services.length} Services'
                                            : '0 Services',
                                    style: TextStyle(
                                      color: staff.services.isNotEmpty ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 11,
                                    color: staff.services.isNotEmpty ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Third Row: Contact Info & Explicit "No username" Badge
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 11.5, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            staff.mobile != null && staff.mobile!.isNotEmpty
                                ? staff.mobile!
                                : 'No phone number',
                            style: TextStyle(
                              color: staff.mobile != null && staff.mobile!.isNotEmpty ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            staff.email != null && staff.email!.isNotEmpty
                                ? Icons.alternate_email_rounded
                                : Icons.person_off_outlined,
                            size: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              staff.email != null && staff.email!.isNotEmpty
                                  ? staff.email!
                                  : 'No username',
                              style: TextStyle(
                                color: staff.email != null && staff.email!.isNotEmpty ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                fontStyle: staff.email != null && staff.email!.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
  }
}
