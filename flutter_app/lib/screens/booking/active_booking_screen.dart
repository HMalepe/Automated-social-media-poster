// ============================================
// Active Booking Screen
// ============================================
//
// WHAT IS THIS?
// Shows the current state of a booking with live updates.
// Different views depending on who's looking and what state it's in:
//
// CLIENT sees:
// - "Waiting for pro to accept..." (pending)
// - "Pro is on the way! ETA: 28 min" (accepted)
// - "Job in progress — 23 min elapsed" (in_progress)
// - "Job complete! Vouch for your pro?" (completed)
//
// PRO sees:
// - "New booking request! Accept or Decline?" (pending)
// - "Navigate to client" (accepted)
// - "Job in progress — tap to complete" (in_progress)
//
// WHAT IS REALTIME HERE?
// The booking status updates LIVE. When the pro taps "Accept",
// the client's screen updates immediately without refreshing.
// This uses Supabase Realtime subscriptions.
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/constants.dart';
import 'vouch_screen.dart';

class ActiveBookingScreen extends StatefulWidget {
  final String bookingId;
  final bool isPro; // Are we showing the pro's view or client's view?

  const ActiveBookingScreen({
    super.key,
    required this.bookingId,
    this.isPro = false,
  });

  @override
  State<ActiveBookingScreen> createState() => _ActiveBookingScreenState();
}

class _ActiveBookingScreenState extends State<ActiveBookingScreen> {
  final BookingService _bookingService = BookingService();
  final SupabaseClient _supabase = Supabase.instance.client;

  BookingModel? _booking;
  bool _isLoading = true;
  bool _isActionLoading = false; // For accept/start/complete buttons
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  // Realtime subscription
  RealtimeChannel? _bookingChannel;

  @override
  void initState() {
    super.initState();
    _loadBooking();
    _subscribeToBookingUpdates();
  }

  @override
  void dispose() {
    _bookingChannel?.unsubscribe();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  /// Fetch the booking from the database.
  Future<void> _loadBooking() async {
    try {
      final data = await _supabase
          .from('bookings')
          .select()
          .eq('id', widget.bookingId)
          .single();

      setState(() {
        _booking = BookingModel.fromJson(data);
        _isLoading = false;
      });

      // If job is in progress, start the elapsed timer
      if (_booking!.status == 'in_progress' && _booking!.actualStart != null) {
        _startElapsedTimer();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Listen for real-time changes to this booking.
  void _subscribeToBookingUpdates() {
    _bookingChannel = _supabase
        .channel('booking_${widget.bookingId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.bookingId,
          ),
          callback: (payload) {
            // Booking was updated — reload it
            _loadBooking();
          },
        )
        .subscribe();
  }

  /// Starts a timer that ticks every second (for "job in progress" duration).
  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_booking?.actualStart != null) {
        setState(() {
          _elapsed = DateTime.now().difference(_booking!.actualStart!);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? const Center(child: Text('Booking not found'))
              : _buildBookingView(),
    );
  }

  Widget _buildBookingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ============================================
          // STATUS INDICATOR (animated circle + text)
          // ============================================
          _buildStatusHeader(),
          const SizedBox(height: 32),

          // ============================================
          // BOOKING DETAILS CARD
          // ============================================
          _buildDetailsCard(),
          const SizedBox(height: 24),

          // ============================================
          // ACTION BUTTONS (depends on status and role)
          // ============================================
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// The big status circle at the top.
  Widget _buildStatusHeader() {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (_booking!.status) {
      case 'pending':
        icon = Icons.hourglass_top;
        color = Colors.orange;
        title = widget.isPro ? 'New Booking Request!' : 'Waiting for Response';
        subtitle = widget.isPro
            ? 'A client wants to book you'
            : 'The pro has 2 minutes to accept';
        break;
      case 'accepted':
        icon = Icons.directions_walk;
        color = Colors.blue;
        title = widget.isPro ? 'Booking Accepted' : 'Pro is On the Way!';
        subtitle = widget.isPro
            ? 'Head to the client\'s location'
            : 'Your pro has accepted and is coming to you';
        break;
      case 'in_progress':
        icon = Icons.play_circle_filled;
        color = AppConstants.primaryColor;
        title = 'Job in Progress';
        subtitle = _formatDuration(_elapsed);
        break;
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        title = 'Job Completed!';
        subtitle =
            _booking!.durationMinutes != null
                ? 'Duration: ${_booking!.durationMinutes} minutes'
                : 'Service complete';
        break;
      case 'cancelled':
        icon = Icons.cancel;
        color = Colors.red;
        title = 'Booking Cancelled';
        subtitle = 'This booking has been cancelled';
        break;
      case 'disputed':
        icon = Icons.warning;
        color = Colors.orange;
        title = 'Under Review';
        subtitle = 'Our team is reviewing this booking';
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
        title = _booking!.status;
        subtitle = '';
    }

    return Column(
      children: [
        // Animated status circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 50, color: color),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Booking details card.
  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.location_on,
            label: 'Location',
            value: _booking!.serviceAddress,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.payments,
            label: 'Total',
            value: 'R${_booking!.totalAmount.toStringAsFixed(2)}',
          ),
          if (_booking!.clientNotes != null &&
              _booking!.clientNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.notes,
              label: 'Notes',
              value: _booking!.clientNotes!,
            ),
          ],
        ],
      ),
    );
  }

  /// Action buttons that change based on booking status and user role.
  Widget _buildActionButtons() {
    switch (_booking!.status) {
      // ============================================
      // PENDING — Pro can accept or decline
      // ============================================
      case 'pending':
        if (widget.isPro) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isActionLoading ? null : _acceptBooking,
                  icon: const Icon(Icons.check),
                  label: const Text('Accept Booking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isActionLoading ? null : _declineBooking,
                  icon: const Icon(Icons.close),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          );
        }
        // Client just waits
        return const LinearProgressIndicator();

      // ============================================
      // ACCEPTED — Pro can start the job
      // ============================================
      case 'accepted':
        if (widget.isPro) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isActionLoading ? null : _startJob,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('I\'ve Arrived — Start Job'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Only tap this when you\'ve arrived at the client\'s location.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }
        // Client sees "Chat with Pro" and "Cancel" buttons
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to chat
                },
                icon: const Icon(Icons.chat),
                label: const Text('Chat with Pro'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );

      // ============================================
      // IN PROGRESS — Pro can complete, Client can report
      // ============================================
      case 'in_progress':
        if (widget.isPro) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isActionLoading ? null : _completeJob,
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete Job'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          );
        }
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Report issue
                },
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Report Issue'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        );

      // ============================================
      // COMPLETED — Client can vouch
      // ============================================
      case 'completed':
        if (!widget.isPro) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VouchScreen(
                      bookingId: widget.bookingId,
                      proId: _booking!.proId,
                      proName: 'Your Pro', // Would come from joined data
                      serviceName: 'Service', // Would come from joined data
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.verified_user),
              label: const Text('Vouch for Your Pro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          );
        }
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================
  // ACTIONS
  // ============================================

  Future<void> _acceptBooking() async {
    setState(() => _isActionLoading = true);
    await _bookingService.acceptBooking(widget.bookingId);
    setState(() => _isActionLoading = false);
    await _loadBooking();
  }

  Future<void> _declineBooking() async {
    // Confirm first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Booking?'),
        content: const Text('The client will be notified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    await _bookingService.declineBooking(widget.bookingId);
    setState(() => _isActionLoading = false);

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _startJob() async {
    setState(() => _isActionLoading = true);
    await _bookingService.startJob(widget.bookingId);
    setState(() => _isActionLoading = false);
    await _loadBooking();
    _startElapsedTimer();
  }

  Future<void> _completeJob() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Job?'),
        content: const Text(
          'This will release the payment and prompt the client to vouch for you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not yet'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    _elapsedTimer?.cancel();
    await _bookingService.completeJob(widget.bookingId);
    setState(() => _isActionLoading = false);
    await _loadBooking();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s elapsed';
    }
    return '${minutes}m ${seconds}s elapsed';
  }
}

/// A detail row with icon, label, and value.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ],
    );
  }
}
