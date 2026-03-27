// ============================================
// Map Screen - The Heart of VouchSA
// ============================================
//
// This is the main screen of the app. It shows:
// - A Google Map centered on the user's location
// - Colored pins for available service providers
// - A search/filter bar at the top
// - A "Available Now" toggle for pros
//
// IMPORTANT: For this to work, you need:
// 1. A Google Maps API key (see constants.dart)
// 2. Location permission from the user
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../utils/constants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Track which bottom nav tab is selected
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Get user's location when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final location = context.watch<LocationProvider>();

    return Scaffold(
      // ============================================
      // APP BAR
      // ============================================
      appBar: AppBar(
        title: const Text(
          'VouchSA',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Notification bell
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications screen
            },
          ),
          // Profile icon
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // TODO: Navigate to profile screen
            },
          ),
        ],
      ),

      // ============================================
      // BODY - Changes based on bottom nav selection
      // ============================================
      body: _buildBody(_currentIndex, location),

      // ============================================
      // BOTTOM NAVIGATION BAR
      // ============================================
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'My Pros',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
      ),

      // ============================================
      // FLOATING ACTION BUTTON (Pro availability toggle)
      // ============================================
      // Only shown to pros — lets them toggle "Available Now"
      floatingActionButton: auth.currentUser?.userType != 'client'
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (location.isTracking) {
                  location.stopTracking();
                } else {
                  await location.startTracking();
                }
              },
              icon: Icon(
                location.isTracking
                    ? Icons.location_off
                    : Icons.location_on,
              ),
              label: Text(
                location.isTracking ? 'Go Offline' : 'Go Live',
              ),
              backgroundColor: location.isTracking
                  ? Colors.red
                  : AppConstants.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  /// Builds the correct body widget based on the selected tab
  Widget _buildBody(int index, LocationProvider location) {
    switch (index) {
      case 0:
        return _buildMapView(location);
      case 1:
        return _buildBookingsPlaceholder();
      case 2:
        return _buildMyProsPlaceholder();
      case 3:
        return _buildChatPlaceholder();
      default:
        return _buildMapView(location);
    }
  }

  // ============================================
  // MAP VIEW
  // ============================================
  Widget _buildMapView(LocationProvider location) {
    if (location.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                location.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => location.getCurrentLocation(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (location.currentPosition == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      );
    }

    // Once we have the location, show the map
    // TODO: Replace with actual GoogleMap widget
    // For now, show a placeholder with the user's coordinates
    return Stack(
      children: [
        // Placeholder for Google Map
        // In the real app, this would be:
        // GoogleMap(
        //   initialCameraPosition: CameraPosition(
        //     target: LatLng(location.latitude!, location.longitude!),
        //     zoom: 14,
        //   ),
        //   markers: _proMarkers, // Pins for available pros
        //   myLocationEnabled: true,
        // )
        Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Map will appear here',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your location: ${location.latitude?.toStringAsFixed(4)}, ${location.longitude?.toStringAsFixed(4)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),

        // ============================================
        // SEARCH BAR (Floating on top of the map)
        // ============================================
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search for a service...',
                border: InputBorder.none,
                icon: Icon(Icons.search),
              ),
            ),
          ),
        ),

        // ============================================
        // CATEGORY FILTER CHIPS (Below search bar)
        // ============================================
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: AppConstants.serviceCategories.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.value['label'] as String),
                    avatar: Icon(
                      entry.value['icon'] as IconData,
                      size: 16,
                      color: entry.value['color'] as Color,
                    ),
                    onSelected: (selected) {
                      // TODO: Filter map pins by category
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // PLACEHOLDER SCREENS (To be built later)
  // ============================================
  Widget _buildBookingsPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Your Bookings', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('Upcoming and past bookings will appear here.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMyProsPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('My Pros', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('Your favorite service providers will appear here.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChatPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Messages', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('Chat with your pros and clients here.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
