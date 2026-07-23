import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/chat_message_model.dart';
import '../core/constants/app_translations.dart';

class ChatbotProvider extends ChangeNotifier {
  final Dio _dio = DioClient.instance;

  final List<ChatMessageModel> _messages = [];
  bool _isTyping = false;
  String _errorMessage = '';

  List<ChatMessageModel> get messages => _messages;
  bool get isTyping => _isTyping;
  String get errorMessage => _errorMessage;

  ChatbotProvider() {
    _initWelcomeMessage('English');
  }

  void _initWelcomeMessage([String lang = 'English']) {
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessageModel(
          id: 'welcome_msg',
          text: AppTranslations.getText(lang, 'welcome_ai'),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Update welcome message when language changes
  void updateLanguage(String lang) {
    if (_messages.isNotEmpty && _messages.first.id == 'welcome_msg') {
      _messages[0] = ChatMessageModel(
        id: 'welcome_msg',
        text: AppTranslations.getText(lang, 'welcome_ai'),
        isUser: false,
        timestamp: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // ── Send User Message to Backend (POST /api/chatbot) ────────────────
  Future<bool> sendMessage(String text, {String lang = 'English'}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return false;

    _errorMessage = '';

    // Add User Message
    final userMsg = ChatMessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);
    _isTyping = true;
    notifyListeners();

    try {
      // Append language instruction if not English
      final promptText = (lang != 'English') ? "[Respond in $lang] $trimmed" : trimmed;
      final payload = {'message': promptText};
      final response = await _dio.post(ApiEndpoints.chatbot, data: payload);

      if (response.data != null && response.data['success'] == true) {
        final aiReplyText = response.data['response']?.toString() ??
            "Thank you for your message! How else can I assist you with MediShare?";

        final aiMsg = ChatMessageModel(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: aiReplyText,
          isUser: false,
          timestamp: DateTime.now(),
        );

        _messages.add(aiMsg);
        _isTyping = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.data?['message'] ?? 'Failed to receive AI response.';
        _addErrorMessage(_errorMessage);
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
      _addErrorMessage(_errorMessage);
      return false;
    } catch (e) {
      _errorMessage = 'Unable to connect to AI server: $e';
      _addErrorMessage(_errorMessage);
      return false;
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  void _addErrorMessage(String errorText) {
    _messages.add(
      ChatMessageModel(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        text: '⚠️ $errorText',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ),
    );
  }

  // ── Retry Last User Message ─────────────────────────────────────────
  Future<bool> retryLastMessage({String lang = 'English'}) async {
    final lastUserMsg = _messages.lastWhere(
      (m) => m.isUser,
      orElse: () => throw Exception('No user message to retry'),
    );
    return sendMessage(lastUserMsg.text, lang: lang);
  }

  // ── Clear Conversation ──────────────────────────────────────────────
  void clearChat([String lang = 'English']) {
    _messages.clear();
    _errorMessage = '';
    _isTyping = false;
    _initWelcomeMessage(lang);
    notifyListeners();
  }
}
