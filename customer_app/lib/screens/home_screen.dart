import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'salon_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SalonBranch> _salons = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();
  final _locationService = LocationService();

  final List<String> _categories = [
    'All',
    'Hair & Styling',
    'Facials & Skin',
    'Spa & Grooming',
    '?? Doorstep Home Visits',
    '?? Wedding & Events',
  ];

  @override
  void initState() {
    super.initState();
    _initLocationAndFetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndFetch() async {
    setState(() => _isLoading = true);
    await _locationService.getCurrentLocation();
    await _loadSalons();
  }

  Future<void> _loadSalons({String? query}) async {
    setState(() => _isLoading = true);
    List<SalonBranch> list = [];

    final pos = _locationService.currentPosition;
    final city = _locationService.currentCity;

    if (query != null && query.trim().isNotEmpty) {
      list = await ApiService.searchSalons(query.trim(), lat: pos?.latitude, lng: pos?.longitude);
    } else {
      list = await ApiService.getNearbySalons(
        city: city,
        lat: pos?.latitude,
        lng: pos?.longitude,
      );
    }

    if (!mounted) return;
    setState(() {
      _salons = list;
      _isLoading = false;
    });
  }

  List<SalonBranch> get _filteredSalons {
    if (_selectedCategory == 'All') return _salons;
    if (_selectedCategory == '?? Doorstep Home Visits') {
      return _salons.where((s) => s.features.homeServiceEnabled).toList();
    }
    if (_selectedCategory == '?? Wedding & Events') {
      return _salons.where((s) => s.features.eventWeddingEnabled).toList();
    }
    return _salons.where((s) {
      return s.services.any((svc) => svc.category.toLowerCase().contains(_selectedCategory.toLowerCase().split(' ').first));
    }).toList();
  }

  void _showCitySelector() {
    final cities = ['New Delhi', 'Mumbai', 'Bengaluru', 'Gurugram', 'Noida', 'Kolkata', 'Hyderabad', 'Pune'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Your City / Region', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cities.map((c) => ActionChip(
                backgroundColor: _locationService.currentCity == c ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                side: BorderSide(color: _locationService.currentCity == c ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                label: Text(c, style: TextStyle(
                  color: _locationService.currentCity == c ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                )),
                onPressed: () {
                  Navigator.pop(ctx);
                  _locationService.setManualCity(c);
                  _loadSalons();
                },
              )).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _initLocationAndFetch();
                },
                icon: const Icon(Icons.my_location_rounded, size: 18),
                label: const Text('Use Current GPS Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: const BorderSide(color: Color(0xFF4F46E5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salons = _filteredSalons;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _initLocationAndFetch,
          color: const Color(0xFF4F46E5),
          child: CustomScrollView(
            slivers: [
              // Top Location & Search Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Bar Row
                      GestureDetector(
                        onTap: _showCitySelector,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.location_on_rounded, color: Color(0xFF4F46E5), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _locationService.currentCity,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                  Text(
                                    _locationService.currentArea,
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search Box
                      TextField(
                        controller: _searchController,
                        onSubmitted: (v) => _loadSalons(query: v),
                        decoration: InputDecoration(
                          hintText: 'Search salon, hair stylist, spa...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadSalons();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories Horizontal Bar
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF4F46E5),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        showCheckmark: false,
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                      );
                    },
                  ),
                ),
              ),

              // Title Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Verified Salons Nearby',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${salons.length} found',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              // Salons List
              _isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
                    )
                  : salons.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.storefront_outlined, size: 54, color: Color(0xFFCBD5E1)),
                                const SizedBox(height: 12),
                                Text(
                                  'No salons found in this location.',
                                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _showCitySelector,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Change Location'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final salon = salons[index];
                                return _buildSalonCard(context, salon);
                              },
                              childCount: salons.length,
                            ),
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalonCard(BuildContext context, SalonBranch salon) {
    final status = salon.status;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SalonDetailsScreen(branch: salon)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar/Icon + Salon Name + Rating
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.store_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salon.businessName,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          salon.businessType,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                            const SizedBox(width: 3),
                            Text(
                              '${salon.rating} (${salon.reviewsCount})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('�', style: TextStyle(color: Color(0xFFCBD5E1))),
                            const SizedBox(width: 8),
                            // Distance Badge
                            Icon(Icons.near_me_rounded, size: 12, color: const Color(0xFF4F46E5)),
                            const SizedBox(width: 2),
                            Text(
                              salon.distanceText,
                              style: const TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 12),

              // Address Row
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${salon.address}, ${salon.city}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Status & Modality Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // Live Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: status.statusColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: status.statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          status.statusLabel,
                          style: TextStyle(
                            color: status.statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                        if (status.statusSubtitle.isNotEmpty) ...[
                          Text(' � ${status.statusSubtitle}', style: TextStyle(color: status.statusColor, fontSize: 10.5, fontWeight: FontWeight.w500)),
                        ],
                      ],
                    ),
                  ),

                  // Home Service badge
                  if (salon.features.homeServiceEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home_rounded, size: 12, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text('?? At-Home Visits', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),

                  // Wedding service badge
                  if (salon.features.eventWeddingEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.diamond_rounded, size: 12, color: Color(0xFFD97706)),
                          SizedBox(width: 4),
                          Text('?? Bridal & Events', style: TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Bottom Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Starting from', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600)),
                      Text(
                        '?${salon.minPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SalonDetailsScreen(branch: salon)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    label: const Text('View Services', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
