import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../../providers/auth_provider.dart';
import '../../providers/equipment_provider.dart';

// Models
import '../../models/equipment_model.dart';

// Shared Widgets
import '../../shared/widgets/ms_skeleton.dart';
import '../../shared/widgets/ms_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';

// Screens
import 'equipment_detail_screen.dart';
import 'edit_equipment_screen.dart';
import 'add_equipment_screen.dart';

class MyEquipmentScreen extends StatefulWidget {
  const MyEquipmentScreen({super.key});

  @override
  State<MyEquipmentScreen> createState() => _MyEquipmentScreenState();
}

class _MyEquipmentScreenState extends State<MyEquipmentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentProvider>().fetchEquipment();
    });
  }

  void _confirmDelete(BuildContext context, EquipmentModel equipment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Equipment"),
        content: Text("Are you sure you want to delete '${equipment.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final equipProv = context.read<EquipmentProvider>();
              Navigator.pop(ctx);

              final success = await equipProv.deleteEquipment(equipment.id);
              if (mounted) {
                if (success) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text("${equipment.name} deleted successfully."),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(equipProv.errorMessage.isNotEmpty
                          ? equipProv.errorMessage
                          : "Failed to delete equipment."),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final equipProv = context.watch<EquipmentProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    
    // Filter to only show equipment owned by the current user
    final myList = equipProv.equipment.where((e) => e.ownerId == user?.id).toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      
      // ── App Bar ─────────────────────────────────────────
      appBar: AppBar(
        title: const Text("My Equipment"),
        centerTitle: true,
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
      ),

      // ── Body ────────────────────────────────────────────
      body: RefreshIndicator(
        onRefresh: () => equipProv.fetchEquipment(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildListContent(equipProv, myList, user),
        ),
      ),

      // Floating Add Equipment Button
      floatingActionButton: AnimatedFAB(
        icon: Icons.add,
        label: 'Add Equipment',
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(context, AppPageTransitions.slideUp(const AddEquipmentScreen())).then((_) {
            equipProv.fetchEquipment();
          });
        },
      ),
    );
  }

  Widget _buildListContent(EquipmentProvider equipProv, List<EquipmentModel> list, dynamic user) {
    if (equipProv.isLoading) {
      return ListView.builder(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: 4,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MsSkeleton(height: 120),
        ),
      );
    }

    if (equipProv.errorMessage.isNotEmpty && list.isEmpty) {
      return ListView(
        key: const ValueKey('error'),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 50),
          Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text("Error Loading Equipment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
                const SizedBox(height: 8),
                Text(equipProv.errorMessage, style: TextStyle(color: context.textSecondaryColor), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => equipProv.fetchEquipment(),
                  child: const Text("Try Again"),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (list.isEmpty) {
      return ListView(
        key: const ValueKey('empty'),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 50),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text("No Equipment Listed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
                const SizedBox(height: 8),
                Text(
                  "You haven't listed any medical equipment yet. Start by adding equipment to donate or lend.",
                  style: TextStyle(color: context.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, AppPageTransitions.slideUp(const AddEquipmentScreen())).then((_) {
                      equipProv.fetchEquipment();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add Equipment"),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      key: const ValueKey('loaded'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final equipment = list[index];

        Color statusColor = Colors.teal;
        if (equipment.status == 'REQUESTED') {
          statusColor = Colors.orange;
        } else if (equipment.status == 'DONATED') {
          statusColor = Colors.pink;
        } else if (equipment.status == 'UNAVAILABLE') {
          statusColor = Colors.grey;
        }

        return AnimatedListItem(
          index: index,
          child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: context.borderColor, width: 1.5),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                AppPageTransitions.slideUp(
                  EquipmentDetailScreen(equipment: equipment),
                ),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // M3 Equipment Thumbnail
                  Hero(
                    tag: 'my-equipment-image-${equipment.id}',
                    child: Container(
                      width: 90,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: equipment.image.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                equipment.image,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.medical_services_outlined,
                                  color: AppColors.primary,
                                  size: 30,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.medical_services,
                              color: AppColors.primary,
                              size: 32,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Detail Fields
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              equipment.category,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.textSecondaryColor),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                equipment.status,
                                style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          equipment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          equipment.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "Qty: ${equipment.quantity} · ${equipment.condition}",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textSecondaryColor),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditEquipmentScreen(equipment: equipment),
                                      ),
                                    ).then((_) {
                                      equipProv.fetchEquipment();
                                    });
                                  },
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _confirmDelete(context, equipment),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ), // end Padding
          ), // end InkWell
        ), // end Card
        ); // end AnimatedListItem
      },
    );
  }
}