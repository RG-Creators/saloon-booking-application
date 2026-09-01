import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'manage_hours_screen.dart';

class ManageBranchesScreen extends StatefulWidget {
  const ManageBranchesScreen({super.key});

  @override
  State<ManageBranchesScreen> createState() => _ManageBranchesScreenState();
}

class _ManageBranchesScreenState extends State<ManageBranchesScreen> {
  List<OwnerBranch> _branches = [];
  bool _isLoading = true;
  static const int _maxBranches = 4;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoading = true);
    final branches = await ApiService.getBranches();
    if (!mounted) return;
    setState(() {
      _branches = branches;
      _isLoading = false;
    });
  }

  // --- ⚡ TOGGLE BRANCH ACTIVE / DISABLED STATUS ---
  Future<void> _toggleBranchStatus(OwnerBranch branch) async {
    final scaffold = ScaffoldMessenger.of(context);
    final res = await ApiService.toggleBranchStatus(branch.id);
    if (!mounted) return;
    if (res['success'] == true) {
      _fetchBranches();
      scaffold.showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Branch status updated.'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      scaffold.showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to update branch status.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // --- 🗑️ DELETE BRANCH MODAL WITH CONFIRMATION ---
  void _confirmDeleteBranch(OwnerBranch branch) {
    if (_branches.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Cannot delete your primary active branch. At least one branch is required.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Branch?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${branch.name}"? All assigned operating hours and schedules for this branch will also be removed.',
          style: const TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final scaffold = ScaffoldMessenger.of(context);
              final res = await ApiService.deleteBranch(branch.id);
              if (!mounted) return;
              if (res['success'] == true) {
                _fetchBranches();
                scaffold.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Branch deleted successfully.'),
                    backgroundColor: const Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } else {
                scaffold.showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Failed to delete branch.'),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Delete Branch', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // --- ✏️ EDIT BRANCH BOTTOM SHEET ---
  void _showEditBranchSheet(OwnerBranch branch) {
    final nameCtrl = TextEditingController(text: branch.name);
    final addressCtrl = TextEditingController(text: branch.address);
    final cityCtrl = TextEditingController(text: branch.city);
    final stateCtrl = TextEditingController(text: branch.state);
    final pinCtrl = TextEditingController(text: branch.pinCode);
    final phoneCtrl = TextEditingController(text: branch.contactMobile);
    bool isActive = branch.isActive;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_location_alt_rounded, color: Color(0xFF4F46E5), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Edit Branch Details',
                                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 18)),
                            Text('ID #${branch.id} • ${branch.name}',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Active / Online Toggle Inside Sheet
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                          color: isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isActive ? 'Branch is Active & Accepting Bookings' : 'Branch is Disabled / Paused',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isActive ? const Color(0xFF065F46) : const Color(0xFF475569),
                                ),
                              ),
                              Text(
                                isActive ? 'Visible on customer explore & booking page' : 'Hidden from customer bookings',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isActive ? const Color(0xFF047857) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isActive,
                          activeThumbColor: const Color(0xFF059669),
                          activeTrackColor: const Color(0xFFA7F3D0),
                          onChanged: (val) {
                            setModalState(() => isActive = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _BranchField(controller: nameCtrl, label: 'Branch Name *', hint: 'e.g. Koramangala Branch', icon: Icons.store_rounded),
                  const SizedBox(height: 14),
                  _BranchField(controller: addressCtrl, label: 'Address *', hint: 'Street, Building, Landmark', icon: Icons.location_on_rounded, maxLines: 2),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _BranchField(controller: cityCtrl, label: 'City *', hint: 'Bangalore', icon: Icons.location_city_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _BranchField(controller: stateCtrl, label: 'State', hint: 'Karnataka', icon: Icons.map_rounded)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _BranchField(controller: pinCtrl, label: 'PIN Code', hint: '560001', icon: Icons.pin_drop_rounded, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _BranchField(controller: phoneCtrl, label: 'Contact Phone', hint: '+91 98765 43210', icon: Icons.phone_rounded, keyboardType: TextInputType.phone)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty ||
                                  addressCtrl.text.trim().isEmpty ||
                                  cityCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill Name, Address, and City.')),
                                );
                                return;
                              }
                              setModalState(() => isSaving = true);
                              final scaffoldMsg = ScaffoldMessenger.of(context);
                              
                              final res = await ApiService.updateBranch(branch.id, {
                                'name': nameCtrl.text.trim(),
                                'address': addressCtrl.text.trim(),
                                'city': cityCtrl.text.trim(),
                                'state': stateCtrl.text.trim(),
                                'pin_code': pinCtrl.text.trim(),
                                'contact_mobile': phoneCtrl.text.trim(),
                                'is_active': isActive,
                              });

                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);

                              if (res['success'] == true) {
                                _fetchBranches();
                                scaffoldMsg.showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? '✅ Branch updated successfully!'),
                                    backgroundColor: const Color(0xFF059669),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              } else {
                                scaffoldMsg.showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Failed to update branch.'),
                                    backgroundColor: const Color(0xFFDC2626),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

  // --- ➕ ADD BRANCH BOTTOM SHEET ---
  void _showAddBranchSheet() {
    if (_branches.length >= _maxBranches) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $_maxBranches branches reached (1 main + 3 additional).'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_business_rounded, color: Color(0xFF4F46E5), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Add New Branch',
                              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 18)),
                          Text('${_maxBranches - _branches.length} slot(s) remaining',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _BranchField(controller: nameCtrl, label: 'Branch Name *', hint: 'e.g. South Ex Branch', icon: Icons.store_rounded),
                  const SizedBox(height: 14),
                  _BranchField(controller: addressCtrl, label: 'Address *', hint: 'Street, Building, Landmark', icon: Icons.location_on_rounded, maxLines: 2),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _BranchField(controller: cityCtrl, label: 'City *', hint: 'New Delhi', icon: Icons.location_city_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _BranchField(controller: stateCtrl, label: 'State', hint: 'Delhi', icon: Icons.map_rounded)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _BranchField(controller: pinCtrl, label: 'PIN Code', hint: '110049', icon: Icons.pin_drop_rounded, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _BranchField(controller: phoneCtrl, label: 'Contact Phone', hint: '+91 98765 43210', icon: Icons.phone_rounded, keyboardType: TextInputType.phone)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty ||
                                  addressCtrl.text.trim().isEmpty ||
                                  cityCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill Name, Address, and City.')),
                                );
                                return;
                              }
                              setModalState(() => isSaving = true);
                              final scaffoldMsg = ScaffoldMessenger.of(context);
                              
                              final res = await ApiService.createBranch({
                                'name': nameCtrl.text.trim(),
                                'address': addressCtrl.text.trim(),
                                'city': cityCtrl.text.trim(),
                                'state': stateCtrl.text.trim(),
                                'pin_code': pinCtrl.text.trim(),
                                'contact_mobile': phoneCtrl.text.trim(),
                                'is_active': true,
                              });

                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);

                              if (res['success'] == true) {
                                _fetchBranches();
                                scaffoldMsg.showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? '✅ Branch added successfully!'),
                                    backgroundColor: const Color(0xFF059669),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              } else {
                                scaffoldMsg.showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Failed to add branch.'),
                                    backgroundColor: const Color(0xFFDC2626),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Add Branch', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        title: const Text('Branch Locations',
            style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800)),
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
            onPressed: _fetchBranches,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'manage_branches_fab',
        onPressed: _showAddBranchSheet,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Branch', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
            : Column(
                children: [
                  // Branch slot capacity pill banner
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _branches.length >= _maxBranches
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _branches.length >= _maxBranches
                            ? const Color(0xFFFCD34D)
                            : const Color(0xFFC7D2FE),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _branches.length >= _maxBranches
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline_rounded,
                          color: _branches.length >= _maxBranches
                              ? const Color(0xFFD97706)
                              : const Color(0xFF4F46E5),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_branches.length} / $_maxBranches branches active  •  ${_maxBranches - _branches.length} slots available',
                            style: TextStyle(
                              color: _branches.length >= _maxBranches
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF4F46E5),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _branches.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEEF2FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.store_mall_directory_rounded, size: 48, color: Color(0xFF4F46E5)),
                                ),
                                const SizedBox(height: 16),
                                const Text('No branches found',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                const SizedBox(height: 4),
                                const Text('Add your first branch to start receiving bookings.',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _showAddBranchSheet,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Add Primary Branch'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                            itemCount: _branches.length,
                            itemBuilder: (_, i) {
                              final b = _branches[i];
                              final isMain = i == 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isMain
                                        ? const Color(0xFFC7D2FE)
                                        : const Color(0xFFE2E8F0),
                                    width: isMain ? 1.5 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Header: Icon + Name + Badges
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: b.isActive
                                                  ? (isMain ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9))
                                                  : const Color(0xFFFEE2E2),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              isMain ? Icons.star_rounded : Icons.store_rounded,
                                              color: b.isActive
                                                  ? (isMain ? const Color(0xFF4F46E5) : const Color(0xFF64748B))
                                                  : const Color(0xFFDC2626),
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        b.name,
                                                        style: const TextStyle(
                                                          color: Color(0xFF0F172A),
                                                          fontWeight: FontWeight.w800,
                                                          fontSize: 16,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (isMain) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFEEF2FF),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: const Text('Main',
                                                            style: TextStyle(
                                                              color: Color(0xFF4F46E5),
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w800,
                                                            )),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                // Active / Disabled Live Badge
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                                      decoration: BoxDecoration(
                                                        color: b.isActive
                                                            ? const Color(0xFFECFDF5)
                                                            : const Color(0xFFFEF2F2),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(
                                                          color: b.isActive
                                                              ? const Color(0xFFA7F3D0)
                                                              : const Color(0xFFFECACA),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 6,
                                                            height: 6,
                                                            decoration: BoxDecoration(
                                                              color: b.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                                              shape: BoxShape.circle,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 5),
                                                          Text(
                                                            b.isActive ? 'Active & Live' : 'Disabled / Paused',
                                                            style: TextStyle(
                                                              color: b.isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),
                                      // Location Address info
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFF1F5F9)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    b.address,
                                                    style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w500),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_city_rounded, size: 14, color: Color(0xFF94A3B8)),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    [
                                                      if (b.city.isNotEmpty) b.city,
                                                      if (b.state.isNotEmpty) b.state,
                                                      if (b.pinCode.isNotEmpty) 'PIN: ${b.pinCode}',
                                                    ].join(' • '),
                                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (b.contactMobile.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF94A3B8)),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      b.contactMobile,
                                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 14),

                                      // Bottom Actions: Manage Hours + Edit + Toggle + Delete
                                      Row(
                                        children: [
                                          // Operating Hours Shortcut
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ManageHoursScreen(initialBranchId: b.id),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.schedule_rounded, size: 15),
                                              label: const Text('Hours & Shifts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF4F46E5),
                                                side: const BorderSide(color: Color(0xFFC7D2FE)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // Edit Button
                                          IconButton(
                                            onPressed: () => _showEditBranchSheet(b),
                                            icon: const Icon(Icons.edit_rounded, size: 18),
                                            color: const Color(0xFF475569),
                                            tooltip: 'Edit Branch Details',
                                            style: IconButton.styleFrom(
                                              backgroundColor: const Color(0xFFF1F5F9),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                          const SizedBox(width: 4),

                                          // Toggle Disable / Enable
                                          IconButton(
                                            onPressed: () => _toggleBranchStatus(b),
                                            icon: Icon(
                                              b.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                                              size: 20,
                                            ),
                                            color: b.isActive ? const Color(0xFFD97706) : const Color(0xFF059669),
                                            tooltip: b.isActive ? 'Disable Branch' : 'Enable Branch',
                                            style: IconButton.styleFrom(
                                              backgroundColor: b.isActive ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                          const SizedBox(width: 4),

                                          // Delete Button (only if > 1 branch)
                                          if (_branches.length > 1)
                                            IconButton(
                                              onPressed: () => _confirmDeleteBranch(b),
                                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                              color: const Color(0xFFDC2626),
                                              tooltip: 'Delete Branch',
                                              style: IconButton.styleFrom(
                                                backgroundColor: const Color(0xFFFEE2E2),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BranchField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  const _BranchField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF374151), fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
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
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
