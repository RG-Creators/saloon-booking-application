import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class AddEditStaffScreen extends StatefulWidget {
  final Map<String, dynamic>? staff;

  const AddEditStaffScreen({super.key, this.staff});

  @override
  State<AddEditStaffScreen> createState() => _AddEditStaffScreenState();
}

class _AddEditStaffScreenState extends State<AddEditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _roleController = TextEditingController(text: 'Stylist');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isBookable = true;
  bool _isActive = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  List<OwnerService> _availableServices = [];
  List<OwnerCombo> _availableCombos = [];
  Set<int> _selectedServiceIds = {};
  Set<int> _selectedComboIds = {};
  bool _isLoadingServices = true;

  late String _shopDomain;

  static const List<String> _quickRoles = [
    'Stylist',
    'Senior Stylist',
    'Hair Specialist',
    'Facial Expert',
    'Makeup Artist',
    'Barber',
    'Nail Artist',
    'Masseuse',
    'Staff',
    'Manager',
  ];

  @override
  void initState() {
    super.initState();
    String baseName = ApiService.currentShopName ?? 'shop';
    baseName = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    if (baseName.isEmpty) baseName = 'shop';
    _shopDomain = '@$baseName.com';

    if (widget.staff != null) {
      _nameController.text = (widget.staff!['name'] ?? '').toString();
      _phoneController.text = (widget.staff!['mobile'] ?? '').toString();
      
      final rawRole = widget.staff!['role']?.toString().trim();
      if (rawRole != null && rawRole.isNotEmpty) {
        _roleController.text = rawRole;
      } else {
        _roleController.text = 'Stylist';
      }

      _isBookable = widget.staff!['is_bookable'] == true || widget.staff!['is_bookable'] == 1;
      _isActive = widget.staff!['is_active'] == true || widget.staff!['is_active'] == 1;

      String fullEmail = (widget.staff!['email'] ?? '').toString().trim();
      if (fullEmail.toLowerCase().endsWith(_shopDomain.toLowerCase())) {
        _usernameController.text = fullEmail.substring(0, fullEmail.length - _shopDomain.length);
      } else if (fullEmail.contains('@')) {
        _usernameController.text = fullEmail.split('@').first;
      } else {
        _usernameController.text = fullEmail;
      }

      if (widget.staff!['services'] is List) {
        for (var s in widget.staff!['services']) {
          if (s is Map && s['id'] != null) {
            _selectedServiceIds.add(s['id'] as int);
          } else if (s is OwnerService) {
            _selectedServiceIds.add(s.id);
          }
        }
      }
    }

    _loadAvailableServices();
  }

  Future<void> _loadAvailableServices() async {
    try {
      final results = await Future.wait([
        ApiService.getServices(),
        ApiService.getCombos(),
      ]);
      if (!mounted) return;
      final services = results[0] as List<OwnerService>;
      final combos = results[1] as List<OwnerCombo>;

      setState(() {
        _availableServices = services;
        _availableCombos = combos;
        _isLoadingServices = false;
        if (widget.staff == null && _selectedServiceIds.isEmpty && services.isNotEmpty) {
          _selectedServiceIds = services.map((s) => s.id).toSet();
          _selectedComboIds = combos.map((c) => c.id).toSet();
        } else {
          for (var combo in combos) {
            if (combo.services.isNotEmpty && combo.services.every((s) => _selectedServiceIds.contains(s.id))) {
              _selectedComboIds.add(combo.id);
            }
          }
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingServices = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _roleController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isAllRounder =>
      _availableServices.isNotEmpty && _selectedServiceIds.length == _availableServices.length;

  void _toggleAllServices() {
    setState(() {
      if (_isAllRounder) {
        _selectedServiceIds.clear();
        _selectedComboIds.clear();
      } else {
        _selectedServiceIds = _availableServices.map((s) => s.id).toSet();
        _selectedComboIds = _availableCombos.map((c) => c.id).toSet();
      }
    });
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final username = _usernameController.text.trim().replaceAll('@', '');

    setState(() => _isSaving = true);

    String? email = username.isNotEmpty ? '$username$_shopDomain' : null;

    final data = <String, dynamic>{
      'branch_id': 1,
      'name': _nameController.text.trim(),
      'mobile': phone,
      'email': email,
      'is_bookable': _isBookable,
      'is_active': _isActive,
      'role': _roleController.text.trim().isEmpty ? 'Stylist' : _roleController.text.trim(),
      'service_ids': _selectedServiceIds.toList(),
    };

    if (widget.staff == null) {
      data['create_login'] = true;
      data['password'] = _passwordController.text.trim().isNotEmpty
          ? _passwordController.text.trim()
          : 'password123';
    }

    Map<String, dynamic> res;
    if (widget.staff == null) {
      res = await ApiService.createStaff(data);
    } else {
      res = await ApiService.updateStaff(widget.staff!['id'], data);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res['success'] == true) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(res['message'] ?? 'Staff saved successfully!')),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(res['message'] ?? 'Failed to save staff')),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _deleteStaff() async {
    final staffName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'this staff member';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text('Remove Staff', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
          ],
        ),
        content: Text('Are you sure you want to remove "$staffName"? Their login and booking assignments will be removed.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            label: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    final res = await ApiService.deleteStaff(widget.staff!['id']);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (res['success'] == true) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$staffName" was removed successfully.'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to remove staff member.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    final passwordController = TextEditingController();
    final staffName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Staff';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Color(0xFF4F46E5), size: 22),
            SizedBox(width: 8),
            Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New login password for $staffName:',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: 'Min 8 characters',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF6366F1), size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
              obscureText: true,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (passwordController.text.length < 8) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 8 characters')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );

    if (result == true) {
      final res = await ApiService.resetStaffPassword(widget.staff!['id'], passwordController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Password updated successfully!'),
          backgroundColor: res['success'] == true ? const Color(0xFF059669) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.staff != null;
    final initial = _nameController.text.trim().isNotEmpty ? _nameController.text.trim()[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Staff Member' : 'New Staff Onboarding',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
              tooltip: 'Remove Staff',
              onPressed: _isDeleting ? null : _deleteStaff,
            ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card for Editing
              if (isEditing) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Staff Member',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: #${widget.staff!['id']} • ${_roleController.text.trim()} • ${_selectedServiceIds.length} Services',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Section 1: Staff Details
              _SectionCard(
                title: 'Staff Information',
                icon: Icons.person_rounded,
                iconColor: const Color(0xFF4F46E5),
                children: [
                  _RequiredLabel(label: 'Full Name'),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'e.g. Ravi Sharma',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.normal),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 18),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Staff full name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Role / Specialization (Input Field + Quick Suggestions)
                  _RequiredLabel(label: 'Role / Designation'),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _roleController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'e.g. Senior Stylist / Facial Expert',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.normal),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                      prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF64748B), size: 18),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please specify a role or designation';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _quickRoles.map((role) {
                        final isSelected = _roleController.text.trim().toLowerCase() == role.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(
                              role,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                              ),
                            ),
                            backgroundColor: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                            side: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            onPressed: () {
                              setState(() {
                                _roleController.text = role;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Section 2: Assigned Services & All-Rounder Capability
              _SectionCard(
                title: 'Assigned Services & Skills',
                icon: Icons.format_list_bulleted_rounded,
                iconColor: const Color(0xFF7C3AED),
                children: [
                  // Master All-Rounder Toggle Box (Compact)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isAllRounder ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isAllRounder ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
                        width: _isAllRounder ? 1.2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isAllRounder ? Icons.star_rounded : Icons.star_border_rounded,
                          color: _isAllRounder ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isAllRounder ? '⭐ All-Rounder (All Services)' : 'All-Rounder Option',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: _isAllRounder ? const Color(0xFF6D28D9) : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                _isAllRounder
                                    ? 'Performs all salon catalog services'
                                    : 'Tap switch to assign all services at once',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          child: Switch(
                            value: _isAllRounder,
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFF7C3AED),
                            inactiveThumbColor: const Color(0xFF94A3B8),
                            inactiveTrackColor: const Color(0xFFE2E8F0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (_) => _toggleAllServices(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Combo Packages Multi-Select Section
                  if (_availableCombos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.layers_rounded, size: 14, color: Color(0xFFD97706)),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Combo Packages:',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                        Text(
                          '${_selectedComboIds.length} of ${_availableCombos.length} selected',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _availableCombos.map((combo) {
                        final isSelected = _selectedComboIds.contains(combo.id);
                        return FilterChip(
                          avatar: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14)
                              : const Icon(Icons.layers_outlined, color: Color(0xFFD97706), size: 14),
                          label: Text(
                            '${combo.name} (₹${combo.price.toStringAsFixed(0)})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF78350F),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFD97706),
                          backgroundColor: const Color(0xFFFFFDF5),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFD97706) : const Color(0xFFFDE68A),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          showCheckmark: false,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedComboIds.add(combo.id);
                                for (var s in combo.services) {
                                  _selectedServiceIds.add(s.id);
                                }
                              } else {
                                _selectedComboIds.remove(combo.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Individual Services Multi-Select Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.spa_rounded, size: 14, color: Color(0xFF4F46E5)),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Individual Services:',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                      if (_isLoadingServices)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (_availableServices.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _availableServices.map((service) {
                        final isSelected = _selectedServiceIds.contains(service.id);
                        return FilterChip(
                          avatar: isSelected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                              : const Icon(Icons.add_rounded, color: Color(0xFF64748B), size: 14),
                          label: Text(
                            '${service.name} (₹${service.price.toStringAsFixed(0)})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF7C3AED),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          showCheckmark: false,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedServiceIds.add(service.id);
                              } else {
                                _selectedServiceIds.remove(service.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    )
                  else if (!_isLoadingServices)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text('No salon services found. Please add services first.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    '${_selectedServiceIds.length} of ${_availableServices.length} services currently attached',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Section 3: Login Credentials
              _SectionCard(
                title: 'Login Credentials',
                icon: Icons.vpn_key_rounded,
                iconColor: const Color(0xFF059669),
                children: [
                  _RequiredLabel(label: 'Mobile Number'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _phoneController,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'e.g. 9876543210',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.normal),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
                      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF64748B), size: 18),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Mobile number is required';
                      }
                      if (!RegExp(r'^\d{10}$').hasMatch(val.trim())) {
                        return 'Please enter a valid 10-digit mobile number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Staff Username Input (Optional)
                  const Text('Staff Username (Optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _usernameController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.3,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter username (e.g. ravi)',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.normal),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                      prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF6366F1), size: 18),
                    ),
                    validator: (val) {
                      if (val != null && val.contains('@')) {
                        return 'Do not enter "@". The domain $_shopDomain is attached automatically.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),

                  // Real-Time Generated Email Preview Pill (Compact)
                  if (_usernameController.text.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF4F46E5)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                                children: [
                                  const TextSpan(text: 'Full Login Email: '),
                                  TextSpan(
                                    text: '${_usernameController.text.trim().replaceAll('@', '')}$_shopDomain',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Password field (only on creation)
                  if (!isEditing) ...[
                    const Text('Login Password (Optional - defaults to password123)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155))),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'Default: password123',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.normal),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF64748B), size: 18),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (val) {
                        if (val != null && val.isNotEmpty && val.length < 8) {
                          return 'Password must be at least 8 characters long';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Section 4: Availability & Booking (Compact)
              _SectionCard(
                title: 'Operational Settings',
                icon: Icons.tune_rounded,
                iconColor: const Color(0xFFD97706),
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Accepts Customer Bookings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                    subtitle: const Text('Stylist will be visible in customer appointment slots', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    activeTrackColor: const Color(0xFF059669),
                    value: _isBookable,
                    onChanged: (val) => setState(() => _isBookable = val),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Account Active', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                    subtitle: const Text('Allow this staff member to authenticate in Partner App', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    activeTrackColor: const Color(0xFF059669),
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Reset Password Button (When editing)
              if (isEditing) ...[
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: _resetPassword,
                    icon: const Icon(Icons.lock_reset_rounded, color: Color(0xFF4F46E5), size: 18),
                    label: const Text('Reset Staff Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF4F46E5))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: const Color(0xFFEEF2FF),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Save / Update Button (Centered Text & Uplifted for 3-Button Navigation)
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    elevation: 0,
                    alignment: Alignment.center,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _saveStaff,
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEditing ? 'Save Staff Changes' : 'Create Staff Profile',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _RequiredLabel extends StatelessWidget {
  final String label;
  const _RequiredLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF334155)),
          ),
          const TextSpan(
            text: ' *',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
