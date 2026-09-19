import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_user_model.dart';
import '../../services/chat_service.dart';
import 'private_chat_screen.dart';

class FindUsersScreen extends StatefulWidget {
  const FindUsersScreen({super.key});

  @override
  State<FindUsersScreen> createState() => _FindUsersScreenState();
}

class _FindUsersScreenState extends State<FindUsersScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchCtrl = TextEditingController();
  
  List<ChatUser> _users = [];
  bool _isLoading = false;

  void _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _users = []);
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final results = await _chatService.searchUsers(query);
      setState(() => _users = results);
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startChat(ChatUser user) async {
    try {
      final chatProv = context.read<ChatProvider>();
      final conv = await chatProv.getOrCreateConversation(user.id);
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(
          builder: (_) => PrivateChatScreen(
            conversationId: conv.id,
            otherUser: user,
          )
        )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start chat: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text('New Message', style: TextStyle(color: Color(0xFF172033), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF172033)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFFF7FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
              : _users.isEmpty
                ? Center(
                    child: Text(
                      _searchCtrl.text.isEmpty 
                        ? 'Type to search users' 
                        : 'No users found',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.separated(
                    itemCount: _users.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFCCFBF1),
                          backgroundImage: user.profileImage != null ? NetworkImage(user.profileImage!) : null,
                          child: user.profileImage == null 
                            ? Text(user.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF14B8A6), fontWeight: FontWeight.bold))
                            : null,
                        ),
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(user.role),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () => _startChat(user),
                          child: const Text('Message', style: TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
