import 'package:flutter/material.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? mobile;
  final List<String> roles;
  final int? tenantId;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.mobile,
    required this.roles,
    this.tenantId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'],
      roles: List<String>.from(json['roles'] ?? []),
      tenantId: json['tenant_id'],
    );
  }
}

class StoreStatus {
  final bool isOpen;
  final String statusCode;
  final String statusLabel;
  final String statusColorHex;
  final String statusSubtitle;

  StoreStatus({
    required this.isOpen,
    required this.statusCode,
    required this.statusLabel,
    required this.statusColorHex,
    required this.statusSubtitle,
  });

  Color get statusColor {
    try {
      final hex = statusColorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return isOpen ? const Color(0xFF059669) : const Color(0xFF64748B);
    }
  }

  factory StoreStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return StoreStatus(
        isOpen: true,
        statusCode: 'OPEN_NOW',
        statusLabel: 'Open Now',
        statusColorHex: '#059669',
        statusSubtitle: 'Accepting bookings',
      );
    }
    return StoreStatus(
      isOpen: json['is_open'] == true,
      statusCode: json['status_code'] ?? 'OPEN_NOW',
      statusLabel: json['status_label'] ?? 'Open',
      statusColorHex: json['status_color'] ?? '#059669',
      statusSubtitle: json['status_subtitle'] ?? '',
    );
  }
}

class WorkingHour {
  final int dayOfWeek;
  final String dayName;
  final bool isOpen;
  final String? openTime;
  final String? closeTime;

  WorkingHour({
    required this.dayOfWeek,
    required this.dayName,
    required this.isOpen,
    this.openTime,
    this.closeTime,
  });

  factory WorkingHour.fromJson(Map<String, dynamic> json) {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final dow = json['day_of_week'] ?? 0;
    return WorkingHour(
      dayOfWeek: dow,
      dayName: (dow >= 0 && dow < days.length) ? days[dow] : 'Day $dow',
      isOpen: json['is_open'] == 1 || json['is_open'] == true,
      openTime: json['open_time'],
      closeTime: json['close_time'],
    );
  }
}

class SalonFeatures {
  final bool homeServiceEnabled;
  final bool eventWeddingEnabled;
  final int homeServiceRadiusKm;
  final double homeServiceTravelFee;
  final double eventMinBookingAmount;
  final String bookingPolicy;
  final int cancellationBufferMinutes;
  final double prebookingTokenAmount;
  final bool crmOnlyBooking;
  final String homeServiceNotes;

  SalonFeatures({
    required this.homeServiceEnabled,
    required this.eventWeddingEnabled,
    required this.homeServiceRadiusKm,
    required this.homeServiceTravelFee,
    required this.eventMinBookingAmount,
    required this.bookingPolicy,
    required this.cancellationBufferMinutes,
    required this.prebookingTokenAmount,
    required this.crmOnlyBooking,
    this.homeServiceNotes = '',
  });

  factory SalonFeatures.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return SalonFeatures(
        homeServiceEnabled: true,
        eventWeddingEnabled: true,
        homeServiceRadiusKm: 10,
        homeServiceTravelFee: 100.0,
        eventMinBookingAmount: 1500.0,
        bookingPolicy: 'PAY_AT_SALON',
        cancellationBufferMinutes: 120,
        prebookingTokenAmount: 50.0,
        crmOnlyBooking: false,
      );
    }
    return SalonFeatures(
      homeServiceEnabled: json['home_service_enabled'] == true,
      eventWeddingEnabled: json['event_wedding_enabled'] == true,
      homeServiceRadiusKm: json['home_service_radius_km'] ?? 10,
      homeServiceTravelFee: double.tryParse(json['home_service_travel_fee'].toString()) ?? 100.0,
      eventMinBookingAmount: double.tryParse(json['event_min_booking_amount'].toString()) ?? 1500.0,
      bookingPolicy: json['booking_policy'] ?? 'PAY_AT_SALON',
      cancellationBufferMinutes: json['cancellation_buffer_minutes'] ?? 120,
      prebookingTokenAmount: double.tryParse(json['prebooking_token_amount'].toString()) ?? 50.0,
      crmOnlyBooking: json['crm_only_booking'] == true,
      homeServiceNotes: json['home_service_notes'] ?? '',
    );
  }
}

class SalonBranch {
  final int id;
  final int tenantId;
  final String name;
  final String businessName;
  final String businessType;
  final String description;
  final String address;
  final String city;
  final String? state;
  final String? pinCode;
  final double? latitude;
  final double? longitude;
  final String? contactMobile;
  final String? contactEmail;
  final double rating;
  final int reviewsCount;
  final double? distanceKm;
  final String distanceText;
  final StoreStatus status;
  final double minPrice;
  final int servicesCount;
  final int combosCount;
  final SalonFeatures features;
  final List<WorkingHour> workingHours;
  final List<ServiceItem> services;
  final List<ServiceCombo> combos;
  final List<Staff> staff;

  SalonBranch({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.businessName,
    required this.businessType,
    required this.description,
    required this.address,
    required this.city,
    this.state,
    this.pinCode,
    this.latitude,
    this.longitude,
    this.contactMobile,
    this.contactEmail,
    required this.rating,
    required this.reviewsCount,
    this.distanceKm,
    required this.distanceText,
    required this.status,
    required this.minPrice,
    required this.servicesCount,
    required this.combosCount,
    required this.features,
    required this.workingHours,
    this.services = const [],
    this.combos = const [],
    this.staff = const [],
  });

  factory SalonBranch.fromJson(Map<String, dynamic> json) {
    var whList = (json['working_hours'] as List?) ?? [];
    var sList = (json['services'] as List?) ?? [];
    var cList = (json['combos'] as List?) ?? [];
    var stList = (json['staff'] as List?) ?? [];

    final pricing = json['pricing'] as Map<String, dynamic>?;

    return SalonBranch(
      id: json['id'] ?? 0,
      tenantId: json['tenant_id'] ?? 0,
      name: json['name'] ?? '',
      businessName: json['business_name'] ?? json['name'] ?? '',
      businessType: json['business_type'] ?? 'Grooming & Salon',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'],
      pinCode: json['pin_code'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      contactMobile: json['contact_mobile'],
      contactEmail: json['contact_email'],
      rating: double.tryParse(json['rating']?.toString() ?? '4.9') ?? 4.9,
      reviewsCount: json['reviews_count'] ?? 128,
      distanceKm: json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null,
      distanceText: json['distance_text'] ?? 'Within your area',
      status: StoreStatus.fromJson(json['status']),
      minPrice: pricing != null ? (double.tryParse(pricing['min_price'].toString()) ?? 150.0) : 150.0,
      servicesCount: pricing != null ? (pricing['services_count'] ?? sList.length) : sList.length,
      combosCount: pricing != null ? (pricing['combos_count'] ?? cList.length) : cList.length,
      features: SalonFeatures.fromJson(json['features'] ?? json['policies']),
      workingHours: whList.map((w) => WorkingHour.fromJson(w)).toList(),
      services: sList.map((s) => ServiceItem.fromJson(s)).toList(),
      combos: cList.map((c) => ServiceCombo.fromJson(c)).toList(),
      staff: stList.map((st) => Staff.fromJson(st)).toList(),
    );
  }
}

class ServiceItem {
  final int id;
  final int branchId;
  final String name;
  final String category;
  final double price;
  final int durationMinutes;
  final String serviceType;
  final double homeSurcharge;
  final String? description;

  ServiceItem({
    required this.id,
    required this.branchId,
    required this.name,
    required this.category,
    required this.price,
    required this.durationMinutes,
    this.serviceType = 'IN_STUDIO',
    this.homeSurcharge = 0.0,
    this.description,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] ?? 0,
      branchId: json['branch_id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? 'General',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      durationMinutes: json['duration_minutes'] ?? 30,
      serviceType: json['service_type'] ?? 'IN_STUDIO',
      homeSurcharge: double.tryParse(json['home_surcharge']?.toString() ?? '0') ?? 0.0,
      description: json['description'],
    );
  }
}

class ServiceCombo {
  final int id;
  final int branchId;
  final String name;
  final double price;
  final double discount;
  final int durationMinutes;
  final String? description;
  final String serviceType;
  final double homeSurcharge;

  ServiceCombo({
    required this.id,
    required this.branchId,
    required this.name,
    required this.price,
    required this.discount,
    required this.durationMinutes,
    this.description,
    this.serviceType = 'IN_STUDIO',
    this.homeSurcharge = 0.0,
  });

  double get originalPrice => price + discount;

  factory ServiceCombo.fromJson(Map<String, dynamic> json) {
    return ServiceCombo(
      id: json['id'] ?? 0,
      branchId: json['branch_id'] ?? 0,
      name: json['name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      durationMinutes: json['duration_minutes'] ?? 45,
      description: json['description'],
      serviceType: json['service_type'] ?? 'IN_STUDIO',
      homeSurcharge: double.tryParse(json['home_surcharge']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class Staff {
  final int id;
  final int branchId;
  final String name;
  final String? role;
  final bool isBookable;
  final String? avatar;

  Staff({
    required this.id,
    required this.branchId,
    required this.name,
    this.role,
    this.isBookable = true,
    this.avatar,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] ?? 0,
      branchId: json['branch_id'] ?? 0,
      name: json['name'] ?? 'Stylist',
      role: json['role'] ?? 'Specialist',
      isBookable: json['is_bookable'] == 1 || json['is_bookable'] == true,
      avatar: json['avatar'],
    );
  }
}

class CustomerBooking {
  final int id;
  final int tenantId;
  final String salonName;
  final String salonPhone;
  final String branchName;
  final String branchAddress;
  final String serviceName;
  final String staffName;
  final String bookingType;
  final String serviceAddress;
  final String addressLandmark;
  final String occasionType;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final double amount;
  final double travelFee;
  final String status;
  final String paymentStatus;
  final bool canCancel;
  final int cancellationBufferMinutes;
  final String cancellationPolicyText;
  final String? createdAt;

  CustomerBooking({
    required this.id,
    required this.tenantId,
    required this.salonName,
    required this.salonPhone,
    required this.branchName,
    required this.branchAddress,
    required this.serviceName,
    required this.staffName,
    required this.bookingType,
    required this.serviceAddress,
    required this.addressLandmark,
    required this.occasionType,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.amount,
    required this.travelFee,
    required this.status,
    required this.paymentStatus,
    required this.canCancel,
    required this.cancellationBufferMinutes,
    required this.cancellationPolicyText,
    this.createdAt,
  });

  factory CustomerBooking.fromJson(Map<String, dynamic> json) {
    return CustomerBooking(
      id: json['id'] ?? 0,
      tenantId: json['tenant_id'] ?? 0,
      salonName: json['salon_name'] ?? 'Salon Partner',
      salonPhone: json['salon_phone'] ?? '+91 98765 43210',
      branchName: json['branch_name'] ?? 'Main Branch',
      branchAddress: json['branch_address'] ?? '',
      serviceName: json['service_name'] ?? 'Salon Service',
      staffName: json['staff_name'] ?? 'Assigned Stylist',
      bookingType: json['booking_type'] ?? 'IN_STUDIO',
      serviceAddress: json['service_address'] ?? '',
      addressLandmark: json['address_landmark'] ?? '',
      occasionType: json['occasion_type'] ?? '',
      bookingDate: json['booking_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      travelFee: double.tryParse(json['travel_fee']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'PENDING',
      paymentStatus: json['payment_status'] ?? 'PENDING',
      canCancel: json['can_cancel'] == true,
      cancellationBufferMinutes: json['cancellation_buffer_minutes'] ?? 120,
      cancellationPolicyText: json['cancellation_policy_text'] ?? 'Free cancellation up to 2 hours before appointment.',
      createdAt: json['created_at'],
    );
  }
}

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;
  final Map<String, dynamic>? data;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });
}

