import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/constants.dart';
import '../profile/pro_profile_screen.dart';

/// Shows the client's list of favorited service providers.
/// Each card shows the pro's name, photo, category, vouch count,
/// and how many times the client has booked them.
class MyProsScreen extends StatefulWidget {
  const MyProsScreen({super.key});

  @override
  State<MyProsScreen> createState() => _MyProsScreenState();
}

class _MyProsScreenState extends State<MyProsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch favorites with joined pro profile data
      final data = await _supabase
          .from('client_favorites')
          .select('''
            id,
            total_bookings,
            last_booked,
            added_at,
            pro_id,
            profiles!client_favorites_pro_id_fkey (
              display_name,
              profile_photo_url
            ),
            pro_profiles!client_favorites_pro_id_fkey (
              service_categories,
              vouch_count,
              certification_status,
              is_available_now
            )
          ''')
          .eq('client_id', userId)
          .order('last_booked', ascending: false);

      setState(() {
        _favorites = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load favorites: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(String favoriteId, String proName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $proName?'),
        content: const Text('You can always add them back later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from('client_favorites').delete().eq('id', favoriteId);
        setState(() {
          _favorites.removeWhere((f) => f['id'] == favoriteId);
        });
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('No favorite pros yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'When you find a pro you love, tap the heart icon on their profile to save them here for easy rebooking.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final fav = _favorites[index];
          final profile = fav['profiles'] ?? {};
          final proProfile = fav['pro_profiles'] ?? {};
          final name = profile['display_name'] ?? 'Unknown Pro';
          final photoUrl = profile['profile_photo_url'];
          final categories =
              List<String>.from(proProfile['service_categories'] ?? []);
          final vouchCount = proProfile['vouch_count'] ?? 0;
          final certStatus = proProfile['certification_status'] ?? 'new';
          final isAvailable = proProfile['is_available_now'] ?? false;
          final totalBookings = fav['total_bookings'] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProProfileScreen(
                      proUserId: fav['pro_id'],
                      proName: name,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Profile photo with availability indicator
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        ),
                        if (isAvailable)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Pro info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              if (certStatus != 'new') ...[
                                const SizedBox(width: 6),
                                Icon(Icons.verified,
                                    size: 16,
                                    color: certStatus == 'certified'
                                        ? Colors.amber
                                        : Colors.blue),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Categories
                          if (categories.isNotEmpty)
                            Text(
                              categories
                                  .take(3)
                                  .map((c) =>
                                      AppConstants.serviceCategories[c]
                                          ?['label'] ??
                                      c)
                                  .join(', '),
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.volunteer_activism,
                                  size: 14, color: Colors.amber[700]),
                              const SizedBox(width: 4),
                              Text('$vouchCount vouches',
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 12),
                              const Icon(Icons.history,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '$totalBookings booking${totalBookings == 1 ? '' : 's'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Remove button
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      tooltip: 'Remove from favorites',
                      onPressed: () => _removeFavorite(fav['id'], name),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
