import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  List<OwnerService> _services = [];
  List<OwnerBranch> _branches = [];
  int? _selectedFilterBranchId;
  bool _isLoading = true;
  String _searchQuery = '';

  static const List<String> _quickCategories = [
    'Haircut',
    'Beard & Shave',
    'Facial & Skin',
    'Hair Color',
    'Spa & Massage',
    'Waxing & Threading',
    'Makeup & Styling',
    'Nails & Manicure',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.getServices(),
      ApiService.getBranches(),
    ]);
    if (!mounted) return;
    setState(() {
      _services = results[0] as List<OwnerService>;
      _branches = results[1] as List<OwnerBranch>;
      _isLoading = false;
    });
  }

  void _showAddEditServiceModal({OwnerService? service}) {
    final isEditing = service != null;
    final nameCtrl = TextEditingController(text: isEditing ? service.name : '');
    final categoryCtrl = TextEditingController(text: isEditing ? service.category : 'Haircut');
    final priceCtrl = TextEditingController(text: isEditing ? service.price.toStringAsFixed(0) : '250');
    final durationCtrl = TextEditingController(text: isEditing ? service.durationMinutes.toString() : '30');
    final homeSurchargeCtrl = TextEditingController(text: isEditing ? service.homeSurcharge.toStringAsFixed(0) : '0');
    String selectedServiceType = isEditing ? service.serviceType : 'IN_STUDIO';
    
    // Default to ALL branches
    bool applyToAllBranches = isEditing ? false : true;
    Set<int> selectedBranchIds = {};
    if (isEditing && service.branchId != null) {
      selectedBranchIds = {service.branchId!};
    } else {
      selectedBranchIds = _branches.map((b) => b.id).toSet();
    }

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          final safeBottom = MediaQuery.of(ctx).padding.bottom;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + safeBottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                                color: const Color(0xFF4F46E5),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isEditing ? 'Edit Service' : 'Add New Service',
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isEditing)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                          tooltip: 'Delete Service',
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: ctx,
                                    builder: (dialogCtx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('Delete Service', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                      content: Text('Are you sure you want to delete "${service.name}"?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                          onPressed: () => Navigator.pop(dialogCtx, true),
                                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    setModalState(() => isSubmitting = true);
                                    await ApiService.deleteService(service.id);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    _fetchData();
                                  }
                                },
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

                  // 🏢 BRANCH AVAILABILITY SELECTOR (Default to All Branches)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  const Icon(Icons.store_rounded, size: 16, color: Color(0xFF4F46E5)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      isEditing ? 'Selected Branch' : 'Apply to All Branches',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isEditing)
                              Switch(
                                value: applyToAllBranches,
                                activeColor: const Color(0xFF4F46E5),
                                onChanged: (val) {
                                  setModalState(() {
                                    applyToAllBranches = val;
                                    if (val) {
                                      selectedBranchIds = _branches.map((b) => b.id).toSet();
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                        if (!applyToAllBranches) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Select which branches offer this service:',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _branches.map((b) {
                              final isSelected = selectedBranchIds.contains(b.id);
                              return FilterChip(
                                label: Text(b.name, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569))),
                                selected: isSelected,
                                selectedColor: const Color(0xFFEEF2FF),
                                backgroundColor: Colors.white,
                                side: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                showCheckmark: false,
                                onSelected: (sel) {
                                  setModalState(() {
                                    if (sel) {
                                      selectedBranchIds.add(b.id);
                                    } else if (selectedBranchIds.length > 1) {
                                      selectedBranchIds.remove(b.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Service Name
                  const Text('Service Name *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'e.g. Classic Haircut & Styling',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Service Modality / Type (In-Studio vs At-Home vs Wedding)
                  const Text('Service Modality & Booking Availability', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      {'key': 'IN_STUDIO', 'label': '✂️ In-Studio Only'},
                      {'key': 'AT_HOME', 'label': '🏠 At-Home Available'},
                      {'key': 'EVENT_WEDDING', 'label': '💍 Wedding & Events'},
                      {'key': 'ANY', 'label': '🌟 All / Flexible'},
                    ].map((m) {
                      final isSel = selectedServiceType == m['key'];
                      return ChoiceChip(
                        label: Text(
                          m['label']!,
                          style: TextStyle(
                            fontSize: 11.5,
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
                          if (val) setModalState(() => selectedServiceType = m['key']!);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Category Selector
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: categoryCtrl,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Category (e.g. Haircut / Facial)',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                      prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF64748B), size: 18),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _quickCategories.map((cat) {
                        final isSel = categoryCtrl.text.trim().toLowerCase() == cat.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: ActionChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                              ),
                            ),
                            backgroundColor: isSel ? const Color(0xFFEEF2FF) : Colors.white,
                            side: BorderSide(color: isSel ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                            onPressed: () {
                              setModalState(() => categoryCtrl.text = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Price & Duration
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Price (₹) *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                            const SizedBox(height: 4),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: '250',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
                                prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF059669), size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Duration (Mins) *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                            const SizedBox(height: 4),
                            TextField(
                              controller: durationCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: '30',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                                prefixIcon: const Icon(Icons.schedule_rounded, color: Color(0xFF64748B), size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (selectedServiceType != 'IN_STUDIO') ...[
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Extra Doorstep Surcharge (₹) (Optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: homeSurchargeCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: '0',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                            prefixIcon: const Icon(Icons.home_repair_service_rounded, color: Color(0xFF4F46E5), size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Action Button
                  Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        elevation: 0,
                        alignment: Alignment.center,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Please enter a service name')),
                                );
                                return;
                              }
                              setModalState(() => isSubmitting = true);

                              final data = {
                                'name': name,
                                'category': categoryCtrl.text.trim().isEmpty ? 'General' : categoryCtrl.text.trim(),
                                'service_type': selectedServiceType,
                                'price': double.tryParse(priceCtrl.text) ?? 200.0,
                                'home_surcharge': double.tryParse(homeSurchargeCtrl.text) ?? 0.0,
                                'duration_minutes': int.tryParse(durationCtrl.text) ?? 30,
                                'apply_to_all_branches': applyToAllBranches,
                                'branch_ids': applyToAllBranches ? null : selectedBranchIds.toList(),
                                'branch_id': selectedBranchIds.isNotEmpty ? selectedBranchIds.first : null,
                              };

                              if (isEditing) {
                                await ApiService.updateService(service.id, data);
                              } else {
                                await ApiService.addService(data);
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                              _fetchData();
                            },
                      child: Center(
                        child: isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                isEditing ? 'Save Changes' : (applyToAllBranches ? 'Publish to All Branches' : 'Publish Service'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    final filteredServices = _services.where((s) {
      final matchesBranch = _selectedFilterBranchId == null || s.branchId == _selectedFilterBranchId;
      if (!matchesBranch) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) || s.category.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
            heroTag: 'manage_services_fab',
            onPressed: () => _showAddEditServiceModal(),
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text(
              'Add Service',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.2),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
            : RefreshIndicator(
                onRefresh: _fetchData,
                color: const Color(0xFF4F46E5),
                child: Column(
                  children: [
                    // Search & Branch Filter Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (v) => setState(() => _searchQuery = v.trim()),
                            decoration: InputDecoration(
                              hintText: 'Search services by name or category...',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                            ),
                          ),
                          if (_branches.length > 1) ...[
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: const Text('All Branches'),
                                      labelStyle: TextStyle(
                                        fontSize: 11,
                                        fontWeight: _selectedFilterBranchId == null ? FontWeight.w800 : FontWeight.w500,
                                        color: _selectedFilterBranchId == null ? Colors.white : const Color(0xFF475569),
                                      ),
                                      selected: _selectedFilterBranchId == null,
                                      selectedColor: const Color(0xFF4F46E5),
                                      backgroundColor: Colors.white,
                                      onSelected: (sel) {
                                        setState(() => _selectedFilterBranchId = null);
                                      },
                                    ),
                                  ),
                                  ..._branches.map((b) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(b.name),
                                      labelStyle: TextStyle(
                                        fontSize: 11,
                                        fontWeight: _selectedFilterBranchId == b.id ? FontWeight.w800 : FontWeight.w500,
                                        color: _selectedFilterBranchId == b.id ? Colors.white : const Color(0xFF475569),
                                      ),
                                      selected: _selectedFilterBranchId == b.id,
                                      selectedColor: const Color(0xFF4F46E5),
                                      backgroundColor: Colors.white,
                                      onSelected: (sel) {
                                        setState(() => _selectedFilterBranchId = sel ? b.id : null);
                                      },
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    Expanded(
                      child: filteredServices.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                                    child: const Icon(Icons.spa_rounded, size: 40, color: Color(0xFF4F46E5)),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('No Services Found', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A))),
                                  const SizedBox(height: 4),
                                  const Text('Add your first service to start offering appointments.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(16, 6, 16, canPop ? 30 : 110),
                              itemCount: filteredServices.length,
                              itemBuilder: (_, i) {
                                final s = filteredServices[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.spa_rounded, color: Color(0xFF4F46E5), size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Full Service Name (Wrapped naturally without truncation)
                                              Text(
                                                s.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14.5,
                                                  color: Color(0xFF0F172A),
                                                  height: 1.25,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              // Metadata Wrap (Category, Duration, Branch)
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(5),
                                                    ),
                                                    child: Text(
                                                      s.category,
                                                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                  if (s.serviceType == 'AT_HOME')
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFECFDF5),
                                                        borderRadius: BorderRadius.circular(5),
                                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                                      ),
                                                      child: const Text('🏠 At-Home', style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w700)),
                                                    ),
                                                  if (s.serviceType == 'EVENT_WEDDING')
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFFFBEB),
                                                        borderRadius: BorderRadius.circular(5),
                                                        border: Border.all(color: const Color(0xFFFDE68A)),
                                                      ),
                                                      child: const Text('💍 Wedding & Events', style: TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.w700)),
                                                    ),
                                                  if (s.serviceType == 'ANY')
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEEF2FF),
                                                        borderRadius: BorderRadius.circular(5),
                                                        border: Border.all(color: const Color(0xFFC7D2FE)),
                                                      ),
                                                      child: const Text('🌟 Studio & Home', style: TextStyle(fontSize: 10, color: Color(0xFF4F46E5), fontWeight: FontWeight.w700)),
                                                    ),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF64748B)),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        '${s.durationMinutes}m',
                                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                                      ),
                                                    ],
                                                  ),
                                                  if (s.branchName.isNotEmpty)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEEF2FF),
                                                        borderRadius: BorderRadius.circular(5),
                                                      ),
                                                      child: Text(
                                                        s.branchName,
                                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '₹${s.price.toStringAsFixed(0)}',
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: Color(0xFF059669)),
                                            ),
                                            const SizedBox(height: 4),
                                            InkWell(
                                              onTap: () => _showAddEditServiceModal(service: s),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF8FAFC),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                                ),
                                                child: const Icon(Icons.edit_rounded, size: 15, color: Color(0xFF64748B)),
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
      ),
    );
  }
}
