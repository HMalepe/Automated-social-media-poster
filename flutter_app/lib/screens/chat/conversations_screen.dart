// ============================================
// Conversations List Screen
// ============================================
//
// Shows all active conversations in the "Chat" tab.
// Each row shows: other person's name/photo, last message preview,
// time, and unread badge.
//
// Tapping a conversation opens the ChatScreen.
// ============================================

import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatService _chatService = ChatService();
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final conversations = await _chatService.getConversations();
    setState(() {
      _conversations = conversations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No Conversations', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'When you book a pro (or get booked),\na chat will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _ConversationTile(
            conversation: conversation,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    conversationId: conversation.id,
                    otherPersonName: conversation.otherPersonName ?? 'Unknown',
                    otherPersonPhoto: conversation.otherPersonPhoto,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: conversation.otherPersonPhoto != null
            ? NetworkImage(conversation.otherPersonPhoto!)
            : null,
        child: conversation.otherPersonPhoto == null
            ? Text(
                (conversation.otherPersonName ?? '?')[0].toUpperCase(),
                style: const TextStyle(fontSize: 18),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.otherPersonName ?? 'Unknown',
              style: TextStyle(
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          if (conversation.lastMessageTime != null)
            Text(
              _formatTime(conversation.lastMessageTime!),
              style: TextStyle(
                fontSize: 12,
                color: conversation.unreadCount > 0
                    ? AppConstants.primaryColor
                    : Colors.grey[500],
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessage ?? 'No messages yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: conversation.unreadCount > 0
                    ? Colors.black87
                    : Colors.grey[500],
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          ),
          // Unread badge
          if (conversation.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.day}/${time.month}';
  }
}
