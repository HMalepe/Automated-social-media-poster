// ============================================
// Auth Provider - Manages Login State
// ============================================
//
// WHAT IS A PROVIDER?
// A provider is like a "shared brain" for your app. Multiple screens
// need to know: "Is the user logged in? What's their name?"
// Instead of each screen figuring this out independently, the
// AuthProvider holds this info and shares it with everyone.
//
// WHAT IS ChangeNotifier?
// It's a pattern where when data changes (e.g., user logs in),
// the provider "notifies" all screens that are listening,
// and they automatically update themselves.
// ============================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  // The Supabase client — our connection to the backend
  final SupabaseClient _supabase = Supabase.instance.client;

  // Current state
  UserModel? _currentUser;
  ProfileModel? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters — these let screens READ the state but not modify it directly
  UserModel? get currentUser => _currentUser;
  ProfileModel? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _supabase.auth.currentSession != null;
  String? get errorMessage => _errorMessage;

  // ============================================
  // SEND OTP (Step 1 of Login)
  // ============================================
  // User enters their phone number, we send them a one-time password via SMS.
  //
  // HOW OTP WORKS:
  // 1. User types: +27821234567
  // 2. Supabase sends an SMS with a 6-digit code: "Your code is 123456"
  // 3. User types the code into the app
  // 4. If correct, they're logged in!
  //
  // WHY OTP INSTEAD OF PASSWORDS?
  // - No password to forget
  // - Verifies they own the phone number
  // - Standard in South African apps (like FNB, Capitec)

  Future<bool> sendOtp(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Tell screens "something is loading"

    try {
      await _supabase.auth.signInWithOtp(
        phone: phoneNumber,
      );
      _isLoading = false;
      notifyListeners();
      return true; // OTP sent successfully
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to send OTP. Please check your phone number.';
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // VERIFY OTP (Step 2 of Login)
  // ============================================
  // User enters the 6-digit code they received.
  // If correct, Supabase creates a session (they're logged in).

  Future<bool> verifyOtp(String phoneNumber, String otpCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: otpCode,
        type: OtpType.sms,
      );

      if (response.session != null) {
        // Login successful! Now fetch or create their profile.
        await _loadUserProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Invalid code. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Verification failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // LOAD USER PROFILE
  // ============================================
  // After login, fetch the user's data from the database.
  // If they're new (first login), their profile won't exist yet.

  Future<void> _loadUserProfile() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return;

    try {
      // Try to get their user record
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle(); // Returns null if not found (instead of error)

      if (userData != null) {
        _currentUser = UserModel.fromJson(userData);

        // Also get their profile
        final profileData = await _supabase
            .from('profiles')
            .select()
            .eq('user_id', authUser.id)
            .maybeSingle();

        if (profileData != null) {
          _currentProfile = ProfileModel.fromJson(profileData);
        }
      }
      // If userData is null, they're a new user who needs to create a profile
    } catch (e) {
      _errorMessage = 'Failed to load profile.';
    }
  }

  // ============================================
  // CREATE PROFILE (For new users)
  // ============================================
  // Called after first-time login. Sets up their user record and profile.

  Future<bool> createProfile({
    required String displayName,
    required String userType, // 'pro', 'client', or 'both'
    String? bio,
    String? profilePhotoUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final authUser = _supabase.auth.currentUser;
    if (authUser == null) {
      _errorMessage = 'Not authenticated';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // Create user record
      await _supabase.from('users').upsert({
        'id': authUser.id,
        'phone_number': authUser.phone ?? '',
        'user_type': userType,
        'is_verified': true, // They verified via OTP
      });

      // Create profile
      await _supabase.from('profiles').upsert({
        'user_id': authUser.id,
        'display_name': displayName,
        'bio': bio,
        'profile_photo_url': profilePhotoUrl,
      });

      // If they're a pro, create a pro_profile too
      if (userType == 'pro' || userType == 'both') {
        await _supabase.from('pro_profiles').upsert({
          'user_id': authUser.id,
          'service_categories': [],
          'service_radius_km': 10,
        });
      }

      // Reload the profile
      await _loadUserProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create profile. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // LOGOUT
  // ============================================
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _currentProfile = null;
    notifyListeners();
  }
}
