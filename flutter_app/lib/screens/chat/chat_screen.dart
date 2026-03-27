// ============================================
// Chat Screen - Real-Time Messaging
// ============================================
//
// WHAT IS THIS?
// A real-time chat screen between a client and a pro.
// Messages appear in real-time (no refresh needed).
//
// DESIGN:
// - Messages you sent appear on the RIGHT (green bubbles)
// - Messages from the other person appear on the LEFT (grey bubbles)
// - Text input at the bottom with a send button
// - Newest messages at the bottom (list scrolls up for history)
//
// REAL-TIME:
// When the other person sends a message, it appears instantly
// because we subscribe to the Supabase Realtime channel for
// this conversation's messages table.
// ============================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherPersonName;
  final String? otherPersonPhoto;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherPersonName,
    this.otherPersonPhoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  // Real-time subscription
  RealtimeChannel? _messageChannel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToNewMessages();
  }

  @override
  void dispose() {
    _messageChannel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load existing messages from the database.
  Future<void> _loadMessages() async {
    final messages = await _chatService.getMessages(widget.conversationId);

    setState(() {
      _messages = messages;
      _isLoading = false;
    });

    // Mark messages from the other person as read
    _chatService.markAsRead(widget.conversationId);
  }

  /// Subscribe to real-time new messages.
  void _subscribeToNewMessages() {
    _messageChannel = _chatService.subscribeToMessages(
      widget.conversationId,
      (ChatMessage newMessage) {
        // A new message arrived! Add it to the top of our list
        // (list is reversed, so "top" = newest = bottom of screen)
        setState(() {
          _messages.insert(0, newMessage);
        });

        // Mark as read if it's not from us
        if (!newMessage.isMe) {
          _chatService.markAsRead(widget.conversationId);
        }

        // Scroll to the bottom to show the new message
        _scrollToBottom();
      },
    );
  }

  /// Send a message.
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() => _isSending = true);

    final success = await _chatService.sendMessage(
      conversationId: widget.conversationId,
      messageText: text,
    );

    setState(() => _isSending = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
      // Put the text back so they don't lose it
      _messageController.text = text;
    }
  }

  /// Scroll to the bottom (newest message).
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // 0 because list is reversed
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ============================================
      // APP BAR with other person's name
      // ============================================
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.otherPersonPhoto != null
                  ? NetworkImage(widget.otherPersonPhoto!)
                  : null,
              child: widget.otherPersonPhoto == null
                  ? Text(
                      widget.otherPersonName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(widget.otherPersonName),
          ],
        ),
        actions: const [],
      ),

      body: Column(
        children: [
          // ============================================
          // MESSAGE LIST
          // ============================================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        // REVERSED: newest messages at the bottom
                        reverse: true,
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          // Check if we need a date separator
                          final showDate = index == _messages.length - 1 ||
                              !_isSameDay(
                                message.createdAt,
                                _messages[index + 1].createdAt,
                              );

                          return Column(
                            children: [
                              if (showDate)
                                _buildDateSeparator(message.createdAt),
                              _MessageBubble(message: message),
                            ],
                          );
                        },
                      ),
          ),

          // ============================================
          // MESSAGE INPUT BAR
          // ============================================
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      // Send on Enter (desktop/web)
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  Container(
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state when there are no messages yet.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No messages yet',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Say hello to ${widget.otherPersonName}!',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Date separator between messages from different days.
  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDateHeader(date),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ============================================
// Message Bubble Widget
// ============================================
// A single message bubble. Green and right-aligned for "me",
// grey and left-aligned for the other person.

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      // My messages on the right, theirs on the left
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          // Messages take up at most 75% of the screen width
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isMe
              ? AppConstants.primaryColor
              : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            // Pointy corner on the sender's side
            bottomLeft: Radius.circular(message.isMe ? 16 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Message text
            Text(
              message.messageText,
              style: TextStyle(
                color: message.isMe ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            // Timestamp
            Text(
              '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: message.isMe
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
