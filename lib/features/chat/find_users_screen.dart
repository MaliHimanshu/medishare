import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_user_model.dart';
import '../../services/chat_service.dart';
import '../../core/constants/app_colors.dart';
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
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  void _search(String query) async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final results = await _chatService.searchUsers(query);
      if (mounted) {
        setState(() => _users = results);
      }
    } catch (e) {
      debugPrint("Search error: $e");
      if (mounted) {
        setState(() => _errorMsg = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startChat(ChatUser user) async {
    try {
      final chatProv = context.read<ChatProvider>();
      final conv = await chatProv.getOrCreateConversation(user.id);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PrivateChatScreen(conversationId: conv.id, otherUser: user),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start chat: $e')));
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.purple;
      case 'DONOR':
        return Colors.green;
      case 'NGO':
        return Colors.teal;
      case 'HOSPITAL':
        return const Color(0xFF7C3AED);
      case 'RECIPIENT':
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'User Management & Directory',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: context.surfaceBg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimaryColor),
      ),
      body: Column(
        children: [
          Container(
            color: context.surfaceBg,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _search,
              style: TextStyle(color: context.textPrimaryColor),
              decoration: InputDecoration(
                hintText: 'Search by name, email, phone or role...',
                hintStyle: TextStyle(color: context.textSecondaryColor),
                prefixIcon: Icon(
                  Icons.search,
                  color: context.textSecondaryColor,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: context.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _errorMsg != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 44),
                          const SizedBox(height: 12),
                          Text(
                            _errorMsg!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.textSecondaryColor),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _search(_searchCtrl.text),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: context.textSecondaryColor),
                        const SizedBox(height: 12),
                        Text(
                          _searchCtrl.text.isEmpty
                              ? 'No registered users found'
                              : 'No users match "${_searchCtrl.text}"',
                          style: TextStyle(color: context.textSecondaryColor),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _search(_searchCtrl.text),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _users.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: context.borderColor),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final roleColor = _getRoleColor(user.role);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: roleColor.withAlpha(30),
                            backgroundImage: user.profileImage != null
                                ? NetworkImage(user.profileImage!)
                                : null,
                            child: user.profileImage == null
                                ? Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      color: roleColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: context.textPrimaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: roleColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: roleColor.withAlpha(80),
                                  ),
                                ),
                                child: Text(
                                  user.role.toUpperCase(),
                                  style: TextStyle(
                                    color: roleColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                              if (user.phone != null && user.phone!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '📞 ${user.phone}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Contact User',
                            onPressed: () => _startChat(user),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
