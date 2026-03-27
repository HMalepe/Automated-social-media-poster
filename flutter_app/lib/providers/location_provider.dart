// ============================================
// Location Provider - Manages GPS Tracking
// ============================================
//
// Handles two things:
// 1. Getting the CLIENT's location (to show nearby pros)
// 2. Updating the PRO's location every 30 seconds (when available)
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class LocationProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Current user's position
  Position? _currentPosition;
  bool _isTracking = false;
  String? _errorMessage;

  // Timer for periodic location updates (pro mode)
  Timer? _locationTimer;

  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  String? get errorMessage => _errorMessage;
  double? get latitude => _currentPosition?.latitude;
  double? get longitude => _currentPosition?.longitude;

  // ============================================
  // GET CURRENT LOCATION (One-time)
  // ============================================
  // Called when the app opens or client opens the map.
  // Gets a single GPS reading.
  //
  // PERMISSIONS:
  // The first time this is called, the phone will ask:
  // "Allow VouchSA to access your location?"
  // The user must say yes, or the map won't work.

  Future<Position?> getCurrentLocation() async {
    _errorMessage = null;

    // Step 1: Check if location services are turned on
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = 'Please turn on location services in your phone settings.';
      notifyListeners();
      return null;
    }

    // Step 2: Check if we have permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Ask for permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorMessage = 'Location permission denied. VouchSA needs this to show nearby pros.';
        notifyListeners();
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _errorMessage = 'Location permanently denied. Please enable in phone settings.';
      notifyListeners();
      return null;
    }

    // Step 3: Get the actual position
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      _errorMessage = 'Could not get your location. Please try again.';
      notifyListeners();
      return null;
    }
  }

  // ============================================
  // START TRACKING (For Pros - "Available Now")
  // ============================================
  // When a pro toggles "Available Now", we start sending their
  // location to Supabase every 30 seconds so clients can see
  // them on the map in real-time.

  Future<void> startTracking() async {
    if (_isTracking) return; // Already tracking

    // Get initial position
    await getCurrentLocation();
    if (_currentPosition == null) return; // No permission

    _isTracking = true;
    notifyListeners();

    // Send location immediately
    await _updateLocationInDatabase();

    // Then update every 30 seconds
    _locationTimer = Timer.periodic(
      Duration(seconds: AppConstants.locationUpdateSeconds),
      (_) async {
        await getCurrentLocation();
        if (_currentPosition != null) {
          await _updateLocationInDatabase();
        }
      },
    );
  }

  // ============================================
  // STOP TRACKING
  // ============================================
  // Called when pro toggles "Unavailable" or closes the app.

  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
    notifyListeners();
  }

  // ============================================
  // UPDATE LOCATION IN DATABASE
  // ============================================
  // Sends the pro's current GPS coordinates to Supabase.
  // Uses "upsert" which means: update if exists, insert if doesn't.

  Future<void> _updateLocationInDatabase() async {
    if (_currentPosition == null) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('pro_locations').upsert({
        'pro_id': userId,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'accuracy': _currentPosition!.accuracy,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail — we'll try again in 30 seconds
      debugPrint('Location update failed: $e');
    }
  }

  // Clean up when the provider is destroyed
  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
