import 'chat_user_model.dart';
import 'message_model.dart';

class ConversationParticipant {
  final String id;
  final String conversationId;
  final String userId;
  final DateTime joinedAt;
  final DateTime lastReadAt;
  final ChatUser? user;

  ConversationParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.joinedAt,
    required this.lastReadAt,
    this.user,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      userId: json['userId'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      lastReadAt: DateTime.parse(json['lastReadAt'] as String),
      user: json['user'] != null
          ? ChatUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ChatConversation {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ConversationParticipant> participants;
  final List<ChatMessage> messages;

  ChatConversation({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.participants = const [],
    this.messages = const [],
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    var pList = json['participants'] as List? ?? [];
    var mList = json['messages'] as List? ?? [];

    return ChatConversation(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      participants: pList
          .map((i) => ConversationParticipant.fromJson(i as Map<String, dynamic>))
          .toList(),
      messages: mList
          .map((i) => ChatMessage.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  // Helper to get the other participant in a 1-on-1 chat
  ChatUser? getOtherUser(String currentUserId) {
    try {
      return participants
          .firstWhere((p) => p.userId != currentUserId)
          .user;
    } catch (_) {
      return null;
    }
  }

  // Helper to get unread count
  int getUnreadCount(String currentUserId) {
    try {
      final me = participants.firstWhere((p) => p.userId == currentUserId);
      return messages.where((m) => 
        m.senderId != currentUserId && 
        m.createdAt.isAfter(me.lastReadAt)
      ).length;
    } catch (_) {
      return 0;
    }
  }
}
