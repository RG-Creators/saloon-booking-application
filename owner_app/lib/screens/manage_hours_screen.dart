import 'package:flutter/material.dart';
import 'package:owner_app/models/models.dart';
import 'package:owner_app/services/api_service.dart';

class ManageHoursScreen extends StatefulWidget {
  final int? initialBranchId;
  const ManageHoursScreen({super.key, this.initialBranchId});

  @override
  State<ManageHoursScreen> createState() => _ManageHoursScreenState();
}

class _ManageHoursScreenState extends State<ManageHoursScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _applyToAllBranches = false;
  List<OwnerBranch> _branches = [];
  OwnerBranch? _selectedBranch;

  // Day metadata (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
  final List<String> _dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];
  final List<String> _dayShort = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT'
  ];

  List<Map<String, dynamic>> _hours = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final branches = await ApiService.getBranches();
    if (branches.isNotEmpty) {
      _branches = branches;
      if (widget.initialBranchId != null) {
        _selectedBranch = branches.firstWhere(
          (b) => b.id == widget.initialBranchId,
          orElse: () => branches.first,
        );
      } else {
        _selectedBranch = branches.first;
      }
      await _loadBranchHours(_selectedBranch!.id);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadBranchHours(int branchId) async {
    final data = await ApiService.getBranchHours(branchId);

    // Default week schedule (Mon-Sat open 10am-8pm, Sun closed)
    List<Map<String, dynamic>> defaultWeek = List.generate(7, (index) => {
      'day_of_week': index,
      'is_open': index != 0, // Sunday closed by default
      'open_time': '10:00:00',
      'close_time': '20:00:00',
      'has_split_shift': false,
      'split_open_time': null,
      'split_close_time': null,
    });

    if (data.isNotEmpty) {
      for (var d in data) {
        int dow = d['day_of_week'] is int
            ? d['day_of_week']
            : int.tryParse('${d['day_of_week']}') ?? 0;
        if (dow >= 0 && dow < 7) {
          defaultWeek[dow] = {
            'day_of_week': dow,
            'is_open': d['is_open'] == 1 || d['is_open'] == true,
            'open_time': d['open_time']?.toString() ?? '10:00:00',
            'close_time': d['close_time']?.toString() ?? '20:00:00',
            'has_split_shift':
                d['has_split_shift'] == 1 || d['has_split_shift'] == true,
            'split_open_time': d['split_open_time']?.toString(),
            'split_close_time': d['split_close_time']?.toString(),
          };
        }
      }
    }

    // Sort to show Monday first (1 -> 6, then 0)
    defaultWeek.sort((a, b) {
      int da = a['day_of_week'] == 0 ? 7 : a['day_of_week'];
      int db = b['day_of_week'] == 0 ? 7 : b['day_of_week'];
      return da.compareTo(db);
    });

    setState(() {
      _hours = defaultWeek;
    });
  }

  // --- BULK PRESETS & QUICK TOOLS ---

  void _applyMondayToAllDays() {
    final monday = _hours.firstWhere(
      (h) => h['day_of_week'] == 1,
      orElse: () => _hours.first,
    );

    setState(() {
      for (var h in _hours) {
        if (h['day_of_week'] != 1) {
          h['is_open'] = monday['is_open'];
          h['open_time'] = monday['open_time'];
          h['close_time'] = monday['close_time'];
          h['has_split_shift'] = monday['has_split_shift'];
          h['split_open_time'] = monday['split_open_time'];
          h['split_close_time'] = monday['split_close_time'];
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(Icons.flash_on_rounded, color: Color(0xFFFBBF24), size: 18),
            SizedBox(width: 8),
            Text("Monday's schedule copied to all days!"),
          ],
        ),
      ),
    );
  }

  void _copyDayScheduleToAll(int sourceDow, {bool weekdaysOnly = false}) {
    final source = _hours.firstWhere((h) => h['day_of_week'] == sourceDow);
    setState(() {
      for (var h in _hours) {
        final dow = h['day_of_week'];
        if (dow == sourceDow) continue;
        if (weekdaysOnly && (dow == 0 || dow == 6)) continue;

        h['is_open'] = source['is_open'];
        h['open_time'] = source['open_time'];
        h['close_time'] = source['close_time'];
        h['has_split_shift'] = source['has_split_shift'];
        h['split_open_time'] = source['split_open_time'];
        h['split_close_time'] = source['split_close_time'];
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        content: Text(
          weekdaysOnly
              ? "${_dayNames[sourceDow]}'s schedule copied to Weekdays (Mon-Fri)!"
              : "${_dayNames[sourceDow]}'s schedule copied to All Days!",
        ),
      ),
    );
  }

  void _applyStandardPreset({bool withSplit = false}) {
    setState(() {
      for (var h in _hours) {
        final dow = h['day_of_week'];
        h['is_open'] = dow != 0; // Mon-Sat open, Sun closed
        if (withSplit) {
          h['open_time'] = '10:00:00';
          h['close_time'] = '14:00:00';
          h['has_split_shift'] = true;
          h['split_open_time'] = '16:00:00';
          h['split_close_time'] = '20:00:00';
        } else {
          h['open_time'] = '10:00:00';
          h['close_time'] = '20:00:00';
          h['has_split_shift'] = false;
          h['split_open_time'] = null;
          h['split_close_time'] = null;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        content: Text(
          withSplit
              ? 'Split shift (10-2 PM & 4-8 PM) applied Mon-Sat!'
              : 'Standard shift (10 AM - 8 PM) applied Mon-Sat!',
        ),
      ),
    );
  }

  // --- SAVE OPERATION ---

  Future<void> _saveHours() async {
    if (_selectedBranch == null) return;
    setState(() => _isSaving = true);

    final res = await ApiService.updateBranchHours(
      _selectedBranch!.id,
      _hours,
      applyToAllBranches: _applyToAllBranches,
    );

    setState(() => _isSaving = false);
    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    res['message'] ?? 'Operating hours saved successfully!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    res['message'] ?? 'Failed to save hours. Please try again.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  String _formatTimeStr(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    try {
      final clean = timeStr.trim();
      final parts = clean.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final tod = TimeOfDay(hour: hour, minute: minute);
        final hourFormatted = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
        final ampm = tod.period == DayPeriod.am ? 'AM' : 'PM';
        final mStr = tod.minute.toString().padLeft(2, '0');
        return '$hourFormatted:$mStr $ampm';
      }
      return timeStr;
    } catch (_) {
      return timeStr;
    }
  }

  // --- UPLIFTED BRANCH SELECTOR MODAL ---

  void _showBranchPickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Salon Branch',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choose which branch schedule to configure',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _branches.map((b) {
                      final isSelected = b.id == _selectedBranch?.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? const Color(0xFF4F46E5).withValues(alpha: 0.08)
                                  : const Color(0xFF0F172A).withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          onTap: () {
                            Navigator.pop(ctx);
                            if (b.id != _selectedBranch?.id) {
                              setState(() => _selectedBranch = b);
                              _loadBranchHours(b.id);
                            }
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isSelected
                                    ? [const Color(0xFF4F46E5), const Color(0xFF6366F1)]
                                    : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                              size: 22,
                            ),
                          ),
                          title: Text(
                            b.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: isSelected
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            '${b.city}${b.address.isNotEmpty ? ' • ${b.address}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF4F46E5), size: 24)
                              : const Icon(Icons.radio_button_unchecked_rounded,
                                  color: Color(0xFF94A3B8), size: 20),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openEditSheet(int index) {
    final dayData = _hours[index];
    final dow = dayData['day_of_week'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isOpen = dayData['is_open'] == true;
            final hasSplit = dayData['has_split_shift'] == true;

            Widget buildTimeCard({
              required String label,
              required String fieldKey,
              required IconData icon,
              required Color accentColor,
            }) {
              return Expanded(
                child: InkWell(
                  onTap: () async {
                    final currentStr = dayData[fieldKey];
                    TimeOfDay initial = const TimeOfDay(hour: 10, minute: 0);
                    if (currentStr != null && currentStr.isNotEmpty) {
                      final parts = currentStr.toString().split(':');
                      if (parts.length >= 2) {
                        initial = TimeOfDay(
                          hour: int.tryParse(parts[0]) ?? 10,
                          minute: int.tryParse(parts[1]) ?? 0,
                        );
                      }
                    }
                    final selected = await showTimePicker(
                      context: context,
                      initialTime: initial,
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: ColorScheme.light(
                              primary: accentColor,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: const Color(0xFF0F172A),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (selected != null) {
                      final hStr = selected.hour.toString().padLeft(2, '0');
                      final mStr = selected.minute.toString().padLeft(2, '0');
                      setModalState(() {
                        dayData[fieldKey] = '$hStr:$mStr:00';
                      });
                      setState(() {});
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 14, color: accentColor),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formatTimeStr(dayData[fieldKey]),
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
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
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isOpen
                                  ? [const Color(0xFF4F46E5), const Color(0xFF6366F1)]
                                  : [const Color(0xFF94A3B8), const Color(0xFF64748B)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              _dayShort[dow],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_dayNames[dow]} Timing',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                isOpen
                                    ? 'Salon is open & taking bookings'
                                    : 'Salon is closed on this day',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOpen
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Open / Closed Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isOpen ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOpen ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  isOpen ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: isOpen ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    isOpen ? 'Open for Business' : 'Closed Today',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isOpen ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isOpen,
                            activeThumbColor: const Color(0xFF059669),
                            activeTrackColor: const Color(0xFFA7F3D0),
                            inactiveThumbColor: const Color(0xFF94A3B8),
                            inactiveTrackColor: const Color(0xFFE2E8F0),
                            onChanged: (val) {
                              setModalState(() {
                                dayData['is_open'] = val;
                              });
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),

                    if (isOpen) ...[
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Icon(Icons.wb_sunny_rounded, size: 16, color: Color(0xFFF59E0B)),
                          SizedBox(width: 6),
                          Text(
                            'Shift 1 / Main Operating Hours',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          buildTimeCard(
                            label: 'OPENS AT',
                            fieldKey: 'open_time',
                            icon: Icons.login_rounded,
                            accentColor: const Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 10),
                          buildTimeCard(
                            label: hasSplit ? 'BREAK STARTS' : 'CLOSES AT',
                            fieldKey: 'close_time',
                            icon: Icons.logout_rounded,
                            accentColor: const Color(0xFF4F46E5),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Split Shift Toggle Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.free_breakfast_rounded, size: 18, color: Color(0xFF6366F1)),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Enable Split Shift',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          'Lunch break / Afternoon closure',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: hasSplit,
                              activeThumbColor: const Color(0xFF6366F1),
                              activeTrackColor: const Color(0xFFC7D2FE),
                              inactiveThumbColor: const Color(0xFF94A3B8),
                              inactiveTrackColor: const Color(0xFFE2E8F0),
                              onChanged: (val) {
                                setModalState(() {
                                  dayData['has_split_shift'] = val;
                                  if (val &&
                                      (dayData['split_open_time'] == null ||
                                          dayData['split_open_time'] == '')) {
                                    dayData['close_time'] = '14:00:00';
                                    dayData['split_open_time'] = '16:00:00';
                                    dayData['split_close_time'] = '20:00:00';
                                  }
                                });
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),

                      if (hasSplit) ...[
                        const SizedBox(height: 14),
                        const Row(
                          children: [
                            Icon(Icons.nights_stay_rounded, size: 16, color: Color(0xFF6366F1)),
                            SizedBox(width: 6),
                            Text(
                              'Shift 2 / Evening Operating Hours',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            buildTimeCard(
                              label: 'RE-OPENS AT',
                              fieldKey: 'split_open_time',
                              icon: Icons.login_rounded,
                              accentColor: const Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 10),
                            buildTimeCard(
                              label: 'FINAL CLOSE',
                              fieldKey: 'split_close_time',
                              icon: Icons.logout_rounded,
                              accentColor: const Color(0xFF6366F1),
                            ),
                          ],
                        ),
                      ],
                    ],

                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 14),

                    // Quick Copy Actions Inside Sheet
                    const Text(
                      'QUICK APPLY THIS TIMING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _copyDayScheduleToAll(dow, weekdaysOnly: true);
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.business_rounded, size: 14),
                            label: const Text('To Weekdays',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4F46E5),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _copyDayScheduleToAll(dow, weekdaysOnly: false);
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.calendar_month_rounded, size: 14),
                            label: const Text('To All 7 Days',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4F46E5),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Done Editing',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Branch Hours & Shifts',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              'Configure business schedule & breaks',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'mon_to_all') _applyMondayToAllDays();
              if (val == 'standard_10_8') _applyStandardPreset(withSplit: false);
              if (val == 'split_preset') _applyStandardPreset(withSplit: true);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'mon_to_all',
                child: Row(
                  children: [
                    Icon(Icons.flash_on_rounded, color: Color(0xFFF59E0B), size: 18),
                    SizedBox(width: 10),
                    Text('Copy Monday to All Days',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'standard_10_8',
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: Color(0xFF4F46E5), size: 18),
                    SizedBox(width: 10),
                    Text('Set Mon-Sat 10 AM – 8 PM',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'split_preset',
                child: Row(
                  children: [
                    Icon(Icons.free_breakfast_rounded, color: Color(0xFF6366F1), size: 18),
                    SizedBox(width: 10),
                    Text('Set Split Shift (10-2, 4-8)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : _branches.isEmpty
              ? const Center(child: Text('No active branches found for this salon.'))
              : Column(
                  children: [
                    // Top Modern Uplifted Branch Switcher Card & Presets
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Luxury Uplifted Branch Switcher Card
                          InkWell(
                            onTap: _branches.length > 1 ? _showBranchPickerModal : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFC7D2FE), width: 1.3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.storefront_rounded,
                                        color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                _selectedBranch?.name ?? 'Main Branch',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF0F172A),
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'ACTIVE',
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF059669),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _selectedBranch != null
                                              ? '${_selectedBranch!.city}${_selectedBranch!.address.isNotEmpty ? ' • ${_selectedBranch!.address}' : ''}'
                                              : 'Operating location',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_branches.length > 1) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFFC7D2FE)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Switch',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                          SizedBox(width: 2),
                                          Icon(Icons.unfold_more_rounded,
                                              size: 14, color: Color(0xFF4F46E5)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Quick Action Horizontal Pills
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildActionChip(
                                  icon: Icons.flash_on_rounded,
                                  iconColor: const Color(0xFFF59E0B),
                                  label: 'Copy Mon to All',
                                  onTap: _applyMondayToAllDays,
                                ),
                                const SizedBox(width: 8),
                                _buildActionChip(
                                  icon: Icons.schedule_rounded,
                                  iconColor: const Color(0xFF4F46E5),
                                  label: '10 AM – 8 PM (Standard)',
                                  onTap: () => _applyStandardPreset(withSplit: false),
                                ),
                                const SizedBox(width: 8),
                                _buildActionChip(
                                  icon: Icons.free_breakfast_rounded,
                                  iconColor: const Color(0xFF6366F1),
                                  label: 'Split Shift (10-2 & 4-8)',
                                  onTap: () => _applyStandardPreset(withSplit: true),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Day by Day Schedule List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 14, bottom: 120),
                        itemCount: _hours.length,
                        itemBuilder: (_, i) {
                          final h = _hours[i];
                          final dow = h['day_of_week'] is int
                              ? h['day_of_week']
                              : int.tryParse('${h['day_of_week']}') ?? 0;
                          final isOpen = h['is_open'] == true;
                          final hasSplit = h['has_split_shift'] == true;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isOpen
                                    ? const Color(0xFFE0E7FF)
                                    : const Color(0xFFF1F5F9),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openEditSheet(i),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Day Badge
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: isOpen
                                              ? const Color(0xFFEEF2FF)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _dayShort[dow],
                                              style: TextStyle(
                                                color: isOpen
                                                    ? const Color(0xFF4F46E5)
                                                    : const Color(0xFF94A3B8),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            Container(
                                              width: 5,
                                              height: 5,
                                              margin: const EdgeInsets.only(top: 2),
                                              decoration: BoxDecoration(
                                                color: isOpen
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFFEF4444),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Day Info & Timing (Safely Wrapped to Prevent Overflow)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    _dayNames[dow],
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Color(0xFF0F172A),
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                if (hasSplit && isOpen) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 5, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEEF2FF),
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.bolt_rounded,
                                                            size: 10,
                                                            color: Color(0xFF6366F1)),
                                                        Text(
                                                          'Split',
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w800,
                                                            color: Color(0xFF4F46E5),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            if (!isOpen)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF2F2),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Closed for Bookings',
                                                  style: TextStyle(
                                                    color: Color(0xFFDC2626),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              )
                                            else
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  _buildTimingPill(
                                                    '${_formatTimeStr(h['open_time'])} – ${_formatTimeStr(h['close_time'])}',
                                                    isPrimary: true,
                                                  ),
                                                  if (hasSplit) ...[
                                                    const SizedBox(height: 3),
                                                    _buildTimingPill(
                                                      '${_formatTimeStr(h['split_open_time'])} – ${_formatTimeStr(h['split_close_time'])}',
                                                      isPrimary: false,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),

                                      // Edit Switch & Chevron
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Switch(
                                            value: isOpen,
                                            activeThumbColor: const Color(0xFF4F46E5),
                                            activeTrackColor: const Color(0xFFC7D2FE),
                                            inactiveThumbColor: const Color(0xFF94A3B8),
                                            inactiveTrackColor: const Color(0xFFF1F5F9),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                            onChanged: (val) {
                                              setState(() {
                                                h['is_open'] = val;
                                              });
                                            },
                                          ),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: Color(0xFF94A3B8),
                                            size: 18,
                                          ),
                                        ],
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
                  ],
                ),

      // Sticky Bottom Save Bar
      bottomNavigationBar: _branches.isEmpty || _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_branches.length > 1) ...[
                      InkWell(
                        onTap: () => setState(
                            () => _applyToAllBranches = !_applyToAllBranches),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _applyToAllBranches,
                                  activeColor: const Color(0xFF4F46E5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                  onChanged: (val) => setState(() =>
                                      _applyToAllBranches = val ?? false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sync this schedule across all ${_branches.length} branches',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveHours,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isSaving
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Saving Schedule...',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _applyToAllBranches
                                        ? 'Save for All ${_branches.length} Branches'
                                        : 'Save Operating Schedule',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingPill(String text, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFF8FAFC) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPrimary ? const Color(0xFFE2E8F0) : const Color(0xFFC7D2FE),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPrimary ? Icons.access_time_rounded : Icons.nights_stay_rounded,
              size: 11,
              color: isPrimary ? const Color(0xFF64748B) : const Color(0xFF4F46E5),
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isPrimary ? const Color(0xFF1E293B) : const Color(0xFF4338CA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
