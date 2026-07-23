import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/global_search_provider.dart';
import '../../shared/widgets/ms_search_bar.dart';
import '../../shared/widgets/ms_skeleton.dart';
import '../../shared/widgets/ms_empty_state.dart';
import '../../shared/widgets/ms_status_chip.dart';
import '../../shared/widgets/ms_section_header.dart';
import '../../shared/widgets/ms_image.dart';
import '../../shared/widgets/ms_animations.dart';
import '../../core/theme/app_page_transitions.dart';

import '../equipment/equipment_detail_screen.dart';
import '../donations/donation_detail_screen.dart';
import '../requests/request_detail_screen.dart';
import '../hospital/hospital_detail_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchProv = context.watch<GlobalSearchProvider>();
    final query = searchProv.query;
    final selectedFilter = searchProv.selectedFilter;
    final isSearching = searchProv.isSearching;

    final filterOptions = ['All', 'Equipment', 'Donations', 'Requests', 'Hospitals'];

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Global Search'),
        centerTitle: true,
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search Bar Input ─────────────────────────────────────
          Container(
            color: context.surfaceBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                MSSearchBar(
                  controller: _searchController,
                  hintText: 'Search equipment, donations, requests, hospitals...',
                  onChanged: (val) {
                    searchProv.search(val);
                  },
                  onClear: () {
                    _searchController.clear();
                    searchProv.search('');
                  },
                ),
                const SizedBox(height: 10),

                // Filter Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterOptions.map((opt) {
                      final isSelected = selectedFilter == opt;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : context.textPrimaryColor,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withAlpha(35),
                          onSelected: (val) {
                            searchProv.setFilter(opt);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Body Content ──────────────────────────────────────────
          Expanded(
            child: _buildBodyContent(context, searchProv, query, selectedFilter, isSearching),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(
    BuildContext context,
    GlobalSearchProvider searchProv,
    String query,
    String filter,
    bool isSearching,
  ) {
    // 1. Initial State: Show Recent Searches & Quick Suggestions
    if (query.isEmpty) {
      return _buildRecentAndSuggestions(context, searchProv);
    }

    // 2. Loading State: Skeleton Cards
    if (isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: MsSkeleton(height: 100),
        ),
      );
    }

    // 3. Error State
    if (searchProv.errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: AppColors.error),
              const SizedBox(height: 16),
              Text(searchProv.errorMessage, style: TextStyle(color: context.textSecondaryColor), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => searchProv.search(query),
                child: const Text('Retry Search'),
              )
            ],
          ),
        ),
      );
    }

    // 4. No Results State
    if (searchProv.totalResultsCount == 0) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: MSEmptyState(
          icon: Icons.search_off_outlined,
          title: 'No Results Found',
          subtitle: 'No equipment, donations, requests, or hospitals matched "$query".',
          actionLabel: 'Clear Search',
          onAction: () {
            _searchController.clear();
            searchProv.search('');
          },
        ),
      );
    }

    // 5. Results State Grouped By Category
    final showEquip = filter == 'All' || filter == 'Equipment';
    final showHosp = filter == 'All' || filter == 'Hospitals';
    final showReq = filter == 'All' || filter == 'Requests';
    final showDon = filter == 'All' || filter == 'Donations';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Equipment Results Category ─────────────────────
        if (showEquip && searchProv.equipmentResults.isNotEmpty) ...[
          MSSectionHeader(title: 'Equipment (${searchProv.equipmentResults.length})'),
          const SizedBox(height: 10),
          ...searchProv.equipmentResults.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return AnimatedListItem(
              index: index,
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: context.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: context.borderColor),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(context, AppPageTransitions.slideRight(EquipmentDetailScreen(equipment: item)));
                  },
                  leading: MsImage(imageUrl: item.image, width: 44, height: 44, borderRadius: BorderRadius.circular(10)),
                  title: Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
                  subtitle: Text('Category: ${item.category} • Donor: ${item.donor}', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                  trailing: MSStatusChip(status: item.status),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        // ── Hospitals Results Category ─────────────────────
        if (showHosp && searchProv.hospitalResults.isNotEmpty) ...[
          MSSectionHeader(title: 'Hospitals (${searchProv.hospitalResults.length})'),
          const SizedBox(height: 10),
          ...searchProv.hospitalResults.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return AnimatedListItem(
              index: index,
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: context.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: context.borderColor),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(context, AppPageTransitions.slideRight(HospitalDetailScreen(hospital: item)));
                  },
                  leading: MsImage(imageUrl: item.image, width: 44, height: 44, borderRadius: BorderRadius.circular(10), placeholderIcon: Icons.local_hospital),
                  title: Text(item.hospitalName, style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
                  subtitle: Text('${item.address}, ${item.city}', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(item.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        // ── Requests Results Category ──────────────────────
        if (showReq && searchProv.requestResults.isNotEmpty) ...[
          MSSectionHeader(title: 'Requests (${searchProv.requestResults.length})'),
          const SizedBox(height: 10),
          ...searchProv.requestResults.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final equip = item.equipment;
            return AnimatedListItem(
              index: index,
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: context.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: context.borderColor),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(context, AppPageTransitions.slideRight(RequestDetailScreen(request: item)));
                  },
                  leading: MsImage(imageUrl: equip?.image, width: 44, height: 44, borderRadius: BorderRadius.circular(10)),
                  title: Text(equip?.name ?? 'Requested Equipment', style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
                  subtitle: Text('Requester: ${item.requesterName} • Hospital: ${item.hospital}', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                  trailing: MSStatusChip(status: item.status),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        // ── Donations Results Category ─────────────────────
        if (showDon && searchProv.donationResults.isNotEmpty) ...[
          MSSectionHeader(title: 'Donations (${searchProv.donationResults.length})'),
          const SizedBox(height: 10),
          ...searchProv.donationResults.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final equip = item.equipment;
            return AnimatedListItem(
              index: index,
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: context.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: context.borderColor),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(context, AppPageTransitions.slideRight(DonationDetailScreen(donation: item)));
                  },
                  leading: MsImage(imageUrl: equip?.image, width: 44, height: 44, borderRadius: BorderRadius.circular(10)),
                  title: Text(equip?.name ?? 'Donated Equipment', style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
                  subtitle: Text('Donor: ${item.donorName} • Hospital: ${item.hospital}', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                  trailing: MSStatusChip(status: item.status),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  /// Recent Searches & Popular Suggestions View
  Widget _buildRecentAndSuggestions(BuildContext context, GlobalSearchProvider searchProv) {
    final recents = searchProv.recentSearches;
    final suggestions = ['Wheelchair', 'Oxygen Cylinder', 'Hospital Bed', 'Ventilator', 'Civil Hospital'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches Header
          if (recents.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Searches', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
                TextButton(
                  onPressed: () => searchProv.clearRecentSearches(),
                  child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recents.map((term) {
                return InputChip(
                  label: Text(term, style: TextStyle(color: context.textPrimaryColor, fontSize: 12)),
                  backgroundColor: context.cardBg,
                  side: BorderSide(color: context.borderColor),
                  onPressed: () {
                    _searchController.text = term;
                    searchProv.search(term);
                  },
                  onDeleted: () => searchProv.removeRecentSearch(term),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Popular Suggestions Header
          Text('Popular Suggestions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((sug) {
              return ActionChip(
                avatar: const Icon(Icons.trending_up, size: 14, color: AppColors.primary),
                label: Text(sug, style: TextStyle(color: context.textPrimaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                backgroundColor: context.cardBg,
                side: BorderSide(color: context.borderColor),
                onPressed: () {
                  _searchController.text = sug;
                  searchProv.search(sug);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
