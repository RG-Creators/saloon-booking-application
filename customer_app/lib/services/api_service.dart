import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'notification_service.dart';

class ApiService {
  static const String baseUrl = 'http://10.21.170.176:8000/api/v1';

  static String? authToken;
  static User? currentUser;
  static String? fcmDeviceToken;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  /// Load session from SharedPreferences
  static Future<bool> loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      authToken = prefs.getString('auth_token');
      final userJson = prefs.getString('user_data');
      if (authToken != null && userJson != null) {
        currentUser = User.fromJson(jsonDecode(userJson));
        return true;
      }
    } catch (e) {
      debugPrint('Error loading session: $e');
    }
    return false;
  }

  /// Save session to SharedPreferences
  static Future<void> saveSession(String token, User user) async {
    authToken = token;
    currentUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_data', jsonEncode({
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'mobile': user.mobile,
        'roles': user.roles,
        'tenant_id': user.tenantId,
      }));
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  /// Clear session on Logout
  static Future<void> clearSession() async {
    authToken = null;
    currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    } catch (_) {}
  }

  /// Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'app_type': 'customer',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['access_token'];
        final user = User.fromJson(data['user']);
        await saveSession(token, user);
        if (fcmDeviceToken != null) {
          updateFcmToken(fcmDeviceToken!);
        }
        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Authentication failed'};
      }
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

  /// Register Customer
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? mobile,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final token = data['access_token'];
        final user = User.fromJson(data['user']);
        await saveSession(token, user);
        if (fcmDeviceToken != null) {
          updateFcmToken(fcmDeviceToken!);
        }
        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      debugPrint('API Error: $e');
      return {'success': false, 'message': formatNetworkError(e)};
    }
  }

  /// Update FCM Token
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
    } catch (_) {
      return false;
    }
  }

  /// Discover Nearby Salons with distance & live statuses
  static Future<List<SalonBranch>> getNearbySalons({
    String city = 'New Delhi',
    double? lat,
    double? lng,
    String category = '',
  }) async {
    try {
      var uri = '$baseUrl/discovery/nearby?city=${Uri.encodeComponent(city)}';
      if (lat != null && lng != null) {
        uri += '&lat=$lat&lng=$lng';
      }
      if (category.isNotEmpty) {
        uri += '&category=${Uri.encodeComponent(category)}';
      }

      final response = await http.get(Uri.parse(uri), headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List?) ?? [];
        return list.map((b) => SalonBranch.fromJson(b)).toList();
      }
    } catch (e) {
      debugPrint('getNearbySalons error: $e');
    }
    return [];
  }

  /// Search Salons by query
  static Future<List<SalonBranch>> searchSalons(String query, {double? lat, double? lng}) async {
    try {
      var uri = '$baseUrl/discovery/search?q=${Uri.encodeComponent(query)}';
      if (lat != null && lng != null) {
        uri += '&lat=$lat&lng=$lng';
      }

      final response = await http.get(Uri.parse(uri), headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List?) ?? [];
        return list.map((b) => SalonBranch.fromJson(b)).toList();
      }
    } catch (e) {
      debugPrint('searchSalons error: $e');
    }
    return [];
  }

  /// Get Shop Details
  static Future<SalonBranch?> getShopDetails(int branchOrTenantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/discovery/shops/$branchOrTenantId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SalonBranch.fromJson(data['data']);
        }
      }
    } catch (e) {
      debugPrint('getShopDetails error: $e');
    }
    return null;
  }

  /// Get Available 30-min Time Slots
  static Future<List<String>> getAvailableSlots({
    required int branchId,
    required int serviceId,
    required String date,
    int? staffId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/booking/slots/check'),
        headers: _headers,
        body: jsonEncode({
          'branch_id': branchId,
          'service_id': serviceId,
          'date': date,
          if (staffId != null) ...{'staff_id': staffId},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final slotsMap = data['data'] as Map<String, dynamic>? ?? {};
        final list = slotsMap.keys.toList();
        list.sort();
        return list;
      }
    } catch (e) {
      debugPrint('getAvailableSlots error: $e');
    }
    return [];
  }

  /// Lock Time Slot (5-Minute Pessimistic Slot Lock)
  static Future<Map<String, dynamic>> lockSlot({
    required int branchId,
    required int serviceId,
    required int staffId,
    required String date,
    required String time,
    String bookingType = 'IN_STUDIO',
    String? serviceAddress,
    String? addressLandmark,
    String? occasionType,
    double? travelFee,
    int? comboId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/booking/lock'),
        headers: _headers,
        body: jsonEncode({
          'branch_id': branchId,
          'service_id': serviceId,
          'staff_id': staffId,
          'date': date,
          'time': time,
          'booking_type': bookingType,
          if (serviceAddress != null && serviceAddress.isNotEmpty) 'service_address': serviceAddress,
          if (addressLandmark != null && addressLandmark.isNotEmpty) 'address_landmark': addressLandmark,
          if (occasionType != null && occasionType.isNotEmpty) 'occasion_type': occasionType,
          if (travelFee != null) ...{'travel_fee': travelFee},
          if (comboId != null) ...{'combo_id': comboId},
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'booking_id': data['data']['id'], 'data': data['data']};
      } else {
        return {
          'success': false,
          'crm_blocked': data['crm_blocked'] == true,
          'strike_blocked': data['strike_blocked'] == true,
          'message': data['message'] ?? 'Slot lock collision conflict.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Slot lock failed: $e'};
    }
  }

  /// Confirm Booking
  static Future<Map<String, dynamic>> confirmBooking(int bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/booking/confirm'),
        headers: _headers,
        body: jsonEncode({'booking_id': bookingId}),
      );

      final data = jsonDecode(response.body);
      return {'success': data['success'] ?? false, 'message': data['message'] ?? 'Confirmed'};
    } catch (e) {
      return {'success': false, 'message': 'Confirmation failed: $e'};
    }
  }

  /// Get Customer Appointments (Upcoming & Past)
  static Future<Map<String, List<CustomerBooking>>> getCustomerBookings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer/bookings'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final upcomingList = (data['upcoming'] as List?) ?? [];
        final pastList = (data['past'] as List?) ?? [];
        final allList = (data['all'] as List?) ?? [];

        return {
          'upcoming': upcomingList.map((b) => CustomerBooking.fromJson(b)).toList(),
          'past': pastList.map((b) => CustomerBooking.fromJson(b)).toList(),
          'all': allList.map((b) => CustomerBooking.fromJson(b)).toList(),
        };
      }
    } catch (e) {
      debugPrint('getCustomerBookings error: $e');
    }
    return {'upcoming': [], 'past': [], 'all': []};
  }

  /// Cancel Booking
  static Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer/bookings/$bookingId/cancel'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Booking cancelled.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error canceling booking: $e'};
    }
  }

  /// Fetch Stored Notifications
  static Future<void> fetchNotifications() async {
    if (authToken == null) return;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List?) ?? [];
        for (var item in list) {
          final title = item['title'] ?? 'Notification';
          final body = item['body'] ?? '';
          final dateStr = item['created_at'];
          DateTime? dt = dateStr != null ? DateTime.tryParse(dateStr) : null;
          NotificationService().addNotification(title, body, timestamp: dt, data: item['data']);
        }
      }
    } catch (_) {}
  }

  /// Mark Notifications as Read
  static Future<void> markNotificationsRead() async {
    if (authToken == null) return;
    try {
      await http.post(
        Uri.parse('$baseUrl/notifications/read'),
        headers: _headers,
      );
    } catch (_) {}
  }
}
