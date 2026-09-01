import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:simple_animations/simple_animations.dart';
import '../services/api_service.dart';

class RegisterShopScreen extends StatefulWidget {
  const RegisterShopScreen({super.key});

  @override
  State<RegisterShopScreen> createState() => _RegisterShopScreenState();
}

class _RegisterShopScreenState extends State<RegisterShopScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _slugController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;

  String? _selectedState;
  String? _selectedCity;
  final TextEditingController _cityController = TextEditingController();
  final FocusNode _cityFocusNode = FocusNode();
  bool _isLoading = false;

  List<String> _statesList = [];
  List<String> _citiesList = [];
  bool _isLoadingStates = true;
  bool _isLoadingCities = false;

  // ---------- ALL ORIGINAL METHODS REMAIN UNCHANGED ----------
  @override
  void initState() {
    super.initState();
    _shopNameController.addListener(_onShopNameChanged);
    _fetchStatesInit();
  }

  Future<void> _fetchStatesInit() async {
    final states = await ApiService.fetchStates();
    if (mounted) {
      setState(() {
        if (states.isNotEmpty) {
          _statesList = states;
        } else {
          _statesList = ['Maharashtra', 'Delhi', 'Karnataka', 'Tamil Nadu', 'Gujarat'];
        }
        _isLoadingStates = false;
      });
    }
  }

  Future<void> _onStateSelected(String state) async {
    setState(() {
      _selectedState = state;
      _selectedCity = null;
      _citiesList = [];
      _isLoadingCities = true;
      _pincodeController.clear();
    });

    final cities = await ApiService.fetchCities(state);
    if (mounted) {
      setState(() {
        _citiesList = cities.isNotEmpty ? cities : ['Mumbai', 'Delhi'];
        _isLoadingCities = false;
      });
    }
  }

  Future<void> _onCitySelected(String city) async {
    setState(() {
      _selectedCity = city;
    });

    final pin = await ApiService.fetchPincodeForCity(city);
    if (mounted && pin != null) {
      setState(() {
        _pincodeController.text = pin;
      });
    }
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _shopNameController.dispose();
    _slugController.dispose();
    _pincodeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _cityFocusNode.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onShopNameChanged() {
    final text = _shopNameController.text.trim().toLowerCase();
    final slug = text
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
    _slugController.text = slug;
  }

  Future<void> _autoDetectLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      }
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detecting location...')));
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final apiResult = await ApiService.detectLocation(lat: position.latitude, lng: position.longitude);

      List<geo.Placemark> placemarks = [];
      try {
        placemarks = await geo.Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
      } catch (e) {
        print("Geocoding exception: $e");
      }

      String detectedState = '';
      String detectedCity = '';
      String detectedPincode = '';
      String detectedAddress = '';

      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        detectedState = place.administrativeArea ?? '';

        String subLocality = place.subLocality ?? '';
        String locality = place.locality ?? '';

        if (subLocality.isNotEmpty && !subLocality.contains('+')) {
          detectedCity = subLocality;
        } else if (locality.isNotEmpty && !locality.contains('+')) {
          detectedCity = locality;
        } else {
          detectedCity = place.subAdministrativeArea ?? '';
        }

        detectedPincode = place.postalCode ?? '';

        List<String> addressParts = [];

        String street = place.street ?? '';
        String adminArea = place.administrativeArea ?? '';
        String country = place.country ?? '';

        if (street.isNotEmpty && !street.contains('+')) addressParts.add(street);
        if (subLocality.isNotEmpty && !subLocality.contains('+') && subLocality != street)
          addressParts.add(subLocality);
        if (locality.isNotEmpty && !locality.contains('+') && locality != subLocality)
          addressParts.add(locality);
        if (adminArea.isNotEmpty && !adminArea.contains('+') && adminArea != locality)
          addressParts.add(adminArea);
        if (country.isNotEmpty && !country.contains('+') && country != adminArea)
          addressParts.add(country);

        detectedAddress = addressParts.join(', ');
      }

      if (detectedState.isEmpty && apiResult['success'] == true) {
        final apiData = apiResult['data'];
        detectedState = apiData['state'] ?? detectedState;
        detectedCity = apiData['city'] ?? detectedCity;
        detectedPincode = apiData['zipcode'] ?? detectedPincode;
        detectedAddress = apiData['address'] ?? detectedAddress;
      }

      setState(() {
        if (!_statesList.contains(detectedState)) {
          _statesList.add(detectedState);
        }

        _selectedState = detectedState;

        if (!_citiesList.contains(detectedCity)) {
          _citiesList.add(detectedCity);
        }

        _selectedCity = detectedCity;
        _cityController.text = detectedCity;

        if (detectedPincode.isNotEmpty) {
          _pincodeController.text = detectedPincode;
        }

        if (_addressController.text.isEmpty && detectedAddress.isNotEmpty && detectedAddress != ', ,') {
          _addressController.text = detectedAddress;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.my_location_rounded, color: Color(0xFF34D399), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Location auto-detected: $detectedCity, $detectedState ($detectedPincode)')),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to detect location: $e')));
      }
    }
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your State and City.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.registerShop(
      ownerName: _ownerNameController.text.trim(),
      contactNumber: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      password: _passwordController.text,
      shopName: _shopNameController.text.trim(),
      shopSlug: _slugController.text.trim(),
      state: _selectedState!,
      city: _selectedCity!,
      pincode: _pincodeController.text.trim(),
      address: _addressController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showVerificationDialog(
        ownerName: _ownerNameController.text.trim(),
        shopName: _shopNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFEF2F2),
          content: Text(
            result['message'] ?? 'Registration failed. Please check details.',
            style: const TextStyle(color: Color(0xFFDC2626)),
          ),
        ),
      );
    }
  }

  void _showVerificationDialog({
    required String ownerName,
    required String shopName,
    required String phone,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFF4F46E5), size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                'Registration Submitted!',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '30 Minute Verification Window',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFD97706),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(text: 'Thank you, '),
                    TextSpan(text: ownerName, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                    const TextSpan(text: '! Your shop '),
                    TextSpan(text: shopName, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                    const TextSpan(text: ' has been submitted. Please wait up to '),
                    const TextSpan(text: '30 minutes', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w800)),
                    const TextSpan(text: '. Our verification team will call you at '),
                    TextSpan(text: phone, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800)),
                    const TextSpan(text: ' for shop onboarding approval.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Back to Login',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, height: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- END OF ORIGINAL METHODS ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Register Your Shop',
          style: GoogleFonts.inter(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: AnimationConfiguration.staggeredList(
            position: 0,
            duration: const Duration(milliseconds: 600),
            child: SlideAnimation(
              verticalOffset: 30,
              child: FadeInAnimation(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------- HEADER BANNER (improved) ----------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Join Bookify Partner Network',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Zero setup fee • 30-min instant verification',
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ---------- SECTION 1: Owner Details ----------
                      _buildSectionHeader('1. Owner Details'),
                      const SizedBox(height: 14),
                      _buildFormCard(
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _ownerNameController,
                              label: 'Full Owner Name *',
                              icon: Icons.person_outline_rounded,
                              validator: (val) {
                                if (val == null || val.trim().length < 3) {
                                  return 'Please enter a valid owner name (min 3 chars).';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Contact Phone Number (For Verification) *',
                              icon: Icons.phone_iphone_rounded,
                              hint: '10-digit mobile number',
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: (val) {
                                if (val == null || !RegExp(r'^[6-9]\d{9}$').hasMatch(val.trim())) {
                                  return 'Enter a valid 10-digit Indian phone number.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email Address (Optional)',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val != null && val.trim().isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                                  return 'Enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password *',
                              icon: Icons.lock_outline_rounded,
                              obscureText: !_isPasswordVisible,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF64748B),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              validator: (val) {
                                if (val == null || val.length < 6) {
                                  return 'Password must be at least 6 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password *',
                              icon: Icons.lock_reset_rounded,
                              obscureText: !_isPasswordVisible,
                              validator: (val) {
                                if (val != _passwordController.text) {
                                  return 'Passwords do not match.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ---------- SECTION 2: Shop Details ----------
                      _buildSectionHeader('2. Shop Details'),
                      const SizedBox(height: 14),
                      _buildFormCard(
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _shopNameController,
                              label: 'Shop / Salon Name *',
                              icon: Icons.store_rounded,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter your shop or salon name.';
                                }
                                return null;
                              },
                            ),
                            // slug is hidden, but we keep it in the controller
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ---------- SECTION 3: Location & Address ----------
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '3. Location & Address',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _autoDetectLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEEF2FF),
                              foregroundColor: const Color(0xFF4F46E5),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            icon: const Icon(Icons.my_location_rounded, size: 18),
                            label: Text(
                              'Auto-Detect',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildFormCard(
                        child: Column(
                          children: [
                            // State Dropdown
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _statesList.contains(_selectedState) ? _selectedState : null,
                              dropdownColor: Colors.white,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF0F172A),
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Select State *',
                                labelStyle: GoogleFonts.inter(
                                  color: const Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(Icons.map_rounded, color: Color(0xFF4F46E5)),
                                suffixIcon: _isLoadingStates
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                                        ),
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              ),
                              items: _statesList.map((state) {
                                return DropdownMenuItem<String>(
                                  value: state,
                                  child: Text(state, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) _onStateSelected(val);
                              },
                            ),
                            const SizedBox(height: 16),

                            // City Autocomplete
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return RawAutocomplete<String>(
                                  textEditingController: _cityController,
                                  focusNode: _cityFocusNode,
                                  optionsBuilder: (TextEditingValue textEditingValue) {
                                    if (_selectedState == null || _isLoadingCities) {
                                      return const Iterable<String>.empty();
                                    }
                                    if (textEditingValue.text.isEmpty) {
                                      return _citiesList;
                                    }
                                    return _citiesList.where((String option) {
                                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                    });
                                  },
                                  onSelected: (String selection) {
                                    _onCitySelected(selection);
                                  },
                                  fieldViewBuilder: (BuildContext context, TextEditingController controller,
                                      FocusNode focusNode, VoidCallback onFieldSubmitted) {
                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF0F172A),
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Select or Enter City *',
                                        labelStyle: GoogleFonts.inter(
                                          color: const Color(0xFF64748B),
                                          fontSize: 13,
                                        ),
                                        prefixIcon: const Icon(Icons.location_city_rounded, color: Color(0xFF4F46E5)),
                                        helperText: _selectedState == null ? 'Select State first to unlock cities' : null,
                                        helperStyle: GoogleFonts.inter(
                                          color: const Color(0xFF94A3B8),
                                          fontSize: 12,
                                        ),
                                        suffixIcon: _isLoadingCities
                                            ? const Padding(
                                                padding: EdgeInsets.all(12),
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                                                ),
                                              )
                                            : null,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      ),
                                      onChanged: (val) {
                                        _selectedCity = val;
                                        if (val.length > 2) {
                                          _onCitySelected(val);
                                        }
                                      },
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Please enter or select a city.';
                                        }
                                        return null;
                                      },
                                    );
                                  },
                                  optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected,
                                      Iterable<String> options) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4.0,
                                        borderRadius: BorderRadius.circular(12),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(maxHeight: 200, maxWidth: constraints.maxWidth),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            itemCount: options.length,
                                            itemBuilder: (BuildContext context, int index) {
                                              final String option = options.elementAt(index);
                                              return ListTile(
                                                title: Text(
                                                  option,
                                                  style: GoogleFonts.inter(
                                                    color: const Color(0xFF0F172A),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                onTap: () {
                                                  onSelected(option);
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // PIN Code
                            _buildTextField(
                              controller: _pincodeController,
                              label: 'PIN Code *',
                              icon: Icons.pin_drop_rounded,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              validator: (val) {
                                if (val == null || !RegExp(r'^\d{6}$').hasMatch(val.trim())) {
                                  return 'Enter a valid 6-digit PIN code.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Address
                            _buildTextField(
                              controller: _addressController,
                              label: 'Full Shop Street Address *',
                              icon: Icons.home_work_rounded,
                              hint: 'Building, Shop No, Street Name, Landmark',
                              maxLines: 2,
                              validator: (val) {
                                if (val == null || val.trim().length < 5) {
                                  return 'Please enter full shop address (min 5 chars).';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ---------- REGISTER BUTTON ----------
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: const Color(0xFF4F46E5).withOpacity(0.3),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  'Register Shop Now',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    height: 1.2,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- UI HELPER METHODS ----------
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required Widget child}) {
    return Card(
      elevation: 2,
      shadowColor: const Color(0xFF4F46E5).withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: GoogleFonts.inter(
        color: const Color(0xFF0F172A),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          fontSize: 13,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
      ),
      validator: validator,
    );
  }
}