// ============================================
// User & Profile Models
// ============================================
//
// WHAT IS A MODEL?
// A model is a Dart class that represents data from your database.
// Think of it as a template/blueprint. When you get data from Supabase,
// it comes as raw JSON (like a messy pile of text). A model organizes
// that data into neat, typed fields you can use in your app.
//
// Example: Instead of data['display_name'] (which might not exist),
// you use user.displayName (which Dart guarantees exists).
// ============================================

/// Represents a user in the VouchSA app.
/// Every person (client or pro) has one of these.
class UserModel {
  final String id;
  final String phoneNumber;
  final String userType; // 'pro', 'client', or 'both'
  final bool isVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.userType,
    required this.isVerified,
    required this.createdAt,
  });

  /// Creates a UserModel from a database row (JSON map).
  /// "factory" is a special constructor that can do logic before creating the object.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      phoneNumber: json['phone_number'],
      userType: json['user_type'],
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Converts this model back to JSON (for sending to the database).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'user_type': userType,
      'is_verified': isVerified,
    };
  }
}

/// Represents a user's public profile.
class ProfileModel {
  final String userId;
  final String displayName;
  final String? bio;
  final String? profilePhotoUrl;
  final String? voiceIntroUrl;
  final String? videoIntroUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  ProfileModel({
    required this.userId,
    required this.displayName,
    this.bio,
    this.profilePhotoUrl,
    this.voiceIntroUrl,
    this.videoIntroUrl,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['user_id'],
      displayName: json['display_name'],
      bio: json['bio'],
      profilePhotoUrl: json['profile_photo_url'],
      voiceIntroUrl: json['voice_intro_url'],
      videoIntroUrl: json['video_intro_url'],
      address: json['address'],
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'bio': bio,
      'profile_photo_url': profilePhotoUrl,
      'voice_intro_url': voiceIntroUrl,
      'video_intro_url': videoIntroUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// Represents a service provider's professional profile.
class ProProfileModel {
  final String userId;
  final List<String> serviceCategories;
  final double? hourlyRate;
  final int serviceRadiusKm;
  final bool isAvailableNow;
  final int totalJobsCompleted;
  final double totalEarnings;
  final int vouchCount;
  final double vouchRate;
  final String certificationStatus; // 'new', 'trusted', 'certified'

  ProProfileModel({
    required this.userId,
    required this.serviceCategories,
    this.hourlyRate,
    this.serviceRadiusKm = 10,
    this.isAvailableNow = false,
    this.totalJobsCompleted = 0,
    this.totalEarnings = 0,
    this.vouchCount = 0,
    this.vouchRate = 0,
    this.certificationStatus = 'new',
  });

  factory ProProfileModel.fromJson(Map<String, dynamic> json) {
    return ProProfileModel(
      userId: json['user_id'],
      serviceCategories: List<String>.from(json['service_categories'] ?? []),
      hourlyRate: json['hourly_rate'] != null
          ? double.parse(json['hourly_rate'].toString())
          : null,
      serviceRadiusKm: json['service_radius_km'] ?? 10,
      isAvailableNow: json['is_available_now'] ?? false,
      totalJobsCompleted: json['total_jobs_completed'] ?? 0,
      totalEarnings: json['total_earnings'] != null
          ? double.parse(json['total_earnings'].toString())
          : 0,
      vouchCount: json['vouch_count'] ?? 0,
      vouchRate: json['vouch_rate'] != null
          ? double.parse(json['vouch_rate'].toString())
          : 0,
      certificationStatus: json['certification_status'] ?? 'new',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'service_categories': serviceCategories,
      'hourly_rate': hourlyRate,
      'service_radius_km': serviceRadiusKm,
      'is_available_now': isAvailableNow,
    };
  }
}
