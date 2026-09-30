import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../models/chat_message_model.dart';
import '../../providers/menu_chatbot_provider.dart';
import 'chatbot_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openConversation(ChatConversationModel conv) {
    if (conv.isSupport) {
      context.read<MenuChatbotProvider>().markSupportAsRead();
      Navigator.push(
        context,
        AppPageTransitions.slideRight(const ChatbotScreen()),
      );
    } else {
      // General desk info modal
      showModalBottomSheet(
        context: context,
        backgroundColor: context.surfaceBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withAlpha(25),
                child: Icon(
                  conv.id == 'hospital_help'
                      ? Icons.local_hospital_outlined
                      : Icons.volunteer_activism_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                conv.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                conv.lastMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<MenuChatbotProvider>().markSupportAsRead();
                    Navigator.push(
                      context,
                      AppPageTransitions.slideRight(const ChatbotScreen()),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text(
                    "Chat with MediShare Support",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showNewChatDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Start a Conversation",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Choose an official channel to connect with:",
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: AppColors.primary.withAlpha(12),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  "MediShare In-App Support",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                subtitle: const Text(
                  "Equipment, hospitals, rentals & payments",
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<MenuChatbotProvider>().markSupportAsRead();
                  Navigator.push(
                    context,
                    AppPageTransitions.slideRight(const ChatbotScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);
    if (difference.inMinutes < 60) {
      return "${difference.inMinutes == 0 ? 1 : difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else {
      return "${dt.day}/${dt.month}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<MenuChatbotProvider>();
    final conversations = chatProvider.filteredConversations;
    final currentFilter = chatProvider.activeFilter;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        title: Text(
          "MediShare Chat",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: context.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text(
          "New Chat",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _showNewChatDialog,
      ),
      body: Column(
        children: [
          // ── Search Conversations Bar ──────────────────────────────
          Container(
            color: context.surfaceBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: context.textPrimaryColor),
              onChanged: (val) => chatProvider.setConversationSearchQuery(val),
              decoration: InputDecoration(
                hintText: "Search conversations...",
                hintStyle: TextStyle(
                  color: context.textHintColor,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.primary,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          chatProvider.setConversationSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: context.inputBg,
              ),
            ),
          ),

          // ── All / Unread Filter Chips ─────────────────────────────
          Container(
            width: double.infinity,
            color: context.surfaceBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip(
                  label: "All",
                  isSelected: currentFilter == ChatFilter.all,
                  onTap: () => chatProvider.setFilter(ChatFilter.all),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: "Unread",
                  isSelected: currentFilter == ChatFilter.unread,
                  onTap: () => chatProvider.setFilter(ChatFilter.unread),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Conversation List ─────────────────────────────────────
          Expanded(
            child: conversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 56,
                          color: context.textSecondaryColor.withAlpha(100),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No conversations found",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: conversations.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      indent: 76,
                      color: context.borderColor.withAlpha(60),
                    ),
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      return _buildConversationTile(conv);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(ChatConversationModel conv) {
    return InkWell(
      onTap: () => _openConversation(conv),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with Online indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: conv.isSupport
                      ? AppColors.primary
                      : AppColors.accent.withAlpha(30),
                  child: Icon(
                    conv.isSupport
                        ? Icons.support_agent_rounded
                        : (conv.id == 'hospital_help'
                              ? Icons.local_hospital_outlined
                              : Icons.volunteer_activism_outlined),
                    color: conv.isSupport ? Colors.white : AppColors.accentDark,
                    size: 26,
                  ),
                ),
                if (conv.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981), // Emerald green
                        shape: BoxShape.circle,
                        border: Border.all(color: context.surfaceBg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                conv.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (conv.isSupport) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        _formatDate(conv.lastTimestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: conv.unreadCount > 0
                              ? AppColors.primary
                              : context.textSecondaryColor,
                          fontWeight: conv.unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: conv.unreadCount > 0
                                ? context.textPrimaryColor
                                : context.textSecondaryColor,
                            fontWeight: conv.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (conv.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${conv.unreadCount}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
