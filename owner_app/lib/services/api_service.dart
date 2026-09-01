import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:owner_app/models/models.dart';
import 'notification_service.dart';
import '../main.dart';
import '../config.dart';

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;
  static String? authToken;
  static String? fcmDeviceToken;
  static int? currentUserId;
  static int? currentTenantId;
  static String? currentShopName;
  static String currentUserRole = 'OWNER';
  static bool isSaaSBillingEnabled = false;

  static bool get isStaff => currentUserRole.toUpperCase() == 'STAFF';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AppConfig.apiSecret != null && AppConfig.apiSecret!.isNotEmpty)
          'X-Api-Secret': AppConfig.apiSecret!,
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  /// Shop Owner or Staff Login
  static Future<Map<String, dynamic>> login(String rawEmail, String rawPassword) async {
    final email = rawEmail.trim().toLowerCase();
    final password = rawPassword.trim();

    if (email.isEmpty || password.isEmpty) {
      return {'success': false, 'message': 'Please enter both your email/phone and password.'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password, 'app_type': 'partner'}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = data['user'] ?? {};
        
        // Detect Roles safely
        final rolesRaw = user['roles'];
        final List<String> roles = [];
        if (rolesRaw is List) {
          for (var r in rolesRaw) {
            if (r is Map) {
              roles.add((r['name'] ?? r['role'] ?? '').toString().toUpperCase());
            } else if (r != null) {
              roles.add(r.toString().toUpperCase());
            }
          }
        }

        // Client-side RBAC Guard
        final isSuperAdmin = roles.contains('SUPERADMIN') || roles.contains('SUPER_ADMIN') || roles.contains('SUBADMIN');
        final isCustomerOnly = roles.contains('CUSTOMER') && !roles.contains('OWNER') && !roles.contains('STAFF') && !roles.contains('MANAGER');

        if (isSuperAdmin) {
          return {
            'success': false,
            'message': 'Superadmin and Subadmin accounts can only log in through the Web Console.',
          };
        }

        if (isCustomerOnly) {
          return {
            'success': false,
            'message': 'Customer accounts cannot access the Partner App. Please use the Customer App.',
          };
        }

        authToken = data['access_token'] ?? data['token'];
        currentUserId = user['id'];
        currentTenantId = user['tenant_id'];
        currentShopName = user['tenant']?['business_name'] ?? 'Shop Partner';

        if (roles.contains('STAFF')) {
          currentUserRole = 'STAFF';
        } else {
          currentUserRole = 'OWNER';
        }

        // Send FCM Device Registration Token to backend
        if (fcmDeviceToken != null) {
          updateFcmToken(fcmDeviceToken!);
        }

        // Sync stored offline notifications from MySQL DB & Check SaaS Billing State
        fetchStoredNotifications();
        checkSaaSEnabled();

        return {'success': true, 'data': data};
      }

      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    } catch (e) {
      debugPrint('API Error: $e');
      return {'success': false, 'message': formatNetworkError(e)};
    }
  }

  /// Format Network & Server Connection Errors into friendly messages
  static String formatNetworkError(dynamic error) {
    final str = error.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('timeout') ||
        str.contains('connection timed out') ||
        str.contains('clientexception') ||
        str.contains('failed host lookup') ||
        str.contains('connection refused') ||
        str.contains('network is unreachable') ||
        str.contains('os error') ||
        str.contains('errno = 110') ||
        str.contains('errno = 111')) {
      return "Couldn't reach the server. Please check your internet connection or server status.";
    }
    return "Couldn't reach the server. Please try again.";
  }

  /// Logout User & Clear Token
  static Future<void> logout() async {
    try {
      if (authToken != null) {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: _headers,
        );
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_logged_out', true);
      await prefs.remove('remember_email');
      await prefs.remove('remember_password');
      await prefs.remove('remember_expiry');
    } catch (e) { debugPrint('API Error: $e'); }
    authToken = null;
    currentUserId = null;
    currentTenantId = null;
    currentShopName = null;
    currentUserRole = 'OWNER';
    isSaaSBillingEnabled = false;
    NotificationService().clearAll();
  }

  /// Check if Master SaaS Billing Engine is Enabled.
  /// Uses a dedicated public endpoint so auth/tenant issues never block the check.
  static Future<bool> checkSaaSEnabled() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/billing/status'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dynamic enabledVal = data['enabled'];
        isSaaSBillingEnabled =
            (enabledVal == true || enabledVal == 1 || enabledVal.toString() == 'true');
        return isSaaSBillingEnabled;
      }
    } catch (e) { debugPrint('API Error: $e'); }
    // Do NOT flip to false on error — preserve current known state
    return isSaaSBillingEnabled;
  }

  /// Fetch Stored Pending Notifications from Backend DB (Offline Delivery Sync)
  static Future<void> fetchStoredNotifications() async {
    if (authToken == null) return;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications?unread_only=true'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List?) ?? [];
        if (list.isNotEmpty) {
          for (var item in list) {
            final id = item['id'] as int? ?? 0;
            final title = item['title'] ?? 'Notification';
            final body = item['body'] ?? '';
            final dateStr = item['created_at'];
            DateTime? dt;
            if (dateStr != null) {
              dt = DateTime.tryParse(dateStr);
            }

            // Add to local in-app notification inbox
            NotificationService().addNotification(title, body, timestamp: dt);

            // 🔔 POP UP SYSTEM TRAY NOTIFICATION ONCE FOR UNREAD OFFLINE ALERTS
            showSystemTrayNotification(title, body, id: id);
          }

          // Immediately mark delivered offline notifications as read in MySQL so they NEVER repeat on subsequent logins!
          markNotificationsRead();
        }
      }
    } catch (e) { debugPrint('API Error: $e'); }
  }

  /// Mark all notifications as read in Backend DB
  static Future<void> markNotificationsRead() async {
    if (authToken == null) return;
    try {
      await http.post(
        Uri.parse('$baseUrl/notifications/read'),
        headers: _headers,
      );
    } catch (e) { debugPrint('API Error: $e'); }
  }

  /// Send/Update FCM Device Token to Backend
  static Future<bool> updateFcmToken(String token) async {
    fcmDeviceToken = token;
    if (authToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/fcm-token'),
        headers: _headers,
        body: jsonEncode({'fcm_token': token}),
      );
      return response.statusCode == 200;
    } catch (e) { debugPrint('API Error: $e'); 
      return false;
    }
  }

  /// Register New Shop Partner with named parameters
  static Future<Map<String, dynamic>> registerShop({
    required String ownerName,
    required String contactNumber,
    String? email,
    required String password,
    required String shopName,
    String? shopSlug,
    required String state,
    required String city,
    required String pincode,
    required String address,
  }) async {
    try {
      final body = <String, dynamic>{
        'owner_name': ownerName,
        'contact_number': contactNumber,
        if (email != null && email.isNotEmpty) 'email': email,
        'password': password,
        'shop_name': shopName,
        if (shopSlug != null && shopSlug.isNotEmpty) 'shop_slug': shopSlug,
        'state': state,
        'city': city,
        'pincode': pincode,
        'address': address,
        if (fcmDeviceToken != null) 'fcm_token': fcmDeviceToken,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register-shop'),
        headers: _headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Shop registration submitted successfully!',
          'tenant_id': data['tenant_id'],
          'contact_number': data['contact_number'],
          'verification_window_minutes': data['verification_window_minutes'] ?? 30,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed. Please check your details.'
        };
      }
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Network connection error: $e'};
    }
  }

  /// Detect real-time exact location from Backend IPGeolocation integration
  static Future<Map<String, dynamic>> detectLocation({double? lat, double? lng}) async {
    try {
      String url = '$baseUrl/location/detect';
      if (lat != null && lng != null) {
        url += '?lat=$lat&lng=$lng';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to detect location'};
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Fetch states of India via Backend Proxy
  static Future<List<String>> fetchStates() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/location/states'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final statesList = data['data'] as List;
          return statesList.map((e) => e.toString()).toList();
        }
      } else {
        debugPrint('Fetch States Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Fetch States Exception: $e');
    }
    return [];
  }

  /// Fetch cities of a specific state via Backend Proxy
  static Future<List<String>> fetchCities(String state) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/location/cities/${Uri.encodeComponent(state)}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final citiesList = data['data'] as List;
          return citiesList.map((e) => e.toString()).toList();
        }
      }
    } catch (e) { debugPrint('API Error: $e'); }
    return [];
  }

  /// Fetch Pincode for a City via Backend Proxy
  static Future<String?> fetchPincodeForCity(String city) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/location/pincode/${Uri.encodeComponent(city)}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'].toString();
        }
      }
    } catch (e) { debugPrint('API Error: $e'); }
    return null;
  }

  /// Get Owner Business Profile
  static Future<Map<String, dynamic>> getBusinessProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/profile'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tenantMap = data['tenant'] ?? {};
        currentTenantId = tenantMap['id'];
        currentShopName = tenantMap['business_name'];
        return {'success': true, 'tenant': tenantMap, 'raw': data};
      }
    } catch (e) { debugPrint('API Error: $e'); }
    return {'success': false};
  }

  /// Update Shop Booking & Cancellation Policies
  static Future<Map<String, dynamic>> updateBookingPolicy({
    required String bookingPolicy,
    int cancellationBufferMinutes = 120,
    double prebookingTokenAmount = 50.00,
    int consecutiveDeclinesLimit = 3,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/booking-policy'),
        headers: _headers,
        body: jsonEncode({
          'booking_policy': bookingPolicy,
          'cancellation_buffer_minutes': cancellationBufferMinutes,
          'prebooking_token_amount': prebookingTokenAmount,
          'consecutive_declines_limit': consecutiveDeclinesLimit,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': data['success'] == true, 'message': data['message'] ?? 'Policies updated'};
      }
    } catch (e) { debugPrint('API Error: $e'); }
    return {'success': false, 'message': 'Network error updating policies'};
  }

  /// Get Home & Event/Wedding Services configuration
  static Future<Map<String, dynamic>> getHomeServiceSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/home-service-settings'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'settings': data['settings'] ?? {}};
      }
    } catch (e) { debugPrint('API Error in getHomeServiceSettings: $e'); }
    return {'success': false, 'settings': {}};
  }

  /// Update Home & Event/Wedding Services configuration
  static Future<Map<String, dynamic>> updateHomeServiceSettings(Map<String, dynamic> settingsData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/home-service-settings'),
        headers: _headers,
        body: jsonEncode(settingsData),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Settings updated successfully!',
        'settings': data['settings'] ?? {},
      };
    } catch (e) {
      debugPrint('API Error in updateHomeServiceSettings: $e');
      return {'success': false, 'message': 'Network error updating settings.'};
    }
  }

  /// Toggle Shop Online / Offline Availability immediately in Database
  static Future<Map<String, dynamic>> toggleShopOnline(bool isOnline) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/toggle-online'),
        headers: _headers,
        body: jsonEncode({
          'is_online': isOnline,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] == true,
          'is_online': data['is_online'] ?? isOnline,
          'status': data['status'],
          'message': data['message'] ?? 'Shop status updated.',
        };
      }
    } catch (e) { debugPrint('API Error: $e'); }
    return {'success': false, 'message': 'Network error updating shop status.'};
  }

  /// Get Dynamic Owner Dashboard Metrics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/dashboard-stats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? {}};
      }
    } catch (e) { debugPrint('API Error: $e'); }
    return {'success': false, 'data': {}};
  }

  /// Get Branch List
  static Future<List<OwnerBranch>> getBranches() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/branches'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List?) ?? [];
        return list.map((b) => OwnerBranch.fromJson(b)).toList();
      }
    } catch (e) { debugPrint('API Error in getBranches: $e'); }
    return [];
  }

  /// Create New Branch
  static Future<Map<String, dynamic>> createBranch(Map<String, dynamic> branchData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/branches'),
        headers: _headers,
        body: jsonEncode(branchData),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201 || data['success'] == true,
        'message': data['message'] ?? (response.statusCode == 201 ? 'Branch created!' : 'Failed to create branch.'),
        'data': data['data'],
      };
    } catch (e) {
      debugPrint('API Error in createBranch: $e');
      return {'success': false, 'message': 'Network error creating branch.'};
    }
  }


  /// Update Existing Branch
  static Future<Map<String, dynamic>> updateBranch(int branchId, Map<String, dynamic> branchData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/business/branches/$branchId'),
        headers: _headers,
        body: jsonEncode(branchData),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Branch updated successfully.',
        'data': data['data'],
      };
    } catch (e) {
      debugPrint('API Error in updateBranch: $e');
      return {'success': false, 'message': 'Network error updating branch.'};
    }
  }

  /// Toggle Branch Active/Disabled Status
  static Future<Map<String, dynamic>> toggleBranchStatus(int branchId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/branches/$branchId/toggle'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Branch status updated.',
        'data': data['data'],
      };
    } catch (e) {
      debugPrint('API Error in toggleBranchStatus: $e');
      return {'success': false, 'message': 'Network error toggling branch status.'};
    }
  }

  /// Delete Branch
  static Future<Map<String, dynamic>> deleteBranch(int branchId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/business/branches/$branchId'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Branch deleted successfully.',
      };
    } catch (e) {
      debugPrint('API Error in deleteBranch: $e');
      return {'success': false, 'message': 'Network error deleting branch.'};
    }
  }

  /// Get Services offered by Salon
  static Future<List<OwnerService>> getServices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/services'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List?) ?? [];
        return list.map((s) => OwnerService.fromJson(s)).toList();
      }
    } catch (e) { debugPrint('API Error: $e'); }
    return [];
  }

  /// Add New Service via Map
  static Future<Map<String, dynamic>> addService(Map<String, dynamic> serviceData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/services'),
        headers: _headers,
        body: jsonEncode(serviceData),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201 || response.statusCode == 200,
        'message': data['message'] ?? 'Service saved successfully!',
        'data': data['data'],
      };
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Create Service with named parameters
  static Future<bool> createService({
    required int branchId,
    required String name,
    required String category,
    required double price,
    required int durationMinutes,
  }) async {
    final res = await addService({
      'branch_id': branchId,
      'name': name,
      'category': category,
      'price': price,
      'duration_minutes': durationMinutes,
    });
    return res['success'] == true;
  }

  /// Update Existing Service
  static Future<Map<String, dynamic>> updateService(int id, Map<String, dynamic> serviceData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/business/services/$id'),
        headers: _headers,
        body: jsonEncode(serviceData),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Service updated successfully!',
        'data': data['data'],
      };
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Delete Existing Service
  static Future<Map<String, dynamic>> deleteService(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/business/services/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Service deleted successfully!',
      };
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Toggle Service Active Status
  static Future<Map<String, dynamic>> toggleService(int id, bool isActive) async {
    return updateService(id, {'is_active': isActive});
  }

  /// Get Staff List
  static Future<List<OwnerStaff>> getStaff() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/staff'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List?) ?? [];
        return list.map((s) => OwnerStaff.fromJson(s)).toList();
      }
    } catch (e) { debugPrint('API Error: $e'); }
    return [];
  }

  /// Get Combos List
  static Future<List<OwnerCombo>> getCombos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/combos'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List?) ?? [];
        return list.map((c) => OwnerCombo.fromJson(c)).toList();
      }
    } catch (e) { debugPrint('API Error: $e'); }
    return [];
  }

  /// Create New Combo Package
  static Future<Map<String, dynamic>> createCombo(Map<String, dynamic> comboData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/combos'),
        headers: _headers,
        body: jsonEncode(comboData),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201 || response.statusCode == 200,
        'message': data['message'] ?? 'Combo package created successfully!',
        'data': data['data'],
      };
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Update Existing Combo Package
  static Future<Map<String, dynamic>> updateCombo(int id, Map<String, dynamic> comboData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/business/combos/$id'),
        headers: _headers,
        body: jsonEncode(comboData),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Combo package updated successfully!',
        'data': data['data'],
      };
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Delete Existing Combo Package
  static Future<Map<String, dynamic>> deleteCombo(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/business/combos/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Combo package deleted successfully!',
      };
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Toggle Combo Package Active Status
  static Future<Map<String, dynamic>> toggleCombo(int id, bool isActive) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/combos/$id/toggle'),
        headers: _headers,
        body: jsonEncode({'is_active': isActive}),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Combo status updated.',
      };
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get Customer CRM Directory
  static Future<List<OwnerCustomerCRM>> getCustomers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/customers'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List?) ?? [];
        return list.map<OwnerCustomerCRM>((c) => OwnerCustomerCRM.fromJson(c)).toList();
      }
    } catch (e) { debugPrint('API Error: $e'); }
    return [];
  }

  /// Get Promotions and Rush Surge Rules from Database
  static Future<Map<String, dynamic>> getPromotions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/promotions'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'promotions': ((data['promotions'] as List?) ?? []).map<OwnerPromotion>((p) => OwnerPromotion.fromJson(p)).toList(),
          'rush_rules': ((data['rush_rules'] as List?) ?? []).map<OwnerRushPricingRule>((r) => OwnerRushPricingRule.fromJson(r)).toList(),
        };
      }
    } catch (e) { debugPrint('API Error: $e'); }
    return {'promotions': <OwnerPromotion>[], 'rush_rules': <OwnerRushPricingRule>[]};
  }

  /// Create Off-Peak Discount in Database
  static Future<Map<String, dynamic>> createOffPeakDiscount(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/promotions/discounts'),
        headers: _headers,
        body: jsonEncode(data),
      );
      final res = jsonDecode(response.body);
      return {
        'success': (response.statusCode == 201 || response.statusCode == 200) && res['success'] == true,
        'message': res['message'] ?? 'Discount created successfully!',
        'data': res['data'],
      };
    } catch (e) {
      debugPrint('API Error createOffPeakDiscount: $e');
      return {'success': false, 'message': 'Network error creating discount: $e'};
    }
  }

  /// Update Off-Peak Discount in Database
  static Future<Map<String, dynamic>> updateOffPeakDiscount(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/business/promotions/discounts/$id'),
        headers: _headers,
        body: jsonEncode(data),
      );
      final res = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && res['success'] == true,
        'message': res['message'] ?? 'Discount updated successfully!',
        'data': res['data'],
      };
    } catch (e) {
      debugPrint('API Error updateOffPeakDiscount: $e');
      return {'success': false, 'message': 'Network error updating discount: $e'};
    }
  }

  /// Toggle Off-Peak Discount Active Status in Database
  static Future<Map<String, dynamic>> toggleOffPeakDiscount(int id, bool isActive) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/promotions/discounts/$id/toggle'),
        headers: _headers,
        body: jsonEncode({'is_active': isActive}),
      );
      final res = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && res['success'] == true,
        'message': res['message'] ?? 'Status updated successfully!',
      };
    } catch (e) {
      debugPrint('API Error toggleOffPeakDiscount: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Delete Off-Peak Discount from Database
  static Future<Map<String, dynamic>> deleteOffPeakDiscount(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/business/promotions/discounts/$id'),
        headers: _headers,
      );
      final res = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && res['success'] == true,
        'message': res['message'] ?? 'Discount deleted successfully!',
      };
    } catch (e) {
      debugPrint('API Error deleteOffPeakDiscount: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Create Rush Surge Rule in Database
  static Future<Map<String, dynamic>> createSurgeRule(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/promotions/surge-rules'),
        headers: _headers,
        body: jsonEncode(data),
      );
      final res = jsonDecode(response.body);
      return {
        'success': (response.statusCode == 201 || response.statusCode == 200) && res['success'] == true,
        'message': res['message'] ?? 'Surge rule created successfully!',
        'data': res['data'],
      };
    } catch (e) {
      debugPrint('API Error createSurgeRule: $e');
      return {'success': false, 'message': 'Network error creating surge rule: $e'};
    }
  }

  /// Update Rush Surge Rule in Database
  static Future<Map<String, dynamic>> updateSurgeRule(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/business/promotions/surge-rules/$id'),
        headers: _headers,
        body: jsonEncode(data),
      );
      final res = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && res['success'] == true,
        'message': res['message'] ?? 'Surge rule updated successfully!',
        'data': res['data'],
      };
    } catch (e) {
      debugPrint('API Error updateSurgeRule: $e');
      return {'success': false, 'message': 'Network error updating surge rule: $e'};
    }
  }

  /// Toggle Rush Surge Rule Enabled Status in Database
  static Future<Map<String, dynamic>> toggleSurgeRule(int id, bool isEnabled) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/promotions/surge-rules/$id/toggle'),
        headers: _headers,
        body: jsonEncode({'is_enabled': isEnabled}),
      );
      final res = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && res['success'] == true,
        'message': res['message'] ?? 'Surge rule status updated successfully!',
      };
    } catch (e) {
      debugPrint('API Error toggleSurgeRule: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Delete Rush Surge Rule from Database
  static Future<Map<String, dynamic>> deleteSurgeRule(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/business/promotions/surge-rules/$id'),
        headers: _headers,
      );
      final res = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && res['success'] == true,
        'message': res['message'] ?? 'Surge rule deleted successfully!',
      };
    } catch (e) {
      debugPrint('API Error deleteSurgeRule: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get Today's Time Slot Schedule per Staff
  static Future<List<OwnerStaffSchedule>> getTodaySlots() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/today-slots'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ((data['schedule'] as List?) ?? [])
            .map<OwnerStaffSchedule>((s) => OwnerStaffSchedule.fromJson(Map<String, dynamic>.from(s)))
            .toList();
      }
    } catch (e) { debugPrint('API Error: $e'); }
    return [];
  }

  /// Add a new Combo Package
  static Future<bool> addCombo({
    required String name,
    required double price,
    required int durationMinutes,
    double discount = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/combos'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'price': price,
          'duration_minutes': durationMinutes,
          'discount': discount,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) { debugPrint('API Error: $e'); 
      return false;
    }
  }

  /// Add a new Branch
  static Future<bool> addBranch({
    required String name,
    required String address,
    required String city,
    String state = '',
    String pinCode = '',
    String contactMobile = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/branches'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'address': address,
          'city': city,
          if (state.isNotEmpty) 'state': state,
          if (pinCode.isNotEmpty) 'pin_code': pinCode,
          if (contactMobile.isNotEmpty) 'contact_mobile': contactMobile,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) { debugPrint('API Error: $e'); 
      return false;
    }
  }

  /// Respond to Booking Request (Accept, Decline, or Add Extra Time)
  static Future<Map<String, dynamic>> respondBooking({
    required int bookingId,
    required String action,
    int? delayMinutes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/bookings/$bookingId/respond'),
        headers: _headers,
        body: jsonEncode({
          'action': action,
          if (delayMinutes != null && delayMinutes > 0) 'delay_minutes': delayMinutes,
        }),
      );

      final bodyStr = response.body.trim();
      if (!bodyStr.startsWith('{')) {
        return {
          'success': response.statusCode == 200,
          'message': action == 'DECLINE' ? 'Booking declined successfully!' : 'Booking updated successfully!'
        };
      }

      final data = jsonDecode(bodyStr);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? (action == 'DECLINE' ? 'Booking declined successfully!' : 'Booking updated successfully!'),
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update booking status.'
      };
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Toggle Staff Online Availability
  static Future<Map<String, dynamic>> toggleStaffOnline(bool isOnline) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/staff/toggle-online'),
        headers: _headers,
        body: jsonEncode({'is_online': isOnline}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Server returned status ${response.statusCode}'};
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Fetch Staff Dashboard Stats & Metrics
  static Future<Map<String, dynamic>> getStaffStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/staff/stats'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to fetch staff stats.'};
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Look up customer details by Phone Number from server
  static Future<Map<String, dynamic>> lookupCustomerByPhone(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/customers/lookup'),
        headers: _headers,
        body: jsonEncode({'phone': phone}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('API Error lookupCustomerByPhone: $e');
      return {'success': false, 'found': false, 'message': 'Connection error: $e'};
    }
  }

  /// Create / Pre-add Customer to CRM
  static Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> customerData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/customers'),
        headers: _headers,
        body: jsonEncode(customerData),
      );
      final res = jsonDecode(response.body);
      return {
        'success': (response.statusCode == 201 || response.statusCode == 200) && res['success'] == true,
        'message': res['message'] ?? 'Customer saved to CRM.',
        'data': res['data'],
      };
    } catch (e) {
      debugPrint('API Error createCustomer: $e');
      return {'success': false, 'message': 'Network error creating customer: $e'};
    }
  }

  /// Update Customer in CRM
  static Future<Map<String, dynamic>> updateCustomer(int id, Map<String, dynamic> customerData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/business/customers/$id'),
        headers: _headers,
        body: jsonEncode(customerData),
      );
      final res = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && res['success'] == true,
        'message': res['message'] ?? 'Customer updated.',
        'data': res['data'],
      };
    } catch (e) {
      debugPrint('API Error updateCustomer: $e');
      return {'success': false, 'message': 'Network error updating customer: $e'};
    }
  }

  /// Fetch all booking clients who are NOT yet in the CRM directory
  static Future<Map<String, dynamic>> getUnaddedBookingClients() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/customers/unadded-booking-clients'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'data': [], 'message': 'Failed to load unadded booking clients.'};
    } catch (e) {
      debugPrint('API Error getUnaddedBookingClients: $e');
      return {'success': false, 'data': [], 'message': 'Connection error: $e'};
    }
  }

  /// Batch Add Selected Booking Clients to CRM
  static Future<Map<String, dynamic>> batchAddBookingClients(List<Map<String, dynamic>> clients) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/customers/batch-add-bookings'),
        headers: _headers,
        body: jsonEncode({'clients': clients}),
      );
      final res = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && res['success'] == true,
        'message': res['message'] ?? 'Customers added to CRM.',
        'count': res['count'] ?? 0,
      };
    } catch (e) {
      debugPrint('API Error batchAddBookingClients: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get Customer Full Details & History with Filter
  static Future<Map<String, dynamic>> getCustomerDetails(int customerId, {int months = 6}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/customers/$customerId/details?months=$months'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to load customer details.'};
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Remove Customer from CRM
  static Future<Map<String, dynamic>> removeCustomerFromCrm(int customerId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/business/customers/$customerId'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Request Account & Data Deletion
  static Future<Map<String, dynamic>> requestAccountDeletion() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/account/request-deletion'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ==========================================
  // STAFF MANAGEMENT
  // ==========================================

  static Future<List<dynamic>> getStaffList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/business/staff'), headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) { debugPrint('API Error: $e'); }
    return [];
  }

  static Future<Map<String, dynamic>> createStaff(Map<String, dynamic> staffData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/staff'),
        headers: _headers,
        body: jsonEncode(staffData),
      );
      return jsonDecode(response.body);
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Network error creating staff.'};
    }
  }

  static Future<Map<String, dynamic>> updateStaff(int id, Map<String, dynamic> staffData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/business/staff/$id'),
        headers: _headers,
        body: jsonEncode(staffData),
      );
      return jsonDecode(response.body);
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Network error updating staff.'};
    }
  }

  static Future<Map<String, dynamic>> deleteStaff(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/business/staff/$id'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Network error deleting staff.'};
    }
  }

  static Future<Map<String, dynamic>> resetStaffPassword(int id, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/staff/$id/reset-password'),
        headers: _headers,
        body: jsonEncode({'password': newPassword}),
      );
      return jsonDecode(response.body);
    } catch (e) { debugPrint('API Error: $e'); 
      return {'success': false, 'message': 'Network error resetting password.'};
    }
  }

  // ==========================================
  // BRANCH HOURS MANAGEMENT
  // ==========================================

  static Future<List<dynamic>> getBranchHours(int branchId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/branches/$branchId/hours'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) { debugPrint('API Error: $e'); }
    return [];
  }

  static Future<Map<String, dynamic>> updateBranchHours(
    int branchId, 
    List<Map<String, dynamic>> hoursData, {
    bool applyToAllBranches = false,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/business/branches/$branchId/hours'),
        headers: _headers,
        body: jsonEncode({
          'hours': hoursData,
          'apply_to_all_branches': applyToAllBranches,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Operating schedule saved successfully!',
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update branch hours (Status ${response.statusCode})',
      };
    } catch (e) {
      debugPrint('API Error in updateBranchHours: $e');
      return {'success': false, 'message': 'Network error updating hours: $e'};
    }
  }
}




