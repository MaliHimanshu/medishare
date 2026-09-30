import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import 'find_users_screen.dart';
import 'private_chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        final chat = context.read<ChatProvider>();
        chat.init(auth.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF172033),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF172033)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FindUsersScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProv, child) {
          if (chatProv.isLoading && chatProv.conversations.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            );
          }

          if (chatProv.conversations.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => chatProv.loadConversations(),
            child: ListView.separated(
              itemCount: chatProv.conversations.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Colors.black12),
              itemBuilder: (context, index) {
                final conv = chatProv.conversations[index];
                final otherUser = conv.getOtherUser(
                  chatProv.currentUserId ?? '',
                );
                final unreadCount = conv.getUnreadCount(
                  chatProv.currentUserId ?? '',
                );
                final lastMessage = conv.messages.isNotEmpty
                    ? conv.messages.first.content
                    : 'Started a conversation';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFCCFBF1),
                    backgroundImage: otherUser?.profileImage != null
                        ? NetworkImage(otherUser!.profileImage!)
                        : null,
                    child: otherUser?.profileImage == null
                        ? Text(
                            otherUser?.name[0].toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Color(0xFF14B8A6),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    otherUser?.name ?? 'Unknown User',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF172033),
                    ),
                  ),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0
                          ? const Color(0xFF172033)
                          : const Color(0xFF64748B),
                      fontWeight: unreadCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: unreadCount > 0
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF2563EB),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrivateChatScreen(
                          conversationId: conv.id,
                          otherUser: otherUser,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.message, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FindUsersScreen()),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a conversation with a MediShare user',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
