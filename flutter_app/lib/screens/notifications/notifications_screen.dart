import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data model for a notification
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? relatedBookingId;
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.relatedBookingId,
    this.actionUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      type: json['notification_type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      relatedBookingId: json['related_booking_id'],
      actionUrl: json['action_url'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Shows a list of all notifications for the current user.
/// Supports pull-to-refresh and mark-as-read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _notifications =
            (data as List).map((n) => AppNotification.fromJson(n)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final old = _notifications[index];
          _notifications[index] = AppNotification(
            id: old.id,
            type: old.type,
            title: old.title,
            body: old.body,
            relatedBookingId: old.relatedBookingId,
            actionUrl: old.actionUrl,
            isRead: true,
            createdAt: old.createdAt,
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      setState(() {
        _notifications = _notifications.map((n) {
          return AppNotification(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            relatedBookingId: n.relatedBookingId,
            actionUrl: n.actionUrl,
            isRead: true,
            createdAt: n.createdAt,
          );
        }).toList();
      });
    } catch (_) {}
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_booking':
        return Icons.calendar_today;
      case 'booking_accepted':
        return Icons.check_circle;
      case 'booking_declined':
        return Icons.cancel;
      case 'job_started':
        return Icons.play_circle;
      case 'job_completed':
        return Icons.task_alt;
      case 'new_vouch':
        return Icons.volunteer_activism;
      case 'payment_received':
        return Icons.payments;
      case 'payout_completed':
        return Icons.account_balance;
      case 'dispute_filed':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'new_booking':
        return Colors.blue;
      case 'booking_accepted':
        return Colors.green;
      case 'booking_declined':
        return Colors.red;
      case 'job_started':
        return Colors.orange;
      case 'job_completed':
        return Colors.green;
      case 'new_vouch':
        return Colors.amber;
      case 'payment_received':
        return Colors.green;
      case 'payout_completed':
        return Colors.teal;
      case 'dispute_filed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No notifications yet',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ll see booking updates,\nvouches, and more here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _colorForType(n.type).withOpacity(0.15),
                          child: Icon(_iconForType(n.type),
                              color: _colorForType(n.type)),
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight:
                                n.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.body, maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(_timeAgo(n.createdAt),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                        trailing: n.isRead
                            ? null
                            : Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        onTap: () {
                          if (!n.isRead) _markAsRead(n.id);
                          // Navigate to related booking if available
                          if (n.relatedBookingId != null) {
                            // Navigation would go here based on notification type
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
