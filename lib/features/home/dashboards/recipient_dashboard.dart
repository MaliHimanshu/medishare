import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_page_transitions.dart';
import '../../../models/equipment_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/equipment_provider.dart';
import '../../../providers/rental_provider.dart';
import '../../../providers/request_provider.dart';
import '../../../shared/widgets/ms_skeleton.dart';
import '../../equipment/equipment_list_screen.dart';
import '../../equipment/nearby_equipment_screen.dart';
import '../../equipment/equipment_detail_screen.dart';
import '../../rental/my_rentals_screen.dart';
import '../../requests/request_screen.dart';
import '../../search/global_search_screen.dart';
import '../../chatbot/chat_home_screen.dart';

class RecipientDashboard extends StatefulWidget {
  final UserModel user;

  const RecipientDashboard({super.key, required this.user});

  @override
  State<RecipientDashboard> createState() => _RecipientDashboardState();
}

class _RecipientDashboardState extends State<RecipientDashboard> {
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _categories = const [
    {"name": "All", "icon": Icons.grid_view_rounded},
    {"name": "Mobility", "icon": Icons.accessible_rounded},
    {"name": "Respiratory", "icon": Icons.air_rounded},
    {"name": "Monitoring", "icon": Icons.monitor_heart_rounded},
    {"name": "Support", "icon": Icons.healing_rounded},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchAll();
      context.read<EquipmentProvider>().fetchEquipment();
      context.read<RentalProvider>().fetchRentals();
      context.read<RequestProvider>().fetchRequests();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipProv = context.watch<EquipmentProvider>();
    final rentalProv = context.watch<RentalProvider>();
    final reqProv = context.watch<RequestProvider>();

    final availableNearbyCount = equipProv.equipment
        .where((e) => e.status == 'AVAILABLE')
        .length;
    final activeRentalsCount = rentalProv.rentals
        .where((r) => r.status.name.toUpperCase() == 'ACTIVE')
        .length;
    final myRequestsCount = reqProv.requests.length;

    // Filter available equipment by selected category
    List<EquipmentModel> availableList = equipProv.equipment
        .where((e) => e.status == 'AVAILABLE')
        .toList();
    if (_selectedCategory != 'All') {
      availableList = availableList
          .where(
            (e) => e.category.toLowerCase().contains(
              _selectedCategory.toLowerCase(),
            ),
          )
          .toList();
    }
    final displayAvailable = availableList.take(6).toList();

    final myRentalsList = rentalProv.rentals.take(3).toList();
    final myRequestsList = reqProv.requests.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Recipient Hero Banner ──────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withAlpha(50),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_getGreeting()},",
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "RECIPIENT",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                "${widget.user.name.split(' ').first}! 💙",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Find, request, or rent essential medical equipment at minimal or zero cost.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              // Highlights
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withAlpha(40),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _RecipientHeroStat(
                      label: "Available Nearby",
                      value: availableNearbyCount.toString(),
                      icon: Icons.location_on_outlined,
                    ),
                    Container(height: 24, width: 1, color: Colors.white30),
                    _RecipientHeroStat(
                      label: "Active Rental",
                      value: activeRentalsCount.toString(),
                      icon: Icons.handshake_outlined,
                    ),
                    Container(height: 24, width: 1, color: Colors.white30),
                    _RecipientHeroStat(
                      label: "My Requests",
                      value: myRequestsCount.toString(),
                      icon: Icons.assignment_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Prioritized Section: Search Equipment Bar ──────────
        InkWell(
          onTap: () => Navigator.push(
            context,
            AppPageTransitions.slideRight(const GlobalSearchScreen()),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(
                    context.isDarkMode ? 30 : 5,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Search oxygen, wheelchair, monitor...",
                    style: TextStyle(
                      color: context.textHintColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Find",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Recipient Real Stats Row ───────────────────────────
        Row(
          children: [
            Expanded(
              child: _RecipientStatCard(
                title: "Available Nearby",
                value: availableNearbyCount.toString(),
                icon: Icons.location_on_rounded,
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  AppPageTransitions.slideRight(const NearbyEquipmentScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RecipientStatCard(
                title: "Active Rental",
                value: activeRentalsCount.toString(),
                icon: Icons.handshake_rounded,
                color: const Color(0xFF0284C7),
                onTap: () => Navigator.push(
                  context,
                  AppPageTransitions.slideRight(const MyRentalsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RecipientStatCard(
                title: "My Requests",
                value: myRequestsCount.toString(),
                icon: Icons.assignment_rounded,
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  AppPageTransitions.slideRight(const RequestScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Prioritized Section: Equipment Categories ──────────
        Text(
          "Categories",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              final cat = _categories[idx];
              final isSelected = _selectedCategory == cat["name"];
              return InkWell(
                onTap: () =>
                    setState(() => _selectedCategory = cat["name"] as String),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : context.borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        cat["icon"] as IconData,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : context.textSecondaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat["name"] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : context.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 26),

        // ── Recipient Quick Actions ────────────────────────────
        Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _RecipientActionButton(
              title: "Explore",
              icon: Icons.explore_outlined,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                AppPageTransitions.slideRight(const EquipmentListScreen()),
              ),
            ),
            _RecipientActionButton(
              title: "Nearby",
              icon: Icons.near_me_outlined,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                AppPageTransitions.slideRight(const NearbyEquipmentScreen()),
              ),
            ),
            _RecipientActionButton(
              title: "My Rentals",
              icon: Icons.handshake_outlined,
              color: const Color(0xFF0284C7),
              onTap: () => Navigator.push(
                context,
                AppPageTransitions.slideRight(const MyRentalsScreen()),
              ),
            ),
            _RecipientActionButton(
              title: "Assistant",
              icon: Icons.smart_toy_outlined,
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                AppPageTransitions.slideUp(const ChatHomeScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Prioritized Section: Available Equipment ───────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Available Equipment (${displayAvailable.length})",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                AppPageTransitions.slideRight(const EquipmentListScreen()),
              ),
              child: const Text(
                "See All",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (equipProv.isLoading)
          const MsSkeleton(height: 150)
        else if (displayAvailable.isEmpty)
          const _RecipientEmptyBox(
            title: "No equipment found",
            subtitle: "Try selecting another category or check back shortly.",
          )
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayAvailable.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final item = displayAvailable[index];
                return _RecipientEquipmentCard(equipment: item);
              },
            ),
          ),
        const SizedBox(height: 28),

        // ── Prioritized Section: My Active Rentals ─────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "My Rentals & Requests",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                AppPageTransitions.slideRight(const MyRentalsScreen()),
              ),
              child: const Text(
                "View Rentals",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (myRentalsList.isEmpty && myRequestsList.isEmpty)
          _RecipientEmptyBox(
            title: "No active rentals or requests",
            subtitle:
                "Browse available equipment above to rent or request supplies.",
            buttonText: "Browse Equipment",
            onAction: () => Navigator.push(
              context,
              AppPageTransitions.slideRight(const EquipmentListScreen()),
            ),
          )
        else ...[
          // Show rentals
          ...myRentalsList.map((rental) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF0284C7).withAlpha(25),
                    child: const Icon(
                      Icons.handshake_outlined,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rental.equipment?.name ?? "Equipment Rental",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Total: ₹${rental.totalAmount} • ${rental.numberOfDays} days",
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      rental.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Show requests
          ...myRequestsList.map((req) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange.withAlpha(25),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.equipment?.name ?? "Requested Equipment",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Reason: ${req.reason.isNotEmpty ? req.reason : 'Request submitted'}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      req.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────
class _RecipientHeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _RecipientHeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(190), fontSize: 10),
        ),
      ],
    );
  }
}

class _RecipientStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RecipientStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 78,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withAlpha(context.isDarkMode ? 30 : 5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RecipientActionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withAlpha(45)),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipientEquipmentCard extends StatelessWidget {
  final EquipmentModel equipment;

  const _RecipientEquipmentCard({required this.equipment});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        AppPageTransitions.slideRight(
          EquipmentDetailScreen(equipment: equipment),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withAlpha(25),
                  radius: 16,
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    equipment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              equipment.mode == 'RENT'
                  ? "₹${equipment.rentalPricePerDay?.toStringAsFixed(0) ?? '0'}/day"
                  : "Free for Donation",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: equipment.mode == 'RENT'
                    ? const Color(0xFF0284C7)
                    : AppColors.primary,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (equipment.mode == 'RENT'
                                ? const Color(0xFF0284C7)
                                : AppColors.primary)
                            .withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    equipment.mode == 'RENT' ? "Rent Now" : "Request",
                    style: TextStyle(
                      color: equipment.mode == 'RENT'
                          ? const Color(0xFF0284C7)
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientEmptyBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onAction;

  const _RecipientEmptyBox({
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
          ),
          if (buttonText != null && onAction != null) ...[
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onPressed: onAction,
              child: Text(
                buttonText!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
