import 'dart:async';
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

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentProvider>().fetchEquipment();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<EquipmentProvider>().setSearchQuery(query);
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
                    const SnackBar(
                      content: Text("Equipment deleted successfully."),
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
    final list = equipProv.filteredEquipment;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      
      // ── App Bar ─────────────────────────────────────────
      appBar: AppBar(
        title: const Text("Equipment Catalog"),
        centerTitle: true,
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: AppColors.primary),
            onPressed: () => _openFiltersSheet(context),
          ),
        ],
      ),

      // ── Body ────────────────────────────────────────────
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: "Search name, category, hospital...",
                      hintStyle: TextStyle(color: context.textHintColor),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                equipProv.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: context.inputBg,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.borderColor, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.borderColor, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active filter tags indicator row
          if (equipProv.selectedCategory != 'All' ||
              equipProv.selectedCondition != 'All' ||
              equipProv.selectedStatus != 'All' ||
              equipProv.selectedSort != 'Newest')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text("Active Filters", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textSecondaryColor)),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      equipProv.resetFilters();
                      _searchController.clear();
                    },
                    child: const Text("Clear All", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Catalog Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => equipProv.fetchEquipment(),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildListContent(equipProv, list, user),
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 4,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MsSkeleton(height: 120),
        ),
      );
    }

    if (equipProv.errorMessage.isNotEmpty) {
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
                Text("Error Loading Catalog", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
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
                  child: const Icon(Icons.medical_services_outlined, size: 54, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text("No Equipment Found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
                const SizedBox(height: 8),
                Text(
                  "Try refining your search or filters, or list a new item to get started.",
                  style: TextStyle(color: context.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    equipProv.resetFilters();
                    _searchController.clear();
                  },
                  child: const Text("Reset Filters"),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      key: const ValueKey('loaded'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final equipment = list[index];
        final bool isOwner = user?.id == equipment.ownerId || user?.role == 'ADMIN';

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
                    tag: 'equipment-image-${equipment.id}',
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
                          "Hospital/Donor: ${equipment.donor}",
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
                            if (isOwner)
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

  void _openFiltersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final equipProv = context.watch<EquipmentProvider>();
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Filter & Sort Equipment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const SizedBox(height: 16),
              
              Text("Category", style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All', 'Mobility', 'Respiratory', 'Monitoring', 'Furniture', 'Surgical'].map((cat) {
                  final isSelected = equipProv.selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) => equipProv.setFilters(
                      category: cat,
                      condition: equipProv.selectedCondition,
                      status: equipProv.selectedStatus,
                      sort: equipProv.selectedSort,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              Text("Condition", style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All', 'New', 'Refurbished', 'Used'].map((cond) {
                  final isSelected = equipProv.selectedCondition == cond;
                  return ChoiceChip(
                    label: Text(cond),
                    selected: isSelected,
                    onSelected: (val) => equipProv.setFilters(
                      category: equipProv.selectedCategory,
                      condition: cond,
                      status: equipProv.selectedStatus,
                      sort: equipProv.selectedSort,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              Text("Sort By", style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Newest', 'Name (A-Z)', 'Quantity (High-Low)'].map((sort) {
                  final isSelected = equipProv.selectedSort == sort;
                  return ChoiceChip(
                    label: Text(sort),
                    selected: isSelected,
                    onSelected: (val) => equipProv.setFilters(
                      category: equipProv.selectedCategory,
                      condition: equipProv.selectedCondition,
                      status: equipProv.selectedStatus,
                      sort: sort,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        equipProv.resetFilters();
                        Navigator.pop(ctx);
                      },
                      child: const Text("Reset All"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Apply Filters"),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}