import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTabIndex = 0;

  List<OwnerPromotion> _promotions = [];
  List<OwnerRushPricingRule> _rushRules = [];
  List<OwnerBranch> _branches = [];
  bool _isLoading = true;

  static const List<Map<String, dynamic>> _daysList = [
    {'day': 1, 'label': 'Mon'},
    {'day': 2, 'label': 'Tue'},
    {'day': 3, 'label': 'Wed'},
    {'day': 4, 'label': 'Thu'},
    {'day': 5, 'label': 'Fri'},
    {'day': 6, 'label': 'Sat'},
    {'day': 0, 'label': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _tabController.animation?.addListener(_handleTabAnimation);
    _fetchData();
  }

  void _handleTabChange() {
    if (_tabController.index != _activeTabIndex && !_tabController.indexIsChanging) {
      setState(() {
        _activeTabIndex = _tabController.index;
      });
    }
  }

  void _handleTabAnimation() {
    final animIndex = _tabController.animation?.value.round() ?? _tabController.index;
    if (animIndex != _activeTabIndex && mounted) {
      setState(() {
        _activeTabIndex = animIndex;
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.getPromotions(),
      ApiService.getBranches(),
    ]);

    if (!mounted) return;
    final promoData = results[0] as Map<String, dynamic>;
    final branchesData = results[1] as List<OwnerBranch>;

    setState(() {
      _promotions = (promoData['promotions'] as List<OwnerPromotion>?) ?? [];
      _rushRules = (promoData['rush_rules'] as List<OwnerRushPricingRule>?) ?? [];
      _branches = branchesData;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TIME 12-HOUR FORMATTING HELPERS
  // ─────────────────────────────────────────────────────────────────────────────
  static String formatTime12H(String timeStr) {
    final trimmed = timeStr.trim();
    if (trimmed.isEmpty) return '12:00 PM';
    if (trimmed.toUpperCase().contains('AM') || trimmed.toUpperCase().contains('PM')) {
      return trimmed;
    }
    final parts = trimmed.split(':');
    if (parts.isEmpty) return trimmed;
    int hour = int.tryParse(parts[0]) ?? 12;
    int min = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;
    return '${displayHour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period';
  }

  static TimeOfDay parseTimeToOfDay(String timeStr, {int defaultHour = 14, int defaultMin = 0}) {
    final trimmed = timeStr.trim();
    if (trimmed.isEmpty) return TimeOfDay(hour: defaultHour, minute: defaultMin);
    try {
      if (trimmed.toUpperCase().contains('AM') || trimmed.toUpperCase().contains('PM')) {
        final isPm = trimmed.toUpperCase().contains('PM');
        final clean = trimmed.replaceAll(RegExp(r'[^0-9:]'), '');
        final p = clean.split(':');
        int h = int.parse(p[0]);
        int m = p.length > 1 ? int.parse(p[1]) : 0;
        if (isPm && h < 12) h += 12;
        if (!isPm && h == 12) h = 0;
        return TimeOfDay(hour: h, minute: m);
      } else {
        final p = trimmed.split(':');
        return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
    } catch (_) {
      return TimeOfDay(hour: defaultHour, minute: defaultMin);
    }
  }

  Future<void> _pick12HourTime(
    BuildContext ctx,
    TextEditingController ctrl,
    StateSetter setModalState, {
    int defaultHour = 14,
  }) async {
    final initialTime = parseTimeToOfDay(ctrl.text, defaultHour: defaultHour);
    final picked = await showTimePicker(
      context: ctx,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                dayPeriodShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      final period = picked.period == DayPeriod.pm ? 'PM' : 'AM';
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final formatted = '${hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} $period';
      setModalState(() {
        ctrl.text = formatted;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ADD / EDIT OFF-PEAK DISCOUNT MODAL
  // ─────────────────────────────────────────────────────────────────────────────
  void _showAddEditDiscountModal({OwnerPromotion? discount}) {
    final isEditing = discount != null;
    final titleCtrl = TextEditingController(text: isEditing ? discount.title : '');
    final percentCtrl = TextEditingController(text: isEditing ? discount.discountPercent.toString() : '20');
    final startTimeCtrl = TextEditingController(text: isEditing ? formatTime12H(discount.startTime) : '02:00 PM');
    final endTimeCtrl = TextEditingController(text: isEditing ? formatTime12H(discount.endTime) : '05:00 PM');

    Set<int> selectedDays = isEditing && discount.daysOfWeek.isNotEmpty
        ? discount.daysOfWeek.toSet()
        : {1, 2, 3, 4}; // Mon - Thu default

    int? selectedBranchId = isEditing ? discount.branchId : null;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.local_offer_rounded, color: Color(0xFF059669), size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isEditing ? 'Edit Off-Peak Discount' : 'New Off-Peak Discount',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
                            tooltip: 'Delete Discount',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: ctx,
                                builder: (dCtx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Text('Delete Promotion', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                  content: Text('Are you sure you want to delete "${discount.title}"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                      onPressed: () => Navigator.pop(dCtx, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                setModalState(() => isSaving = true);
                                await ApiService.deleteOffPeakDiscount(discount.id);
                                if (ctx.mounted) Navigator.pop(ctx);
                                _fetchData();
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Promotion Title
                    const Text('Promotion Title *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                    const SizedBox(height: 4),
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'e.g. Afternoon Happy Hour (2 PM - 4 PM)',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Discount Percent
                    const Text('Discount Percentage (%) *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                    const SizedBox(height: 4),
                    TextField(
                      controller: percentCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: '20',
                        suffixText: '% OFF',
                        suffixStyle: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Active Days Selector
                    const Text('Active Days of Week:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _daysList.map((d) {
                        final int dayVal = d['day'];
                        final String label = d['label'];
                        final isSel = selectedDays.contains(dayVal);
                        return FilterChip(
                          label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.w800 : FontWeight.w500, color: isSel ? Colors.white : const Color(0xFF334155))),
                          selected: isSel,
                          selectedColor: const Color(0xFF059669),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSel ? const Color(0xFF059669) : const Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          showCheckmark: false,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedDays.add(dayVal);
                              } else {
                                if (selectedDays.length > 1) selectedDays.remove(dayVal);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Time Window Pickers (12-Hour AM/PM)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time (12h)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _pick12HourTime(context, startTimeCtrl, setModalState, defaultHour: 14),
                                borderRadius: BorderRadius.circular(10),
                                child: IgnorePointer(
                                  child: TextField(
                                    controller: startTimeCtrl,
                                    readOnly: true,
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    decoration: InputDecoration(
                                      hintText: '02:00 PM',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      prefixIcon: const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF059669)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Time (12h)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _pick12HourTime(context, endTimeCtrl, setModalState, defaultHour: 17),
                                borderRadius: BorderRadius.circular(10),
                                child: IgnorePointer(
                                  child: TextField(
                                    controller: endTimeCtrl,
                                    readOnly: true,
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    decoration: InputDecoration(
                                      hintText: '05:00 PM',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      prefixIcon: const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF059669)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Branch Selector
                    if (_branches.isNotEmpty) ...[
                      const Text('Branch Location (Optional):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int?>(
                        initialValue: selectedBranchId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('All Branches (Entire Salon)')),
                          ..._branches.map((b) => DropdownMenuItem<int?>(value: b.id, child: Text(b.name))),
                        ],
                        onChanged: (val) => setModalState(() => selectedBranchId = val),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final title = titleCtrl.text.trim();
                                final percent = double.tryParse(percentCtrl.text.trim()) ?? 0;
                                if (title.isEmpty || percent <= 0) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('Please enter a valid title and discount percent.')),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                final data = {
                                  'title': title,
                                  'discount_percent': percent,
                                  'days_of_week': selectedDays.toList(),
                                  'start_time': startTimeCtrl.text.trim(),
                                  'end_time': endTimeCtrl.text.trim(),
                                  'branch_id': selectedBranchId,
                                  'is_active': isEditing ? discount.isActive : true,
                                };

                                if (isEditing) {
                                  await ApiService.updateOffPeakDiscount(discount.id, data);
                                } else {
                                  await ApiService.createOffPeakDiscount(data);
                                }

                                if (ctx.mounted) Navigator.pop(ctx);
                                _fetchData();
                              },
                        child: isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                isEditing ? 'Save Changes' : 'Publish Off-Peak Discount',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ADD / EDIT RUSH SURGE RULE MODAL
  // ─────────────────────────────────────────────────────────────────────────────
  void _showAddEditSurgeRuleModal({OwnerRushPricingRule? rule}) {
    final isEditing = rule != null;
    final titleCtrl = TextEditingController(text: isEditing ? rule.title : '');
    final surgeCtrl = TextEditingController(text: isEditing ? rule.surgeAmount.toStringAsFixed(0) : '100');
    final startTimeCtrl = TextEditingController(text: isEditing ? formatTime12H(rule.startTime) : '04:00 PM');
    final endTimeCtrl = TextEditingController(text: isEditing ? formatTime12H(rule.endTime) : '08:00 PM');

    Set<int> selectedDays = isEditing && rule.daysOfWeek.isNotEmpty
        ? rule.daysOfWeek.toSet()
        : {0, 6}; // Sat & Sun default

    int? selectedBranchId = isEditing ? rule.branchId : null;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.bolt_rounded, color: Color(0xFFD97706), size: 22),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isEditing ? 'Edit Surge Rule' : 'New Rush Surge Rule',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
                            tooltip: 'Delete Surge Rule',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: ctx,
                                builder: (dCtx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Text('Delete Surge Rule', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                  content: Text('Are you sure you want to delete "${rule.title}"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                      onPressed: () => Navigator.pop(dCtx, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                setModalState(() => isSaving = true);
                                await ApiService.deleteSurgeRule(rule.id);
                                if (ctx.mounted) Navigator.pop(ctx);
                                _fetchData();
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Rule Title
                    const Text('Surge Rule Title *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                    const SizedBox(height: 4),
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'e.g. Weekend Peak Hours Surge',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Surge Amount (₹)
                    const Text('Surge Extra Fee (₹) *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                    const SizedBox(height: 4),
                    TextField(
                      controller: surgeCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: '100',
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Active Days Selector
                    const Text('Active Days of Week:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _daysList.map((d) {
                        final int dayVal = d['day'];
                        final String label = d['label'];
                        final isSel = selectedDays.contains(dayVal);
                        return FilterChip(
                          label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.w800 : FontWeight.w500, color: isSel ? Colors.white : const Color(0xFF334155))),
                          selected: isSel,
                          selectedColor: const Color(0xFFD97706),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSel ? const Color(0xFFD97706) : const Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          showCheckmark: false,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedDays.add(dayVal);
                              } else {
                                if (selectedDays.length > 1) selectedDays.remove(dayVal);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Time Window Pickers (12-Hour AM/PM)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time (12h)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _pick12HourTime(context, startTimeCtrl, setModalState, defaultHour: 16),
                                borderRadius: BorderRadius.circular(10),
                                child: IgnorePointer(
                                  child: TextField(
                                    controller: startTimeCtrl,
                                    readOnly: true,
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    decoration: InputDecoration(
                                      hintText: '04:00 PM',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      prefixIcon: const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFD97706)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Time (12h)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _pick12HourTime(context, endTimeCtrl, setModalState, defaultHour: 20),
                                borderRadius: BorderRadius.circular(10),
                                child: IgnorePointer(
                                  child: TextField(
                                    controller: endTimeCtrl,
                                    readOnly: true,
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    decoration: InputDecoration(
                                      hintText: '08:00 PM',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      prefixIcon: const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFD97706)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Branch Selector
                    if (_branches.isNotEmpty) ...[
                      const Text('Branch Location (Optional):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int?>(
                        initialValue: selectedBranchId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('All Branches (Entire Salon)')),
                          ..._branches.map((b) => DropdownMenuItem<int?>(value: b.id, child: Text(b.name))),
                        ],
                        onChanged: (val) => setModalState(() => selectedBranchId = val),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final title = titleCtrl.text.trim();
                                final surge = double.tryParse(surgeCtrl.text.trim()) ?? 0;
                                if (title.isEmpty || surge <= 0) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('Please enter a valid title and surge amount.')),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                final data = {
                                  'title': title,
                                  'surge_amount': surge,
                                  'days_of_week': selectedDays.toList(),
                                  'start_time': startTimeCtrl.text.trim(),
                                  'end_time': endTimeCtrl.text.trim(),
                                  'branch_id': selectedBranchId,
                                  'is_enabled': isEditing ? rule.isEnabled : true,
                                };

                                if (isEditing) {
                                  await ApiService.updateSurgeRule(rule.id, data);
                                } else {
                                  await ApiService.createSurgeRule(data);
                                }

                                if (ctx.mounted) Navigator.pop(ctx);
                                _fetchData();
                              },
                        child: isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                isEditing ? 'Save Surge Changes' : 'Publish Rush Surge Rule',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Discounts & Surge Pricing',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _activeTabIndex == 0 ? const Color(0xFF059669) : const Color(0xFFD97706),
          indicatorWeight: 3,
          labelColor: _activeTabIndex == 0 ? const Color(0xFF059669) : const Color(0xFFD97706),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_offer_rounded, size: 15),
                    const SizedBox(width: 4),
                    Text('Discounts (${_promotions.length})'),
                  ],
                ),
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 17),
                    const SizedBox(width: 4),
                    Text('Surge Rules (${_rushRules.length})'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'promotions_fab',
        onPressed: () {
          if (_activeTabIndex == 0) {
            _showAddEditDiscountModal();
          } else {
            _showAddEditSurgeRuleModal();
          }
        },
        backgroundColor: _activeTabIndex == 0 ? const Color(0xFF059669) : const Color(0xFFD97706),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          _activeTabIndex == 0 ? 'Add Discount' : 'Add Surge Rule',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPromotionsTab(),
                  _buildRushRulesTab(),
                ],
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DISCOUNTS TAB
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildPromotionsTab() {
    if (_promotions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                child: const Icon(Icons.local_offer_rounded, size: 40, color: Color(0xFF059669)),
              ),
              const SizedBox(height: 12),
              const Text('No Off-Peak Discounts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              const Text('Offer special discount percentages during low-footfall hours to increase bookings.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => _showAddEditDiscountModal(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add First Discount', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFF059669),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        itemCount: _promotions.length,
        itemBuilder: (_, i) {
          final p = _promotions[i];
          final timeDisplay = p.timeWindow.isNotEmpty ? p.timeWindow : '${formatTime12H(p.startTime)} to ${formatTime12H(p.endTime)}';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: p.isActive ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                width: p.isActive ? 1.2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_offer_rounded, color: Color(0xFF059669), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Title (no truncation)
                      Text(
                        p.title.isNotEmpty ? p.title : 'Off-Peak Discount',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Badges Wrap (Discount & Branch)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              '${p.discountPercent}% OFF',
                              style: const TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (p.branchName.isNotEmpty && p.branchName != 'All Branches')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                p.branchName,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Responsive Schedule Row (Never overflows!)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1.5),
                            child: Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              timeDisplay,
                              softWrap: true,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 24,
                      child: Switch(
                        value: p.isActive,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF059669),
                        inactiveThumbColor: const Color(0xFF94A3B8),
                        inactiveTrackColor: const Color(0xFFE2E8F0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) async {
                          setState(() {
                            _promotions[i] = OwnerPromotion(
                              id: p.id,
                              branchId: p.branchId,
                              branchName: p.branchName,
                              title: p.title,
                              discountPercent: p.discountPercent,
                              timeWindow: p.timeWindow,
                              daysOfWeek: p.daysOfWeek,
                              startTime: p.startTime,
                              endTime: p.endTime,
                              isActive: val,
                            );
                          });
                          await ApiService.toggleOffPeakDiscount(p.id, val);
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _showAddEditDiscountModal(discount: p),
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
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // RUSH SURGE RULES TAB
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildRushRulesTab() {
    if (_rushRules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
                child: const Icon(Icons.bolt_rounded, size: 40, color: Color(0xFFD97706)),
              ),
              const SizedBox(height: 12),
              const Text('No Rush Surge Rules', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              const Text('Apply automatic rush hour or weekend surge fees during peak demand periods.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => _showAddEditSurgeRuleModal(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add First Surge Rule', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFFD97706),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        itemCount: _rushRules.length,
        itemBuilder: (_, i) {
          final r = _rushRules[i];
          final timeDisplay = r.timeSlot.isNotEmpty ? r.timeSlot : '${formatTime12H(r.startTime)} to ${formatTime12H(r.endTime)}';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: r.isEnabled ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                width: r.isEnabled ? 1.2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Title (no truncation)
                      Text(
                        r.title.isNotEmpty ? r.title : 'Rush Surge Rule',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Badges Wrap (Surge & Branch)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Text(
                              '+₹${r.surgeAmount.toStringAsFixed(0)} Surge',
                              style: const TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (r.branchName.isNotEmpty && r.branchName != 'All Branches')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                r.branchName,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Responsive Schedule Row (Never overflows!)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1.5),
                            child: Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              timeDisplay,
                              softWrap: true,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 24,
                      child: Switch(
                        value: r.isEnabled,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFFD97706),
                        inactiveThumbColor: const Color(0xFF94A3B8),
                        inactiveTrackColor: const Color(0xFFE2E8F0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) async {
                          setState(() {
                            _rushRules[i] = OwnerRushPricingRule(
                              id: r.id,
                              branchId: r.branchId,
                              branchName: r.branchName,
                              title: r.title,
                              surgeAmount: r.surgeAmount,
                              timeSlot: r.timeSlot,
                              daysOfWeek: r.daysOfWeek,
                              startTime: r.startTime,
                              endTime: r.endTime,
                              isEnabled: val,
                            );
                          });
                          await ApiService.toggleSurgeRule(r.id, val);
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _showAddEditSurgeRuleModal(rule: r),
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
          );
        },
      ),
    );
  }
}
