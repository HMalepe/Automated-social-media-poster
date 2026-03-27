// ============================================
// Bookings List Screen
// ============================================
//
// Shows in the "Bookings" tab. Displays all bookings organized by status:
// - Active (pending, accepted, in_progress) at the top
// - Completed bookings below
// - Cancelled/disputed at the bottom
//
// Each booking is a card you can tap to see the full details
// (opens ActiveBookingScreen).
// ============================================

import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/constants.dart';
import 'active_booking_screen.dart';

class BookingsListScreen extends StatefulWidget {
  final bool isPro; // Show pro's bookings or client's bookings?

  const BookingsListScreen({super.key, this.isPro = false});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  final BookingService _bookingService = BookingService();
  List<BookingModel> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    final bookings = widget.isPro
        ? await _bookingService.getProBookings()
        : await _bookingService.getClientBookings();

    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No Bookings Yet', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              widget.isPro
                  ? 'When clients book you, they\'ll appear here.'
                  : 'Book a pro from the map to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Split bookings into active and past
    final active = _bookings
        .where(
            (b) => ['pending', 'accepted', 'in_progress'].contains(b.status))
        .toList();
    final past = _bookings
        .where((b) =>
            ['completed', 'cancelled', 'disputed'].contains(b.status))
        .toList();

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active bookings section
          if (active.isNotEmpty) ...[
            const Text(
              'Active',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...active.map(
                (booking) => _BookingCard(
                  booking: booking,
                  isPro: widget.isPro,
                  onTap: () => _openBooking(booking),
                )),
            const SizedBox(height: 24),
          ],

          // Past bookings section
          if (past.isNotEmpty) ...[
            Text(
              'Past',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ...past.map(
                (booking) => _BookingCard(
                  booking: booking,
                  isPro: widget.isPro,
                  onTap: () => _openBooking(booking),
                )),
          ],
        ],
      ),
    );
  }

  void _openBooking(BookingModel booking) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveBookingScreen(
          bookingId: booking.id,
          isPro: widget.isPro,
        ),
      ),
    );
  }
}

// ============================================
// Booking Card Widget
// ============================================
class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isPro;
  final VoidCallback onTap;

  const _BookingCard({
    required this.booking,
    required this.isPro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_statusIcon, color: _statusColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Booking info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceAddress,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R${booking.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatDate(booking.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),

              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (booking.status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return AppConstants.primaryColor;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'disputed':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (booking.status) {
      case 'pending':
        return Icons.hourglass_top;
      case 'accepted':
        return Icons.check;
      case 'in_progress':
        return Icons.play_circle_filled;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'disputed':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  String get _statusLabel {
    switch (booking.status) {
      case 'pending':
        return isPro ? 'Awaiting your response' : 'Waiting for pro...';
      case 'accepted':
        return isPro ? 'Head to client' : 'Pro is on the way';
      case 'in_progress':
        return 'Job in progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'disputed':
        return 'Under review';
      default:
        return booking.status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 24) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }
}
