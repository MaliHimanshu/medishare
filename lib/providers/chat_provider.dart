import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/chat_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../core/network/api_endpoints.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  io.Socket? _socket;
  
  List<ChatConversation> _conversations = [];
  bool _isLoading = false;
  String? _error;
  
  List<ChatConversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? currentUserId;

  // Real-time events
  final Map<String, List<ChatMessage>> _activeChatMessages = {};
  final Map<String, bool> _typingStatus = {};

  List<ChatMessage> getMessages(String conversationId) => 
      _activeChatMessages[conversationId] ?? [];
      
  bool isTyping(String conversationId) => 
      _typingStatus[conversationId] ?? false;

  void init(String userId) {
    currentUserId = userId;
    _initSocket();
    loadConversations();
  }

  Future<void> _initSocket() async {
    String? token = await _storage.read(key: 'auth_token');
    token ??= await _storage.read(key: 'medishare_token');
    if (token == null) return;

    // Connect to WebSocket server using the base URL
    final serverUrl = ApiEndpoints.baseUrl.replaceAll('/api', '');

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      debugPrint('Chat Socket Connected');
    });

    _socket?.on('message:new', (data) {
      final message = ChatMessage.fromJson(data);
      
      // Add to active chat if open
      if (_activeChatMessages.containsKey(message.conversationId)) {
        // Insert at beginning because we show list reversed
        _activeChatMessages[message.conversationId]!.insert(0, message);
        
        // Auto mark as read if it's the active screen
        _chatService.markAsRead(message.conversationId);
      }
      
      // Update conversations list summary
      _updateConversationSummary(message);
      
      notifyListeners();
    });

    _socket?.on('typing:start', (data) {
      _typingStatus[data['conversationId']] = true;
      notifyListeners();
    });

    _socket?.on('typing:stop', (data) {
      _typingStatus[data['conversationId']] = false;
      notifyListeners();
    });
  }

  void _updateConversationSummary(ChatMessage message) {
    final idx = _conversations.indexWhere((c) => c.id == message.conversationId);
    if (idx != -1) {
      final conv = _conversations[idx];
      // Quick deep copy to update messages
      final updatedConv = ChatConversation(
        id: conv.id,
        createdAt: conv.createdAt,
        updatedAt: message.createdAt,
        participants: conv.participants,
        messages: [message],
      );
      _conversations.removeAt(idx);
      _conversations.insert(0, updatedConv);
    } else {
      // Reload if it's a new conversation not in our list
      loadConversations();
    }
  }

  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _chatService.getConversations();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMessages(String conversationId) async {
    try {
      final msgs = await _chatService.getMessages(conversationId);
      _activeChatMessages[conversationId] = msgs;
      
      // Join socket room
      _socket?.emit('conversation:join', conversationId);
      
      // Mark as read
      await _chatService.markAsRead(conversationId);
      
      notifyListeners();
    } catch (e) {
      debugPrint("Load messages error: $e");
    }
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('conversation:leave', conversationId);
    _activeChatMessages.remove(conversationId);
  }

  Future<void> sendMessage(String conversationId, String content) async {
    try {
      final message = await _chatService.sendMessage(conversationId, content);
      
      if (_activeChatMessages.containsKey(conversationId)) {
        _activeChatMessages[conversationId]!.insert(0, message);
      }
      
      _updateConversationSummary(message);
      notifyListeners();
    } catch (e) {
      debugPrint("Send message error: $e");
    }
  }

  void setTyping(String conversationId, bool isTyping) {
    if (isTyping) {
      _socket?.emit('typing:start', {'conversationId': conversationId});
    } else {
      _socket?.emit('typing:stop', {'conversationId': conversationId});
    }
  }

  Future<ChatConversation> getOrCreateConversation(String targetUserId) async {
    final conv = await _chatService.getOrCreateConversation(targetUserId);
    
    // Add to list if not already there
    final exists = _conversations.any((c) => c.id == conv.id);
    if (!exists) {
      _conversations.insert(0, conv);
      notifyListeners();
    }
    
    return conv;
  }

  @override
  void dispose() {
    _socket?.disconnect();
    super.dispose();
  }
}
