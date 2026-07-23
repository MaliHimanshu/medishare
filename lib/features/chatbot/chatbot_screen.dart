import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_translations.dart';
import '../../models/chat_message_model.dart';
import '../../providers/chatbot_provider.dart';
import '../../providers/theme_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = context.read<ThemeProvider>().selectedLanguage;
      context.read<ChatbotProvider>().updateLanguage(lang);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(String lang, [String? customText]) {
    final text = customText ?? _messageController.text;
    if (text.trim().isEmpty) return;

    _messageController.clear();
    final provider = context.read<ChatbotProvider>();
    provider.sendMessage(text, lang: lang).then((success) {
      _scrollToBottom();
      if (!success && mounted && provider.errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    _scrollToBottom();
  }

  void _confirmClearChat(String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.cleaning_services_outlined, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(AppTranslations.getText(lang, 'clear_chat'), style: TextStyle(color: context.textPrimaryColor)),
          ],
        ),
        content: Text(
          AppTranslations.getText(lang, 'clear_chat_desc'),
          style: TextStyle(color: context.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTranslations.getText(lang, 'cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ChatbotProvider>().clearChat(lang);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppTranslations.getText(lang, 'chat_cleared')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showOptionsModal(ChatMessageModel message, String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_outlined, color: AppColors.primary),
              title: Text(AppTranslations.getText(lang, 'copy_msg'), style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppTranslations.getText(lang, 'msg_copied')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final lang = themeProv.selectedLanguage;

    final provider = context.watch<ChatbotProvider>();
    final messages = provider.messages;
    final isTyping = provider.isTyping;

    final suggestions = [
      {'label': AppTranslations.getText(lang, 'chip_wheelchair_label'), 'query': AppTranslations.getText(lang, 'chip_wheelchair_query')},
      {'label': AppTranslations.getText(lang, 'chip_equip_label'), 'query': AppTranslations.getText(lang, 'chip_equip_query')},
      {'label': AppTranslations.getText(lang, 'chip_hosp_label'), 'query': AppTranslations.getText(lang, 'chip_hosp_query')},
      {'label': AppTranslations.getText(lang, 'chip_donate_label'), 'query': AppTranslations.getText(lang, 'chip_donate_query')},
      {'label': AppTranslations.getText(lang, 'chip_req_label'), 'query': AppTranslations.getText(lang, 'chip_req_query')},
      {'label': AppTranslations.getText(lang, 'chip_guide_label'), 'query': AppTranslations.getText(lang, 'chip_guide_query')},
    ];

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withAlpha(20),
              child: const Icon(Icons.smart_toy_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              AppTranslations.getText(lang, 'ai_assistant_title'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: context.textPrimaryColor),
            ),
          ],
        ),
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.grey),
            tooltip: 'Clear Conversation',
            onPressed: () => _confirmClearChat(lang),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isTyping) {
                  return _buildTypingIndicator(lang);
                }

                final item = messages[index];
                return _buildMessageBubble(item, lang);
              },
            ),
          ),

          // Quick Suggestion Chips Row
          Container(
            color: context.surfaceBg,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: suggestions.map((sug) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                      label: Text(
                        sug['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      backgroundColor: context.cardBg,
                      side: BorderSide(color: context.borderColor),
                      onPressed: isTyping ? null : () => _handleSend(lang, sug['query']),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Bottom Input Field
          SafeArea(
            child: Container(
              color: context.surfaceBg,
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !isTyping,
                      style: TextStyle(color: context.textPrimaryColor),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: isTyping
                            ? AppTranslations.getText(lang, 'ai_thinking')
                            : AppTranslations.getText(lang, 'ask_ai'),
                        hintStyle: TextStyle(color: context.textHintColor),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        filled: true,
                        fillColor: context.inputBg,
                      ),
                      onSubmitted: (val) => _handleSend(lang),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isTyping ? Colors.grey.shade400 : AppColors.primary,
                    child: IconButton(
                      icon: isTyping
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: isTyping ? null : () => _handleSend(lang),
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

  Widget _buildMessageBubble(ChatMessageModel item, String lang) {
    final isUser = item.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: item.isError ? Colors.red.shade100 : AppColors.primary.withAlpha(25),
              child: Icon(
                item.isError ? Icons.warning_amber : Icons.smart_toy,
                color: item.isError ? Colors.red : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showOptionsModal(item, lang),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isUser ? AppColors.primaryGradient : null,
                  color: isUser
                      ? null
                      : (item.isError ? Colors.red.shade900.withAlpha(40) : context.cardBg),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: isUser
                      ? null
                      : Border.all(
                          color: item.isError ? Colors.red.shade300 : context.borderColor,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(context.isDarkMode ? 30 : 8),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.text,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: isUser
                            ? Colors.white
                            : (item.isError ? Colors.red : context.textPrimaryColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(item.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser ? Colors.white70 : context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(String lang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withAlpha(25),
            child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  AppTranslations.getText(lang, 'ai_thinking'),
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}