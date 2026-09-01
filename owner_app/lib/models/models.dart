class OwnerUser {
  final int id;
  final String name;
  final String email;
  final int? tenantId;

  OwnerUser({
    required this.id,
    required this.name,
    required this.email,
    this.tenantId,
  });

  factory OwnerUser.fromJson(Map<String, dynamic> json) {
    return OwnerUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      tenantId: json['tenant_id'],
    );
  }
}

class OwnerTenant {
  final int id;
  final String businessName;
  final String businessType;
  final String status;
  final String bookingPolicy;
  final String phone;
  final String address;
  final String cancellationPolicy;
  final bool homeServiceEnabled;
  final bool eventWeddingEnabled;
  final int homeServiceRadiusKm;
  final double homeServiceTravelFee;
  final double eventMinBookingAmount;
  final String homeServiceNotes;

  OwnerTenant({
    required this.id,
    required this.businessName,
    required this.businessType,
    required this.status,
    required this.bookingPolicy,
    required this.phone,
    required this.address,
    required this.cancellationPolicy,
    this.homeServiceEnabled = true,
    this.eventWeddingEnabled = true,
    this.homeServiceRadiusKm = 10,
    this.homeServiceTravelFee = 100.0,
    this.eventMinBookingAmount = 1500.0,
    this.homeServiceNotes = '',
  });

  factory OwnerTenant.fromJson(Map<String, dynamic> json) {
    return OwnerTenant(
      id: json['id'] ?? 0,
      businessName: json['business_name'] ?? 'Royal Grooming Studio',
      businessType: json['business_type'] ?? 'Premium Grooming Salon',
      status: json['status'] ?? 'VERIFIED',
      bookingPolicy: json['booking_policy'] ?? 'PAY_AT_SALON',
      phone: json['phone'] ?? '+91 98765 43210',
      address: json['address'] ?? 'MG Road, Sector 14, City Center',
      cancellationPolicy: json['cancellation_policy'] ?? 'Free cancellation up to 2 hours before slot',
      homeServiceEnabled: _parseBool(json['home_service_enabled'], true),
      eventWeddingEnabled: _parseBool(json['event_wedding_enabled'], true),
      homeServiceRadiusKm: int.tryParse(json['home_service_radius_km']?.toString() ?? '') ?? 10,
      homeServiceTravelFee: double.tryParse(json['home_service_travel_fee']?.toString() ?? '') ?? 100.0,
      eventMinBookingAmount: double.tryParse(json['event_min_booking_amount']?.toString() ?? '') ?? 1500.0,
      homeServiceNotes: json['home_service_notes']?.toString() ?? '',
    );
  }
}

class OwnerBranch {
  final int id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String pinCode;
  final String contactMobile;
  final bool isActive;
  final int staffCount;
  final int combosCount;

  OwnerBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.state = '',
    this.pinCode = '',
    this.contactMobile = '',
    this.isActive = true,
    this.staffCount = 0,
    this.combosCount = 0,
  });

  factory OwnerBranch.fromJson(Map<String, dynamic> json) {
    return OwnerBranch(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pinCode: json['pin_code'] ?? '',
      contactMobile: json['contact_mobile'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == null,
      staffCount: json['staff_count'] ?? 0,
      combosCount: json['combos_count'] ?? 0,
    );
  }
}

class OwnerService {
  final int id;
  final int? branchId;
  final String branchName;
  final String name;
  final String category;
  final String serviceType; // 'IN_STUDIO', 'AT_HOME', 'EVENT_WEDDING', 'ANY'
  final double price;
  final double homeSurcharge;
  final int durationMinutes;
  final bool isActive;

  OwnerService({
    required this.id,
    this.branchId,
    this.branchName = '',
    required this.name,
    required this.category,
    this.serviceType = 'IN_STUDIO',
    required this.price,
    this.homeSurcharge = 0.0,
    required this.durationMinutes,
    this.isActive = true,
  });

  factory OwnerService.fromJson(Map<String, dynamic> json) {
    return OwnerService(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      branchId: json['branch_id'] is int ? json['branch_id'] : int.tryParse(json['branch_id']?.toString() ?? ''),
      branchName: json['branch'] is Map ? (json['branch']['name'] ?? '') : (json['branch_name']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      serviceType: json['service_type']?.toString() ?? 'IN_STUDIO',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      homeSurcharge: double.tryParse(json['home_surcharge']?.toString() ?? '') ?? 0.0,
      durationMinutes: int.tryParse(json['duration_minutes']?.toString() ?? '') ?? 30,
      isActive: _parseBool(json['is_active'], true),
    );
  }
}

bool _parseBool(dynamic val, bool def) {
  if (val == null) return def;
  if (val is bool) return val;
  if (val is int) return val == 1;
  if (val is double) return val == 1.0;
  if (val is String) {
    final s = val.toLowerCase().trim();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return def;
}

class OwnerCombo {
  final int id;
  final int? branchId;
  final String branchName;
  final String name;
  final String description;
  final String serviceType;
  final double price;
  final double homeSurcharge;
  final double discount;
  final int durationMinutes;
  final bool isActive;
  final List<OwnerService> services;

  OwnerCombo({
    required this.id,
    this.branchId,
    this.branchName = '',
    required this.name,
    this.description = '',
    this.serviceType = 'IN_STUDIO',
    required this.price,
    this.homeSurcharge = 0.0,
    this.discount = 0.0,
    required this.durationMinutes,
    required this.isActive,
    this.services = const [],
  });

  factory OwnerCombo.fromJson(Map<String, dynamic> json) {
    List<OwnerService> parsedServices = [];
    if (json['services'] is List) {
      for (var s in (json['services'] as List)) {
        if (s is Map) {
          parsedServices.add(OwnerService.fromJson(Map<String, dynamic>.from(s)));
        }
      }
    }

    return OwnerCombo(
      id: json['id'] ?? 0,
      branchId: json['branch_id'] is int ? json['branch_id'] : int.tryParse(json['branch_id']?.toString() ?? ''),
      branchName: json['branch'] is Map ? (json['branch']['name'] ?? '') : (json['branch_name']?.toString() ?? ''),
      name: json['name'] ?? '',
      description: json['description']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? 'IN_STUDIO',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      homeSurcharge: double.tryParse(json['home_surcharge']?.toString() ?? '') ?? 0.0,
      discount: double.tryParse(json['discount'].toString()) ?? 0.0,
      durationMinutes: json['duration_minutes'] ?? 60,
      isActive: _parseBool(json['is_active'], true),
      services: parsedServices,
    );
  }
}

class OwnerStaff {
  final int id;
  final String name;
  final String role;
  final bool isBookable;
  final String? email;
  final String? mobile;
  final bool isActive;
  final List<OwnerService> services;

  OwnerStaff({
    required this.id,
    required this.name,
    required this.role,
    required this.isBookable,
    this.email,
    this.mobile,
    this.isActive = true,
    this.services = const [],
  });

  factory OwnerStaff.fromJson(Map<String, dynamic> json) {
    List<OwnerService> parsedServices = [];
    if (json['services'] is List) {
      for (var item in json['services']) {
        if (item != null) {
          try {
            if (item is Map) {
              parsedServices.add(OwnerService.fromJson(Map<String, dynamic>.from(item)));
            } else if (item is OwnerService) {
              parsedServices.add(item);
            }
          } catch (_) {}
        }
      }
    }

    return OwnerStaff(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      role: json['role'] ?? 'Stylist',
      isBookable: _parseBool(json['is_bookable'], true),
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString(),
      isActive: _parseBool(json['is_active'], true),
      services: parsedServices,
    );
  }
}

class OwnerPromotion {
  final int id;
  final int? branchId;
  final String branchName;
  final String title;
  final int discountPercent;
  final String timeWindow;
  final List<int> daysOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;

  OwnerPromotion({
    required this.id,
    this.branchId,
    this.branchName = '',
    required this.title,
    required this.discountPercent,
    required this.timeWindow,
    this.daysOfWeek = const [],
    this.startTime = '14:00',
    this.endTime = '17:00',
    required this.isActive,
  });

  factory OwnerPromotion.fromJson(Map<String, dynamic> json) {
    List<int> days = [];
    if (json['days_of_week'] is List) {
      for (var d in (json['days_of_week'] as List)) {
        if (d is int) {
          days.add(d);
        } else if (d != null) {
          final p = int.tryParse(d.toString());
          if (p != null) {
            days.add(p);
          }
        }
      }
    }

    return OwnerPromotion(
      id: json['id'] ?? 0,
      branchId: json['branch_id'] is int ? json['branch_id'] : int.tryParse(json['branch_id']?.toString() ?? ''),
      branchName: json['branch_name']?.toString() ?? '',
      title: json['title'] ?? '',
      discountPercent: (json['discount_percent'] is num) ? (json['discount_percent'] as num).toInt() : (int.tryParse(json['discount_percent']?.toString() ?? '0') ?? 0),
      timeWindow: json['time_window']?.toString() ?? '',
      daysOfWeek: days,
      startTime: json['start_time']?.toString() ?? '14:00',
      endTime: json['end_time']?.toString() ?? '17:00',
      isActive: _parseBool(json['is_active'], true),
    );
  }
}

class OwnerRushPricingRule {
  final int id;
  final int? branchId;
  final String branchName;
  final String title;
  final double surgeAmount;
  final String timeSlot;
  final List<int> daysOfWeek;
  final String startTime;
  final String endTime;
  final bool isEnabled;

  OwnerRushPricingRule({
    required this.id,
    this.branchId,
    this.branchName = '',
    required this.title,
    required this.surgeAmount,
    required this.timeSlot,
    this.daysOfWeek = const [],
    this.startTime = '16:00',
    this.endTime = '20:00',
    required this.isEnabled,
  });

  factory OwnerRushPricingRule.fromJson(Map<String, dynamic> json) {
    List<int> days = [];
    if (json['days_of_week'] is List) {
      for (var d in (json['days_of_week'] as List)) {
        if (d is int) {
          days.add(d);
        } else if (d != null) {
          final p = int.tryParse(d.toString());
          if (p != null) {
            days.add(p);
          }
        }
      }
    }

    return OwnerRushPricingRule(
      id: json['id'] ?? 0,
      branchId: json['branch_id'] is int ? json['branch_id'] : int.tryParse(json['branch_id']?.toString() ?? ''),
      branchName: json['branch_name']?.toString() ?? '',
      title: json['title'] ?? '',
      surgeAmount: double.tryParse(json['surge_amount'].toString()) ?? 0.0,
      timeSlot: json['time_slot']?.toString() ?? '',
      daysOfWeek: days,
      startTime: json['start_time']?.toString() ?? '16:00',
      endTime: json['end_time']?.toString() ?? '20:00',
      isEnabled: _parseBool(json['is_enabled'], true),
    );
  }
}

class OwnerCustomerCRM {
  final int id;
  final int? userId;
  final String name;
  final String phone;
  final String email;
  final String gender;
  final String notes;
  final int totalBookings;
  final double totalSpent;
  final bool isVip;
  final String source;

  OwnerCustomerCRM({
    required this.id,
    this.userId,
    required this.name,
    required this.phone,
    this.email = '',
    this.gender = '',
    this.notes = '',
    required this.totalBookings,
    required this.totalSpent,
    required this.isVip,
    this.source = 'MANUAL',
  });

  factory OwnerCustomerCRM.fromJson(Map<String, dynamic> json) {
    return OwnerCustomerCRM(
      id: json['id'] ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
      name: json['name']?.toString() ?? 'Client',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      totalBookings: (json['total_bookings'] is num) ? (json['total_bookings'] as num).toInt() : (int.tryParse(json['total_bookings']?.toString() ?? '0') ?? 0),
      totalSpent: double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0.0,
      isVip: _parseBool(json['is_vip'], false),
      source: json['source']?.toString() ?? 'MANUAL',
    );
  }
}

class OwnerBooking {
  final int id;
  final String customerName;
  final String customerMobile;
  final String serviceName;
  final String bookingType; // 'IN_STUDIO', 'AT_HOME', 'EVENT_WEDDING'
  final String serviceAddress;
  final String addressLandmark;
  final String occasionType;
  final double travelFee;
  final double amount;
  final String status;
  final String bookingDate;
  final String startTime;

  OwnerBooking({
    required this.id,
    required this.customerName,
    this.customerMobile = '',
    required this.serviceName,
    this.bookingType = 'IN_STUDIO',
    this.serviceAddress = '',
    this.addressLandmark = '',
    this.occasionType = '',
    this.travelFee = 0.0,
    required this.amount,
    required this.status,
    required this.bookingDate,
    required this.startTime,
  });

  factory OwnerBooking.fromJson(Map<String, dynamic> json) {
    return OwnerBooking(
      id: json['id'] ?? 0,
      customerName: json['customer']?['name'] ?? json['user']?['name'] ?? json['customer_name'] ?? 'Walk-in Client',
      customerMobile: json['customer']?['mobile'] ?? json['user']?['mobile'] ?? json['customer_mobile'] ?? '',
      serviceName: json['service']?['name'] ?? json['combo']?['name'] ?? json['service_name'] ?? 'Salon Service',
      bookingType: json['booking_type']?.toString() ?? 'IN_STUDIO',
      serviceAddress: json['service_address']?.toString() ?? '',
      addressLandmark: json['address_landmark']?.toString() ?? '',
      occasionType: json['occasion_type']?.toString() ?? '',
      travelFee: double.tryParse(json['travel_fee']?.toString() ?? '') ?? 0.0,
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      status: json['status'] ?? 'CONFIRMED',
      bookingDate: json['booking_date'] ?? '',
      startTime: json['start_time'] ?? '',
    );
  }
}

class LedgerEntry {
  final int id;
  final double amount;
  final String type;
  final String description;
  final String status;
  final String createdAt;

  LedgerEntry({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] ?? 0,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      type: json['type'] ?? 'DEBIT',
      description: json['description'] ?? '',
      status: json['status'] ?? 'PENDING',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class OwnerSlotBooking {
  final int id;
  final String customerName;
  final String customerPhone;
  final String serviceName;
  final String bookingType; // 'IN_STUDIO', 'AT_HOME', 'EVENT_WEDDING'
  final String serviceAddress;
  final String addressLandmark;
  final String occasionType;
  final double travelFee;
  final String amount;
  final String status;
  final String startTime;
  final String? endTime;

  OwnerSlotBooking({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.serviceName,
    this.bookingType = 'IN_STUDIO',
    this.serviceAddress = '',
    this.addressLandmark = '',
    this.occasionType = '',
    this.travelFee = 0.0,
    required this.amount,
    required this.status,
    required this.startTime,
    this.endTime,
  });

  factory OwnerSlotBooking.fromJson(Map<String, dynamic> json) {
    return OwnerSlotBooking(
      id: json['id'] ?? 0,
      customerName: json['customer_name'] ?? 'Walk-in Client',
      customerPhone: json['customer_phone'] ?? '',
      serviceName: json['service_name'] ?? 'Salon Service',
      bookingType: json['booking_type']?.toString() ?? 'IN_STUDIO',
      serviceAddress: json['service_address']?.toString() ?? '',
      addressLandmark: json['address_landmark']?.toString() ?? '',
      occasionType: json['occasion_type']?.toString() ?? '',
      travelFee: double.tryParse(json['travel_fee']?.toString() ?? '') ?? 0.0,
      amount: json['amount']?.toString() ?? '0.00',
      status: json['status'] ?? 'CONFIRMED',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'],
    );
  }
}

class OwnerTimeSlot {
  final String time;
  final bool isBooked;
  final OwnerSlotBooking? booking;

  OwnerTimeSlot({
    required this.time,
    required this.isBooked,
    this.booking,
  });

  factory OwnerTimeSlot.fromJson(Map<String, dynamic> json) {
    return OwnerTimeSlot(
      time: json['time'] ?? '',
      isBooked: json['is_booked'] ?? false,
      booking: json['booking'] != null
          ? OwnerSlotBooking.fromJson(Map<String, dynamic>.from(json['booking']))
          : null,
    );
  }
}

class OwnerStaffSchedule {
  final int staffId;
  final String staffName;
  final String staffRole;
  final List<OwnerTimeSlot> slots;
  final int bookedCount;
  final int availableCount;

  OwnerStaffSchedule({
    required this.staffId,
    required this.staffName,
    required this.staffRole,
    required this.slots,
    required this.bookedCount,
    required this.availableCount,
  });

  factory OwnerStaffSchedule.fromJson(Map<String, dynamic> json) {
    return OwnerStaffSchedule(
      staffId: json['staff_id'] ?? 0,
      staffName: json['staff_name'] ?? '',
      staffRole: json['staff_role'] ?? 'STAFF',
      slots: ((json['slots'] as List?) ?? [])
          .map<OwnerTimeSlot>((s) => OwnerTimeSlot.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      bookedCount: json['booked_count'] ?? 0,
      availableCount: json['available_count'] ?? 0,
    );
  }
}
