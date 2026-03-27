// ============================================
// Vouch Screen
// ============================================
//
// WHAT IS THIS?
// After a job is completed, the client sees this screen.
// It asks: "Would you vouch for [Pro Name]?"
//
// Three options:
// 1. "Yes, vouch!" — Public endorsement (good for the pro)
// 2. "Yes, with a comment" — Same, but with a written message
// 3. "Not this time" — Private, no negative consequence
//
// WHY IS THIS DIFFERENT FROM STAR RATINGS?
// Star ratings are complicated and subjective. "Was it 3 stars or 4?"
// A vouch is simple: "Would you let this person into your home again?"
// Yes or no. That's it. This simplicity IS the trust signal.
// ============================================

import 'package:flutter/material.dart';
import '../../services/booking_service.dart';
import '../../utils/constants.dart';

class VouchScreen extends StatefulWidget {
  final String bookingId;
  final String proId;
  final String proName;
  final String? proPhotoUrl;
  final String serviceName;

  const VouchScreen({
    super.key,
    required this.bookingId,
    required this.proId,
    required this.proName,
    this.proPhotoUrl,
    required this.serviceName,
  });

  @override
  State<VouchScreen> createState() => _VouchScreenState();
}

class _VouchScreenState extends State<VouchScreen> {
  final BookingService _bookingService = BookingService();
  final _commentController = TextEditingController();
  bool _showCommentField = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // ============================================
              // HEADER
              // ============================================
              // Pro's photo
              CircleAvatar(
                radius: 45,
                backgroundColor: AppConstants.primaryColor.withOpacity(0.2),
                backgroundImage: widget.proPhotoUrl != null
                    ? NetworkImage(widget.proPhotoUrl!)
                    : null,
                child: widget.proPhotoUrl == null
                    ? Text(
                        widget.proName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32),
                      )
                    : null,
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'How was your experience?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.serviceName} with ${widget.proName}',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ============================================
              // VOUCH QUESTION
              // ============================================
              Text(
                'Would you vouch for ${widget.proName}?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'A vouch tells others in your area: "I trust this person."',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ============================================
              // COMMENT FIELD (shown when "Yes, with comment")
              // ============================================
              if (_showCommentField) ...[
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  maxLength: 200,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText:
                        'What was great about ${widget.proName}\'s service?',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitVouch(_commentController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit Vouch'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _showCommentField = false),
                  child: const Text('Back'),
                ),
              ],

              // ============================================
              // THREE VOUCH OPTIONS
              // ============================================
              if (!_showCommentField) ...[
                // Option 1: Yes, vouch!
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _submitVouch(null),
                    icon: const Icon(Icons.thumb_up),
                    label: const Text('Yes, vouch!'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Option 2: Yes, with a comment
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() => _showCommentField = true),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Yes, with a comment'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Option 3: Not this time
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isSubmitting ? null : _skip,
                    child: Text(
                      'Not this time',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is private — it won\'t affect the pro negatively.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  /// Submit a vouch (with optional comment).
  Future<void> _submitVouch(String? comment) async {
    setState(() => _isSubmitting = true);

    final success = await _bookingService.createVouch(
      bookingId: widget.bookingId,
      proId: widget.proId,
      vouchText: comment,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      _showSuccessAndClose();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit vouch. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Skip vouching (no negative consequence).
  void _skip() {
    Navigator.of(context).pop();
  }

  /// Show a thank-you message and close.
  void _showSuccessAndClose() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user,
                size: 60, color: AppConstants.primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Thank you!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your vouch helps build trust in your community.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close vouch screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
