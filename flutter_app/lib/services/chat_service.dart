// ============================================
// Chat Service - Real-Time Messaging
// ============================================
//
// HOW CHAT WORKS IN VOUCHSA:
// 1. A conversation is created automatically when a booking is made
// 2. Only the client and pro in that booking can see the messages
// 3. Messages are text-only (no photos, for safety)
// 4. The conversation auto-expires 48 hours after job completion
// 5. Messages arrive in real-time using Supabase Realtime
//
// WHAT IS A STREAM?
// A Stream is like a pipe that data flows through continuously.
// Instead of asking "any new messages?" every second (polling),
// a Stream says "I'll tell you whenever a new message arrives."
// Much more efficient and instant.
// ============================================

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A single chat message.
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String messageText;
  final bool isRead;
  final DateTime createdAt;
  // Set locally based on who's viewing
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageText,
    required this.isRead,
    required this.createdAt,
    required this.isMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      messageText: json['message_text'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      isMe: json['sender_id'] == currentUserId,
    );
  }
}

/// A conversation (linked to a booking).
class Conversation {
  final String id;
  final String bookingId;
  final String clientId;
  final String proId;
  final bool isActive;
  final DateTime? expiresAt;
  // Joined data
  final String? otherPersonName;
  final String? otherPersonPhoto;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.proId,
    required this.isActive,
    this.expiresAt,
    this.otherPersonName,
    this.otherPersonPhoto,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });
}

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser!.id;

  // ============================================
  // GET ALL CONVERSATIONS
  // ============================================
  // Returns a list of active conversations for the current user.
  // Used in the "Chat" tab to show the conversation list.

  Future<List<Conversation>> getConversations() async {
    try {
      final data = await _supabase
          .from('conversations')
          .select('''
            id,
            booking_id,
            client_id,
            pro_id,
            is_active,
            expires_at
          ''')
          .or('client_id.eq.$_currentUserId,pro_id.eq.$_currentUserId')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final List<Conversation> conversations = [];

      for (final row in data) {
        // Figure out who the "other person" is
        final isClient = row['client_id'] == _currentUserId;
        final otherUserId = isClient ? row['pro_id'] : row['client_id'];

        // Get the other person's name
        final profileData = await _supabase
            .from('profiles')
            .select('display_name, profile_photo_url')
            .eq('user_id', otherUserId)
            .maybeSingle();

        // Get the last message and unread count
        final lastMsg = await _supabase
            .from('messages')
            .select('message_text, created_at')
            .eq('conversation_id', row['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        final unreadData = await _supabase
            .from('messages')
            .select('id')
            .eq('conversation_id', row['id'])
            .neq('sender_id', _currentUserId)
            .eq('is_read', false);

        conversations.add(Conversation(
          id: row['id'],
          bookingId: row['booking_id'],
          clientId: row['client_id'],
          proId: row['pro_id'],
          isActive: row['is_active'] ?? true,
          expiresAt: row['expires_at'] != null
              ? DateTime.parse(row['expires_at'])
              : null,
          otherPersonName: profileData?['display_name'] ?? 'Unknown',
          otherPersonPhoto: profileData?['profile_photo_url'],
          lastMessage: lastMsg?['message_text'],
          lastMessageTime: lastMsg != null
              ? DateTime.parse(lastMsg['created_at'])
              : null,
          unreadCount: (unreadData as List).length,
        ));
      }

      return conversations;
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // GET MESSAGES FOR A CONVERSATION
  // ============================================
  // Returns the message history for a specific conversation.
  // Most recent messages first (for reverse-scrolling list).

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final data = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(100);

      return (data as List<dynamic>)
          .map((json) => ChatMessage.fromJson(json, _currentUserId))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // SEND A MESSAGE
  // ============================================
  // Inserts a new message into the messages table.
  // The real-time subscription will automatically notify the other person.

  Future<bool> sendMessage({
    required String conversationId,
    required String messageText,
  }) async {
    try {
      await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': _currentUserId,
        'message_text': messageText,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // MARK MESSAGES AS READ
  // ============================================
  // Called when the user opens a conversation.
  // Marks all messages from the OTHER person as read.

  Future<void> markAsRead(String conversationId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', _currentUserId)
          .eq('is_read', false);
    } catch (e) {
      // Non-critical, silently fail
    }
  }

  // ============================================
  // SUBSCRIBE TO NEW MESSAGES (Real-Time)
  // ============================================
  // Returns a Supabase RealtimeChannel that fires whenever
  // a new message is inserted into this conversation.
  //
  // The chat screen listens to this and adds new messages
  // to the list instantly — no refresh needed.

  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(ChatMessage message) onNewMessage,
  ) {
    return _supabase
        .channel('messages_$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final newMessage = ChatMessage.fromJson(
              payload.newRecord,
              _currentUserId,
            );
            onNewMessage(newMessage);
          },
        )
        .subscribe();
  }

  // ============================================
  // GET CONVERSATION FOR A BOOKING
  // ============================================
  // Finds the conversation linked to a specific booking.

  Future<String?> getConversationIdForBooking(String bookingId) async {
    try {
      final data = await _supabase
          .from('conversations')
          .select('id')
          .eq('booking_id', bookingId)
          .maybeSingle();
      return data?['id'];
    } catch (e) {
      return null;
    }
  }
}
