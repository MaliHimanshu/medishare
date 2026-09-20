import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/chat_user_model.dart';

class ChatService {
  final Dio _dio = DioClient.instance;

  Future<List<ChatConversation>> getConversations() async {
    final response = await _dio.get('${ApiEndpoints.baseUrl}/chat/conversations');
    if (response.data['success'] == true) {
      return (response.data['data'] as List)
          .map((json) => ChatConversation.fromJson(json))
          .toList();
    }
    throw Exception(response.data['message']);
  }

  Future<ChatConversation> getOrCreateConversation(String targetUserId) async {
    final response = await _dio.post(
      '${ApiEndpoints.baseUrl}/chat/conversations',
      data: {'userId': targetUserId},
    );
    if (response.data['success'] == true) {
      return ChatConversation.fromJson(response.data['data']);
    }
    throw Exception(response.data['message']);
  }

  Future<List<ChatMessage>> getMessages(String conversationId, {String? cursor}) async {
    final response = await _dio.get(
      '${ApiEndpoints.baseUrl}/chat/conversations/$conversationId/messages',
      queryParameters: {
        ?'cursor': cursor,
        'limit': 50,
      },
    );
    if (response.data['success'] == true) {
      return (response.data['data'] as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    }
    throw Exception(response.data['message']);
  }

  Future<ChatMessage> sendMessage(String conversationId, String content) async {
    final response = await _dio.post(
      '${ApiEndpoints.baseUrl}/chat/conversations/$conversationId/messages',
      data: {
        'content': content,
        'messageType': 'TEXT',
      },
    );
    if (response.data['success'] == true) {
      return ChatMessage.fromJson(response.data['data']);
    }
    throw Exception(response.data['message']);
  }

  Future<void> markAsRead(String conversationId) async {
    await _dio.patch('${ApiEndpoints.baseUrl}/chat/conversations/$conversationId/read');
  }

  Future<List<ChatUser>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    
    final response = await _dio.get(
      '${ApiEndpoints.baseUrl}/chat/users/search',
      queryParameters: {'q': query},
    );
    
    if (response.data['success'] == true) {
      return (response.data['data'] as List)
          .map((json) => ChatUser.fromJson(json))
          .toList();
    }
    throw Exception(response.data['message']);
  }
}
