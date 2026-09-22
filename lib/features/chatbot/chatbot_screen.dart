import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../models/chat_message_model.dart';
import '../../models/equipment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/menu_chatbot_provider.dart';
import '../../providers/theme_provider.dart';
import '../../shared/widgets/ms_image.dart';

// Related Feature Screens
import '../equipment/equipment_detail_screen.dart';
import '../equipment/add_equipment_screen.dart';
import '../equipment/my_equipment_screen.dart';
import '../search/global_search_screen.dart';
import '../hospital/hospital_screen.dart';
import '../requests/request_screen.dart';
import '../rental/my_rentals_screen.dart';
import '../rental/book_rental_dialog.dart';
import '../donations/my_donations_screen.dart';
import '../settings/help_support_screen.dart';

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
      final auth = context.read<AuthProvider>();
      final lang = context.read<ThemeProvider>().selectedLanguage;
      final role = auth.user?.role ?? 'DONOR';
      context.read<MenuChatbotProvider>().setRole(role, auth.user?.id);
      context.read<MenuChatbotProvider>().updateLanguage(lang);
      _scrollToBottom();
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
    final provider = context.read<MenuChatbotProvider>();
    provider.sendMessage(text, lang: lang).then((_) {
      _scrollToBottom();
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
            const Icon(Icons.delete_sweep_outlined, color: AppColors.primary),
            const SizedBox(width: 10),
            Text('Reset Chat', style: TextStyle(color: context.textPrimaryColor)),
          ],
        ),
        content: Text(
          'Are you sure you want to clear conversation history with MediShare Support?',
          style: TextStyle(color: context.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MenuChatbotProvider>().clearChat(lang);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat history reset to main menu.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAttachmentSheet() {
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
                "Attach or Share",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo_library_outlined,
                    label: "Photo",
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("To upload equipment photos, use the 'Add Equipment' or 'Donate' flow."),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.my_location_rounded,
                    label: "GPS Location",
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleSend(context.read<ThemeProvider>().selectedLanguage, "1");
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.receipt_long_outlined,
                    label: "My Requests",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleSend(context.read<ThemeProvider>().selectedLanguage, "3");
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.local_shipping_outlined,
                    label: "Rentals",
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleSend(context.read<ThemeProvider>().selectedLanguage, "4");
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withAlpha(25),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsModal(ChatMessageModel message) {
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
              title: Text("Copy Text", style: TextStyle(color: context.textPrimaryColor)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Message copied to clipboard."),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            if (message.isUser)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text("Delete Message", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<MenuChatbotProvider>().deleteMessage(message.id);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRequestDialog(BuildContext context, EquipmentModel equipment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.send_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Request ${equipment.name}",
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Please state the medical reason or urgency for this request:",
                    style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    style: TextStyle(color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: "e.g., Post-surgery home recovery for elderly patient",
                      hintStyle: TextStyle(color: context.textHintColor, fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: context.inputBg,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter a reason for the request."),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(ctx);
                          setDialogState(() => isSubmitting = true);
                          final provider = context.read<MenuChatbotProvider>();
                          final success = await provider.submitEquipmentRequest(
                            equipmentId: equipment.id,
                            reason: reason,
                          );
                          setDialogState(() => isSubmitting = false);

                          if (mounted) {
                            navigator.pop();
                            _scrollToBottom();
                            if (success) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text("Equipment request submitted successfully!"),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Submit Request"),
                ),
              ],
            );
          },
        );
      },
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
    final provider = context.watch<MenuChatbotProvider>();
    final messages = provider.messages;
    final isTyping = provider.isTyping;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: context.surfaceBg, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          "MediShare Support",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: context.textPrimaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: AppColors.primary, size: 15),
                    ],
                  ),
                  const Text(
                    "Online • Official MediShare Desk",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Reset to Main Menu',
            onPressed: () => _confirmClearChat(lang),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            tooltip: 'Support Info',
            onPressed: () => Navigator.push(
              context,
              AppPageTransitions.slideRight(const HelpSupportScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Chat Messages ─────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isTyping) {
                  return _buildTypingIndicator(lang);
                }

                final item = messages[index];
                return _buildMessageEntry(item, lang);
              },
            ),
          ),

          // ── Bottom Composer ───────────────────────────────────────
          SafeArea(
            child: Container(
              color: context.surfaceBg,
              padding: const EdgeInsets.fromLTRB(10, 8, 12, 10),
              child: Row(
                children: [
                  // Attachment Button
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 26),
                    onPressed: _showAttachmentSheet,
                  ),

                  // Input Box
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !isTyping,
                      style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: isTyping ? "MediShare Support is responding..." : "Type a message or enter 1-6...",
                        hintStyle: TextStyle(color: context.textHintColor, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: context.inputBg,
                      ),
                      onSubmitted: (val) => _handleSend(lang),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Button
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isTyping ? Colors.grey.shade400 : AppColors.primary,
                    child: IconButton(
                      icon: isTyping
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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

  // ── Render each message entry ──────────────────────────────────────
  Widget _buildMessageEntry(ChatMessageModel item, String lang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            item.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bubble
          _buildMessageBubble(item, lang),

          // Render equipment cards if message contains them
          if (!item.isUser &&
              item.equipmentList != null &&
              item.equipmentList!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildEquipmentCardsCarousel(item.equipmentList!),
          ],

          // Render options chips / radius choices if available
          if (!item.isUser && item.options != null && item.options!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInteractiveOptions(item.options!, lang),
          ],

          // Main Menu Button
          if (!item.isUser && item.showMainMenuButton) ...[
            const SizedBox(height: 8),
            _buildMainMenuButton(lang),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel item, String lang) {
    final isUser = item.isUser;

    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: item.isError ? Colors.red.shade100 : AppColors.primary.withAlpha(25),
            child: Icon(
              item.isError
                  ? Icons.warning_amber_rounded
                  : Icons.support_agent_rounded,
              color: item.isError ? Colors.red : AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: GestureDetector(
            onLongPress: () => _showOptionsModal(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.primaryGradient : null,
                color: isUser
                    ? null
                    : (item.isError
                        ? Colors.red.shade900.withAlpha(40)
                        : context.cardBg),
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
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: isUser
                          ? Colors.white
                          : (item.isError ? Colors.red : context.textPrimaryColor),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(item.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser ? Colors.white70 : context.textSecondaryColor,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ],
      ],
    );
  }

  // ── Render interactive options / menu items ────────────────────────
  Widget _buildInteractiveOptions(List<String> options, String lang) {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          return InkWell(
            onTap: () {
              if (opt == "Open Hospital Directory") {
                Navigator.push(context, AppPageTransitions.slideRight(const HospitalScreen()));
              } else if (opt == "View All Requests" || opt == "View Requests" || opt == "My Requests") {
                Navigator.push(context, AppPageTransitions.slideRight(const RequestScreen()));
              } else if (opt == "Open Rentals & Tracking" || opt == "Open Rentals" || opt == "My Rentals" || opt == "Rental Requests" || opt == "Open Rental Requests") {
                Navigator.push(context, AppPageTransitions.slideRight(const MyRentalsScreen()));
              } else if (opt == "Start a Donation" || opt == "Add Equipment" || opt == "Open Add Equipment Form" || opt == "List Equipment to Donate") {
                Navigator.push(context, AppPageTransitions.slideUp(const AddEquipmentScreen()));
              } else if (opt == "View My Donations" || opt == "View Donations") {
                Navigator.push(context, AppPageTransitions.slideRight(const MyDonationsScreen()));
              } else if (opt == "View My Equipment" || opt == "Hospital Equipment") {
                Navigator.push(context, AppPageTransitions.slideRight(const MyEquipmentScreen()));
              } else if (opt == "Open Search Screen" || opt == "Browse Equipment to Request" || opt == "View Equipment to Rent" || opt == "Browse Equipment") {
                Navigator.push(context, AppPageTransitions.slideRight(const GlobalSearchScreen()));
              } else if (opt == "Contact Support") {
                Navigator.push(context, AppPageTransitions.slideRight(const HelpSupportScreen()));
              } else if (opt == "Grant Permission / Retry" || opt == "View All Equipment") {
                _handleSend(lang, "1");
              } else {
                // Numbered option or radius option
                _handleSend(lang, opt);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(120)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                opt,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Main Menu Button ───────────────────────────────────────────────
  Widget _buildMainMenuButton(String lang) {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        ),
        onPressed: () => _handleSend(lang, "main menu"),
        icon: const Icon(Icons.home_outlined, size: 16),
        label: const Text(
          "[ Main Menu ]",
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── Equipment Cards Carousel ───────────────────────────────────────
  Widget _buildEquipmentCardsCarousel(List<EquipmentModel> equipmentList) {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: SizedBox(
        height: 290,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: equipmentList.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final eq = equipmentList[index];
            return _buildEquipmentCard(eq);
          },
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(EquipmentModel eq) {
    final hasDistance = eq.distance != null;
    final distanceText = hasDistance
        ? "${eq.distance!.toStringAsFixed(1)} km away"
        : (eq.location.isNotEmpty ? eq.location : "MediShare Partner");

    final isRent = eq.mode == 'RENT' || eq.mode == 'BOTH';

    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(context.isDarkMode ? 35 : 10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + Status & Mode Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: MsImage(
                  imageUrl: eq.image,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "AVAILABLE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: eq.mode == 'RENT'
                        ? const Color(0xFF0284C7)
                        : (eq.mode == 'BOTH' ? Colors.purple : Colors.teal),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    eq.mode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Details Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eq.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        eq.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              distanceText,
                              style: const TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (isRent && eq.rentalPricePerDay != null) ...[
                        Text(
                          "₹${eq.rentalPricePerDay!.toInt()}/day${eq.securityDeposit != null ? ' • Deposit: ₹${eq.securityDeposit!.toInt()}' : ''}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ] else ...[
                        const Text(
                          "Free for patient use",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Action Buttons
                  Row(
                    children: [
                      // View Details
                      Expanded(
                        child: SizedBox(
                          height: 28,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: BorderSide(color: context.borderColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                AppPageTransitions.slideRight(
                                  EquipmentDetailScreen(equipment: eq),
                                ),
                              );
                            },
                            child: Text(
                              "Details",
                              style: TextStyle(fontSize: 10.5, color: context.textPrimaryColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Primary Action: Rent or Request
                      Expanded(
                        child: SizedBox(
                          height: 28,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: eq.mode == 'RENT'
                                  ? const Color(0xFF0284C7)
                                  : AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (eq.mode == 'RENT') {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => BookRentalDialog(equipment: eq),
                                );
                              } else {
                                _showRequestDialog(context, eq);
                              }
                            },
                            child: Text(
                              eq.mode == 'RENT' ? "Rent" : "Request",
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Typing Indicator ───────────────────────────────────────────────
  Widget _buildTypingIndicator(String lang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withAlpha(25),
            child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  "Support is typing...",
                  style: TextStyle(
                    fontSize: 12,
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