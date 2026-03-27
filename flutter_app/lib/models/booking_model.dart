// ============================================
// Booking & Service Models
// ============================================

/// A service offered by a pro (e.g., "Men's Haircut - 45 min - R150")
class ProServiceModel {
  final String id;
  final String proId;
  final String serviceName;
  final String? description;
  final int durationMinutes;
  final double price;
  final bool isActive;

  ProServiceModel({
    required this.id,
    required this.proId,
    required this.serviceName,
    this.description,
    required this.durationMinutes,
    required this.price,
    this.isActive = true,
  });

  factory ProServiceModel.fromJson(Map<String, dynamic> json) {
    return ProServiceModel(
      id: json['id'],
      proId: json['pro_id'],
      serviceName: json['service_name'],
      description: json['description'],
      durationMinutes: json['duration_minutes'],
      price: double.parse(json['price'].toString()),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pro_id': proId,
      'service_name': serviceName,
      'description': description,
      'duration_minutes': durationMinutes,
      'price': price,
      'is_active': isActive,
    };
  }
}

/// A booking between a client and a pro.
class BookingModel {
  final String id;
  final String clientId;
  final String proId;
  final String serviceId;
  final String bookingType; // 'instant' or 'scheduled'
  final String status; // 'pending', 'accepted', 'in_progress', 'completed', etc.
  final String serviceAddress;
  final double? serviceLatitude;
  final double? serviceLongitude;
  final DateTime? scheduledStart;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final int? durationMinutes;
  final double servicePrice;
  final double bookingFee;
  final double commissionRate;
  final double totalAmount;
  final String? clientNotes;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.proId,
    required this.serviceId,
    required this.bookingType,
    required this.status,
    required this.serviceAddress,
    this.serviceLatitude,
    this.serviceLongitude,
    this.scheduledStart,
    this.actualStart,
    this.actualEnd,
    this.durationMinutes,
    required this.servicePrice,
    this.bookingFee = 10.0,
    this.commissionRate = 10.0,
    required this.totalAmount,
    this.clientNotes,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      clientId: json['client_id'],
      proId: json['pro_id'],
      serviceId: json['service_id'],
      bookingType: json['booking_type'],
      status: json['status'],
      serviceAddress: json['service_address'],
      serviceLatitude: json['service_latitude'] != null
          ? double.parse(json['service_latitude'].toString())
          : null,
      serviceLongitude: json['service_longitude'] != null
          ? double.parse(json['service_longitude'].toString())
          : null,
      scheduledStart: json['scheduled_start'] != null
          ? DateTime.parse(json['scheduled_start'])
          : null,
      actualStart: json['actual_start'] != null
          ? DateTime.parse(json['actual_start'])
          : null,
      actualEnd: json['actual_end'] != null
          ? DateTime.parse(json['actual_end'])
          : null,
      durationMinutes: json['duration_minutes'],
      servicePrice: double.parse(json['service_price'].toString()),
      bookingFee: double.parse((json['booking_fee'] ?? 10.0).toString()),
      commissionRate:
          double.parse((json['commission_rate'] ?? 10.0).toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      clientNotes: json['client_notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// A vouch (trust endorsement) from a client to a pro.
class VouchModel {
  final String id;
  final String voucherId;
  final String voucheeId;
  final String? bookingId;
  final String? vouchText;
  final DateTime createdAt;
  // These come from joined data (not the vouches table directly)
  final String? voucherName;
  final String? voucherPhotoUrl;
  final double? distanceKm;

  VouchModel({
    required this.id,
    required this.voucherId,
    required this.voucheeId,
    this.bookingId,
    this.vouchText,
    required this.createdAt,
    this.voucherName,
    this.voucherPhotoUrl,
    this.distanceKm,
  });

  factory VouchModel.fromJson(Map<String, dynamic> json) {
    return VouchModel(
      id: json['id'],
      voucherId: json['voucher_id'] ?? '',
      voucheeId: json['vouchee_id'] ?? '',
      bookingId: json['booking_id'],
      vouchText: json['vouch_text'],
      createdAt: DateTime.parse(json['created_at']),
      voucherName: json['voucher_name'],
      voucherPhotoUrl: json['voucher_photo'],
      distanceKm: json['distance_km'] != null
          ? double.parse(json['distance_km'].toString())
          : null,
    );
  }
}
