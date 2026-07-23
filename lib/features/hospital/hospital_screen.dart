import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/hospital_model.dart';
import '../../providers/hospital_provider.dart';
import '../../shared/widgets/ms_skeleton.dart';
import '../../shared/widgets/ms_image.dart';
import '../../shared/widgets/ms_animations.dart';
import '../../core/theme/app_page_transitions.dart';
import 'add_hospital_screen.dart';
import 'hospital_detail_screen.dart';
import 'edit_hospital_screen.dart';

class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key});

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HospitalProvider>().fetchHospitals();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<HospitalProvider>().fetchHospitals();
  }

  void _confirmDelete(HospitalModel hospital) {
    final provider = context.read<HospitalProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Hospital'),
        content: Text('Are you sure you want to delete "${hospital.hospitalName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);

              final success = await provider.deleteHospital(hospital.id);

              if (mounted) {
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Hospital deleted successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage.isNotEmpty
                          ? provider.errorMessage
                          : 'Failed to delete hospital.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hospitalProvider = context.watch<HospitalProvider>();
    final filtered = hospitalProvider.filteredHospitals;
    final availableCities = hospitalProvider.availableCities;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Hospitals Network'),
        centerTitle: true,
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: hospitalProvider.fetchHospitals,
          ),
        ],
      ),
      floatingActionButton: AnimatedFAB(
        icon: Icons.add_business_outlined,
        label: 'Add Hospital',
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final res = await Navigator.push(
            context,
            AppPageTransitions.slideUp(const AddHospitalScreen()),
          );
          if (res == true && mounted) {
            hospitalProvider.fetchHospitals();
          }
        },
      ),
      body: Column(
        children: [
          // Search & Filter Header Section
          Container(
            color: context.surfaceBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchCtrl,
                  onChanged: hospitalProvider.setSearchQuery,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: 'Search hospital by name, city, or state...',
                    hintStyle: TextStyle(color: context.textHintColor),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              hospitalProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: context.inputBg,
                  ),
                ),

                const SizedBox(height: 10),

                // City Filter Chips
                if (availableCities.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: availableCities.map((cityName) {
                        final isSelected = hospitalProvider.selectedCity == cityName;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              cityName == 'All' ? 'All Cities' : cityName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : context.textPrimaryColor,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withAlpha(35),
                            onSelected: (val) {
                              hospitalProvider.setCityFilter(cityName);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _buildContent(hospitalProvider, filtered),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      HospitalProvider hospitalProvider, List<HospitalModel> filtered) {
    if (hospitalProvider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, index) => const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: MsSkeleton(height: 140),
        ),
      );
    }

    if (hospitalProvider.errorMessage.isNotEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(32),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.error_outline, size: 60, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                hospitalProvider.errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: hospitalProvider.fetchHospitals,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(32),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withAlpha(20),
                child: const Icon(
                  Icons.local_hospital_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Hospitals Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No medical facilities match your search query or city filters.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddHospitalScreen()),
                  );
                  if (res == true && mounted) {
                    hospitalProvider.fetchHospitals();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Hospital'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];

        return AnimatedListItem(
          index: index,
          child: Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 0,
          color: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: context.borderColor),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                AppPageTransitions.slideUp(
                  HospitalDetailScreen(hospital: item),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hospital Logo Hero image
                      Hero(
                        tag: 'hospital_logo_${item.id}',
                        child: MsImage(
                          imageUrl: item.image,
                          width: 56,
                          height: 56,
                          borderRadius: BorderRadius.circular(14),
                          placeholderIcon: Icons.local_hospital,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Hospital Name & Address
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.hospitalName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                ),

                                // Actions (Edit / Delete)
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18, color: AppColors.primary),
                                      tooltip: 'Edit Hospital',
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      onPressed: () async {
                                        final res = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditHospitalScreen(hospital: item),
                                          ),
                                        );
                                        if (res == true && context.mounted) {
                                          hospitalProvider.fetchHospitals();
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18, color: Colors.red),
                                      tooltip: 'Delete Hospital',
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      onPressed: () => _confirmDelete(item),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.address}, ${item.city}, ${item.state}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(height: 1, color: context.borderColor),
                  const SizedBox(height: 10),

                  // Bottom Grid Metadata (Contact, Equipment Count, Rating)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            item.phone,
                            style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.medical_services_outlined, size: 14, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text(
                            '${item.availableEquipmentCount} Items',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
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