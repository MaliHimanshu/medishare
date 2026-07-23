import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../../providers/auth_provider.dart';
import '../../providers/equipment_provider.dart';

// Models
import '../../models/equipment_model.dart';

// Screens
import 'edit_equipment_screen.dart';

// Shared Constants
import '../../core/constants/app_colors.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final EquipmentModel equipment;

  const EquipmentDetailScreen({
    super.key,
    required this.equipment,
  });

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  bool _isRequesting = false;
  bool _isBookmarked = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Listing"),
        content: Text("Are you sure you want to delete '${widget.equipment.name}'? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              final provider = context.read<EquipmentProvider>();
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              Navigator.pop(ctx);
              
              final success = await provider.deleteEquipment(widget.equipment.id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? "Deleted successfully." : "Failed to delete listing."),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                if (success) {
                  navigator.pop(); // Return to list screen
                }
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // Request dialog showing text field for reasoning
  void _showRequestDialog(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Request ${widget.equipment.name}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Please state why you need this equipment. The owner will review your request.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Reason for request (e.g. Urgent ICU backup)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _isRequesting
                      ? null
                      : () async {
                          if (reasonController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter a reason."),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final provider = context.read<EquipmentProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(ctx);
                          setStateDialog(() => _isRequesting = true);
                          final success = await provider.requestEquipment(
                                equipmentId: widget.equipment.id,
                                reason: reasonController.text.trim(),
                              );
                          setStateDialog(() => _isRequesting = false);
                          
                          if (mounted) {
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? "Request submitted successfully!"
                                    : "Failed to submit request. Item may already be requested."),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: _isRequesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final bool isOwner = user?.id == widget.equipment.ownerId || user?.role == 'ADMIN';

    Color statusColor = Colors.teal;
    if (widget.equipment.status == 'REQUESTED') {
      statusColor = Colors.orange;
    } else if (widget.equipment.status == 'DONATED') {
      statusColor = Colors.pink;
    } else if (widget.equipment.status == 'UNAVAILABLE') {
      statusColor = Colors.grey;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.equipment.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Link copied to clipboard."),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditEquipmentScreen(equipment: widget.equipment),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Large Image
            Hero(
              tag: 'equipment-image-${widget.equipment.id}',
              child: Container(
                width: double.infinity,
                height: 240,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: widget.equipment.image.isNotEmpty
                    ? Image.network(
                        widget.equipment.image,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.medical_services_outlined,
                          color: Colors.white,
                          size: 70,
                        ),
                      )
                    : const Icon(
                        Icons.medical_services,
                        color: Colors.white,
                        size: 80,
                      ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Block
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.equipment.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.equipment.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: statusColor.withAlpha(50), width: 1),
                        ),
                        child: Text(
                          widget.equipment.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Key Details Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: Colors.grey.shade100, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.business_outlined, "Manufacturer", widget.equipment.manufacturer),
                          const Divider(height: 20),
                          _buildDetailRow(Icons.health_and_safety_outlined, "Condition", widget.equipment.condition),
                          const Divider(height: 20),
                          _buildDetailRow(Icons.inventory_2_outlined, "Quantity Available", "${widget.equipment.quantity} units"),
                          const Divider(height: 20),
                          _buildDetailRow(Icons.location_on_outlined, "Location", widget.equipment.location),
                          const Divider(height: 20),
                          _buildDetailRow(Icons.local_hospital_outlined, "Listed By", widget.equipment.donor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description Block
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.equipment.description.isNotEmpty
                        ? widget.equipment.description
                        : "No description provided for this listing.",
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // M3 Action Buttons Row
                  Row(
                    children: [
                      // Bookmark Action Button
                      IconButton.outlined(
                        icon: Icon(
                          _isBookmarked ? Icons.bookmark : Icons.bookmark_border_outlined,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isBookmarked = !_isBookmarked;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isBookmarked ? "Added to bookmarks." : "Removed from bookmarks."),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      
                      // Share Action Button
                      IconButton.outlined(
                        icon: const Icon(Icons.share_outlined, color: AppColors.primary),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Link copied to clipboard."),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      
                      if (widget.equipment.status == 'AVAILABLE' && !isOwner) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => _showRequestDialog(context),
                              icon: const Icon(Icons.send_outlined, size: 18),
                              label: const Text(
                                "Request Equipment",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        )
      ],
    );
  }
}