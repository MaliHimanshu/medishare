import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_user_model.dart';
import '../../models/message_model.dart';

class PrivateChatScreen extends StatefulWidget {
  final String conversationId;
  final ChatUser? otherUser;

  const PrivateChatScreen({
    super.key,
    required this.conversationId,
    this.otherUser,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadMessages(widget.conversationId);
    });
  }

  @override
  void dispose() {
    // Notify provider we left
    final prov = context.read<ChatProvider>();
    prov.setTyping(widget.conversationId, false);
    prov.leaveConversation(widget.conversationId);
    
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    
    final prov = context.read<ChatProvider>();
    prov.sendMessage(widget.conversationId, _msgController.text.trim());
    
    _msgController.clear();
    prov.setTyping(widget.conversationId, false);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF172033)),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFCCFBF1),
              backgroundImage: widget.otherUser?.profileImage != null ? NetworkImage(widget.otherUser!.profileImage!) : null,
              child: widget.otherUser?.profileImage == null 
                  ? Text(widget.otherUser?.name[0].toUpperCase() ?? 'U', style: const TextStyle(color: Color(0xFF14B8A6), fontWeight: FontWeight.bold, fontSize: 14))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser?.name ?? 'Unknown User',
                    style: const TextStyle(color: Color(0xFF172033), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Consumer<ChatProvider>(
                    builder: (context, prov, child) {
                      final isTyping = prov.isTyping(widget.conversationId);
                      if (isTyping) {
                        return const Text('typing...', style: TextStyle(color: Color(0xFF2563EB), fontSize: 12));
                      }
                      return const SizedBox.shrink();
                    }
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, prov, child) {
                final messages = prov.getMessages(widget.conversationId);
                
                if (messages.isEmpty) {
                  return const Center(child: Text("No messages yet", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == prov.currentUserId;
                    
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
          ),
          border: isMe ? null : Border.all(color: Colors.grey.shade200),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF172033),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all : Icons.check,
                    size: 14,
                    color: msg.isRead ? const Color(0xFF14B8A6) : Colors.white70,
                  )
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Color(0xFF64748B)),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _msgController,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (text) {
                    context.read<ChatProvider>().setTyping(widget.conversationId, text.isNotEmpty);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF2563EB),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
