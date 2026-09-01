import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class ManageCombosScreen extends StatefulWidget {
  const ManageCombosScreen({super.key});

  @override
  State<ManageCombosScreen> createState() => _ManageCombosScreenState();
}

class _ManageCombosScreenState extends State<ManageCombosScreen> {
  List<OwnerCombo> _combos = [];
  List<OwnerService> _availableServices = [];
  List<OwnerBranch> _branches = [];
  int? _selectedFilterBranchId;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.getCombos(),
      ApiService.getServices(),
      ApiService.getBranches(),
    ]);

    if (!mounted) return;
    setState(() {
      _combos = results[0] as List<OwnerCombo>;
      _availableServices = results[1] as List<OwnerService>;
      _branches = results[2] as List<OwnerBranch>;
      _isLoading = false;
    });
  }

  void _showAddEditComboSheet({OwnerCombo? combo}) {
    final isEditing = combo != null;
    final nameCtrl = TextEditingController(text: isEditing ? combo.name : '');
    final descCtrl = TextEditingController(text: isEditing ? combo.description : '');
    final priceCtrl = TextEditingController(text: isEditing ? combo.price.toStringAsFixed(0) : '');
    final durationCtrl = TextEditingController(text: isEditing ? combo.durationMinutes.toString() : '60');
    final discountCtrl = TextEditingController(text: isEditing ? combo.discount.toStringAsFixed(0) : '0');
    final homeSurchargeCtrl = TextEditingController(text: isEditing ? combo.homeSurcharge.toStringAsFixed(0) : '0');
    String selectedServiceType = isEditing ? combo.serviceType : 'IN_STUDIO';
    
    Set<int> selectedServiceIds = {};
    if (isEditing) {
      selectedServiceIds = combo.services.map((s) => s.id).toSet();
    }

    // Default to ALL branches
    bool applyToAllBranches = isEditing ? false : true;
    Set<int> selectedBranchIds = {};
    if (isEditing && combo.branchId != null) {
      selectedBranchIds = {combo.branchId!};
    } else {
      selectedBranchIds = _branches.map((b) => b.id).toSet();
    }

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          final safeBottom = MediaQuery.of(ctx).padding.bottom;

          // Helper to calculate total of selected services
          double totalRegularPrice = 0;
          int totalDuration = 0;
          for (var s in _availableServices) {
            if (selectedServiceIds.contains(s.id)) {
              totalRegularPrice += s.price;
              totalDuration += s.durationMinutes;
            }
          }

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
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                isEditing ? Icons.edit_note_rounded : Icons.layers_rounded,
                                color: const Color(0xFFD97706),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isEditing ? 'Edit Combo Package' : 'New Combo Package',
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
                          tooltip: 'Delete Combo',
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: ctx,
                                    builder: (dialogCtx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('Delete Combo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                      content: Text('Are you sure you want to delete "${combo.name}"?'),
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
                                    setModalState(() => isSaving = true);
                                    await ApiService.deleteCombo(combo.id);
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

                  // 🏢 BRANCH AVAILABILITY SELECTOR
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
                                  const Icon(Icons.store_rounded, size: 16, color: Color(0xFFD97706)),
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
                                activeColor: const Color(0xFFD97706),
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
                            'Select which branches offer this combo package:',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _branches.map((b) {
                              final isSelected = selectedBranchIds.contains(b.id);
                              return FilterChip(
                                label: Text(b.name, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? const Color(0xFFD97706) : const Color(0xFF475569))),
                                selected: isSelected,
                                selectedColor: const Color(0xFFFFFBEB),
                                backgroundColor: Colors.white,
                                side: BorderSide(color: isSelected ? const Color(0xFFD97706) : const Color(0xFFCBD5E1)),
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

                  // Package Name
                  const Text('Combo Package Name *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'e.g. Grooming Masterclass Combo',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Modality Choice Chips
                  const Text('Package Modality & Availability', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
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
                            color: isSel ? const Color(0xFFD97706) : const Color(0xFF475569),
                          ),
                        ),
                        selected: isSel,
                        selectedColor: const Color(0xFFFFFBEB),
                        backgroundColor: const Color(0xFFF8FAFC),
                        side: BorderSide(
                          color: isSel ? const Color(0xFFD97706) : const Color(0xFFE2E8F0),
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

                  // Description
                  const Text('Description (Optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. Haircut + Beard Grooming + Express Facial all-in-one',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Included Services Multi-Select
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Included Services *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                      if (selectedServiceIds.isNotEmpty)
                        Text(
                          '${selectedServiceIds.length} Selected (₹${totalRegularPrice.toStringAsFixed(0)} • ${totalDuration}m)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: _availableServices.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No individual services found. Please add services first.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _availableServices.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, indent: 40),
                            itemBuilder: (_, idx) {
                              final s = _availableServices[idx];
                              final isSelected = selectedServiceIds.contains(s.id);
                              return CheckboxListTile(
                                value: isSelected,
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: const Color(0xFFD97706),
                                title: Text(s.name, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: const Color(0xFF0F172A))),
                                subtitle: Text('${s.durationMinutes} mins • ${s.category}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                secondary: Text('₹${s.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF059669))),
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      selectedServiceIds.add(s.id);
                                    } else {
                                      selectedServiceIds.remove(s.id);
                                    }
                                    if (!isEditing && priceCtrl.text.isEmpty && selectedServiceIds.isNotEmpty) {
                                      double sum = 0;
                                      int mins = 0;
                                      for (var item in _availableServices) {
                                        if (selectedServiceIds.contains(item.id)) {
                                          sum += item.price;
                                          mins += item.durationMinutes;
                                        }
                                      }
                                      priceCtrl.text = (sum * 0.85).round().toString();
                                      durationCtrl.text = mins.toString();
                                      discountCtrl.text = (sum * 0.15).round().toString();
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Pricing & Duration
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Combo Price (₹) *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                            const SizedBox(height: 4),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: 'e.g. 599',
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
                                hintText: '60',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5)),
                                prefixIcon: const Icon(Icons.schedule_rounded, color: Color(0xFF64748B), size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Discount / Savings
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Customer Savings (₹)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                            const SizedBox(height: 4),
                            TextField(
                              controller: discountCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: 'e.g. 150',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5)),
                                prefixIcon: const Icon(Icons.local_offer_outlined, color: Color(0xFFD97706), size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selectedServiceType != 'IN_STUDIO') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Doorstep Surcharge (₹)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
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
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        elevation: 0,
                        alignment: Alignment.center,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                              if (name.isEmpty || price <= 0) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Please enter combo name and valid price')),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);

                              final data = {
                                'name': name,
                                'description': descCtrl.text.trim(),
                                'service_type': selectedServiceType,
                                'price': price,
                                'home_surcharge': double.tryParse(homeSurchargeCtrl.text) ?? 0.0,
                                'duration_minutes': int.tryParse(durationCtrl.text) ?? 60,
                                'discount': double.tryParse(discountCtrl.text) ?? 0,
                                'service_ids': selectedServiceIds.toList(),
                                'apply_to_all_branches': applyToAllBranches,
                                'branch_ids': applyToAllBranches ? null : selectedBranchIds.toList(),
                                'branch_id': selectedBranchIds.isNotEmpty ? selectedBranchIds.first : null,
                                'is_active': isEditing ? combo.isActive : true,
                              };

                              if (isEditing) {
                                await ApiService.updateCombo(combo.id, data);
                              } else {
                                await ApiService.createCombo(data);
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                              _fetchData();
                            },
                      child: Center(
                        child: isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                isEditing ? 'Save Combo Changes' : (applyToAllBranches ? 'Publish to All Branches' : 'Publish Combo Package'),
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

    final filteredCombos = _combos.where((c) {
      final matchesBranch = _selectedFilterBranchId == null || c.branchId == _selectedFilterBranchId;
      if (!matchesBranch) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q);
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
                color: const Color(0xFFD97706).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: 'manage_combos_fab',
            onPressed: () => _showAddEditComboSheet(),
            backgroundColor: const Color(0xFFD97706),
            foregroundColor: Colors.white,
            elevation: 0,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text(
              'Add Combo',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.2),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD97706)))
            : RefreshIndicator(
                onRefresh: _fetchData,
                color: const Color(0xFFD97706),
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
                              hintText: 'Search combos by package name...',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5)),
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
                                      selectedColor: const Color(0xFFD97706),
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
                                      selectedColor: const Color(0xFFD97706),
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
                      child: filteredCombos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
                                    child: const Icon(Icons.layers_rounded, size: 40, color: Color(0xFFD97706)),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('No Combos Found', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A))),
                                  const SizedBox(height: 4),
                                  const Text('Create bundle packages with discount savings to boost sales.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(16, 6, 16, canPop ? 30 : 110),
                              itemCount: filteredCombos.length,
                              itemBuilder: (_, i) {
                                final c = filteredCombos[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
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
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFFBEB),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.layers_rounded, color: Color(0xFFD97706), size: 22),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Full Combo Name (no ellipsis)
                                                  Text(
                                                    c.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 15,
                                                      color: Color(0xFF0F172A),
                                                      height: 1.25,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  // Price, Discount, Duration & Branch Wrap
                                                  Wrap(
                                                    spacing: 6,
                                                    runSpacing: 4,
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    children: [
                                                      Text(
                                                        '₹${c.price.toStringAsFixed(0)}',
                                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF059669)),
                                                      ),
                                                      if (c.serviceType == 'AT_HOME')
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFECFDF5),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFFA7F3D0)),
                                                          ),
                                                          child: const Text('🏠 At-Home', style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w700)),
                                                        ),
                                                      if (c.serviceType == 'EVENT_WEDDING')
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFFFBEB),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFFFDE68A)),
                                                          ),
                                                          child: const Text('💍 Wedding & Events', style: TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.w700)),
                                                        ),
                                                      if (c.serviceType == 'ANY')
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFEEF2FF),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFFC7D2FE)),
                                                          ),
                                                          child: const Text('🌟 Studio & Home', style: TextStyle(fontSize: 10, color: Color(0xFF4F46E5), fontWeight: FontWeight.w700)),
                                                        ),
                                                      if (c.discount > 0)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFECFDF5),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFFA7F3D0)),
                                                          ),
                                                          child: Text(
                                                            'Save ₹${c.discount.toStringAsFixed(0)}',
                                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                                                          ),
                                                        ),
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF64748B)),
                                                          const SizedBox(width: 3),
                                                          Text(
                                                            '${c.durationMinutes}m',
                                                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                                          ),
                                                        ],
                                                      ),
                                                      if (c.branchName.isNotEmpty)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFF1F5F9),
                                                            borderRadius: BorderRadius.circular(5),
                                                          ),
                                                          child: Text(
                                                            c.branchName,
                                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () => _showAddEditComboSheet(combo: c),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF8FAFC),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                                ),
                                                child: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF64748B)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (c.description.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            c.description,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                                          ),
                                        ],
                                        if (c.services.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 5,
                                            runSpacing: 5,
                                            children: c.services.map((s) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                              ),
                                              child: Text(
                                                s.name,
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                              ),
                                            )).toList(),
                                          ),
                                        ],
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
