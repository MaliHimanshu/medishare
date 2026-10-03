import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_page_transitions.dart';
import '../../../models/equipment_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/equipment_provider.dart';
import '../../../providers/rental_provider.dart';
import '../../../shared/widgets/ms_skeleton.dart';
import '../../donations/my_donations_screen.dart';
import '../../equipment/add_equipment_screen.dart';
import '../../equipment/equipment_detail_screen.dart';
import '../../equipment/my_equipment_screen.dart';
import '../../rental/my_rentals_screen.dart';
import '../../chatbot/chat_home_screen.dart';

class DonorDashboard extends StatefulWidget {
  final UserModel user;

  const DonorDashboard({super.key, required this.user});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchAll();
      context.read<EquipmentProvider>().fetchEquipment();
      context.read<RentalProvider>().fetchRentals();
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
    final dash = context.watch<DashboardProvider>();
    final equipProv = context.watch<EquipmentProvider>();
    final rentalProv = context.watch<RentalProvider>();

    final sum = dash.summary;
    // Calculate real numbers from provider data or summary
    final myEquipmentCount = equipProv.equipment
        .where((e) => e.ownerId == widget.user.id)
        .length;
    final rentalRequestsCount = sum?['rentalRequests'] != null
        ? sum!['rentalRequests'].toString()
        : rentalProv.rentals
              .where((r) => r.status.name.toUpperCase() == 'PENDING')
              .length
              .toString();
    final activeRentalsCount = sum?['activeRentals'] != null
        ? sum!['activeRentals'].toString()
        : rentalProv.rentals
              .where((r) => r.status.name.toUpperCase() == 'ACTIVE')
              .length
              .toString();
    final donationsCount =
        sum?['donations']?.toString() ??
        sum?['completedDonations']?.toString() ??
        '0';

    final myEquipmentList = equipProv.equipment
        .where((e) => e.ownerId == widget.user.id)
        .take(5)
        .toList();
    final pendingRentals = rentalProv.rentals
        .where((r) => r.status.name.toUpperCase() == 'PENDING')
        .take(5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Donor Hero Banner ──────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(40),
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
                      "DONOR",
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
                "${widget.user.name.split(' ').first}! 🩺",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Donate medical equipment or offer equipment for rental to empower lives.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              // Donor Highlights
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
                    _DonorHeroStat(
                      label: "My Equipment",
                      value: myEquipmentCount.toString(),
                      icon: Icons.inventory_2_outlined,
                    ),
                    Container(height: 24, width: 1, color: Colors.white30),
                    _DonorHeroStat(
                      label: "Rental Requests",
                      value: rentalRequestsCount,
                      icon: Icons.assignment_outlined,
                    ),
                    Container(height: 24, width: 1, color: Colors.white30),
                    _DonorHeroStat(
                      label: "Donations",
                      value: donationsCount,
                      icon: Icons.volunteer_activism_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Donor Real Stats 2x2 Grid ──────────────────────────
        Row(
          children: [
            Expanded(
              child: _DonorStatCard(
                title: "My Equipment",
                value: myEquipmentCount.toString(),
                icon: Icons.inventory_2_rounded,
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  AppPageTransitions.slideRight(const MyEquipmentScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _DonorStatCard(
                title: "Rental Requests",
                value: rentalRequestsCount,
                icon: Icons.pending_actions_rounded,
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  AppPageTransitions.slideRight(const MyRentalsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _DonorStatCard(
                title: "Active Rentals",
                value: activeRentalsCount,
                icon: Icons.handshake_rounded,
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  AppPageTransitions.slideRight(const MyRentalsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _DonorStatCard(
                title: "Donation History",
                value: donationsCount,
                icon: Icons.volunteer_activism_rounded,
                color: Colors.pink,
                onTap: () => Navigator.push(
                  context,
                  AppPageTransitions.slideRight(const MyDonationsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Donor Quick Actions ────────────────────────────────
        Text(
          "Donor Quick Actions",
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
            _DonorActionButton(
              title: "Add Equip",
              icon: Icons.add_circle_outline,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                AppPageTransitions.slideUp(const AddEquipmentScreen()),
              ),
            ),
            _DonorActionButton(
              title: "Donate",
              icon: Icons.volunteer_activism_outlined,
              color: Colors.pink,
              onTap: () => Navigator.push(
                context,
                AppPageTransitions.slideRight(const MyDonationsScreen()),
              ),
            ),
            _DonorActionButton(
              title: "Rentals",
              icon: Icons.handshake_outlined,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                AppPageTransitions.slideRight(const MyRentalsScreen()),
              ),
            ),
            _DonorActionButton(
              title: "Assistant",
              icon: Icons.smart_toy_outlined,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                AppPageTransitions.slideUp(const ChatHomeScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Prioritized Section: My Equipment ──────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "My Listed Equipment (${myEquipmentList.length})",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                AppPageTransitions.slideRight(const MyEquipmentScreen()),
              ),
              child: const Text(
                "Manage All",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (equipProv.isLoading)
          const MsSkeleton(height: 110)
        else if (myEquipmentList.isEmpty)
          _EmptyBox(
            title: "No equipment listed yet",
            subtitle: "Add your first medical equipment to donate or rent out.",
            buttonText: "Add Equipment",
            onAction: () => Navigator.push(
              context,
              AppPageTransitions.slideUp(const AddEquipmentScreen()),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: myEquipmentList.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = myEquipmentList[index];
                return _DonorEquipmentTile(equipment: item);
              },
            ),
          ),
        const SizedBox(height: 28),

        // ── Prioritized Section: Rental Requests for My Equipment ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Rental Requests",
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
                "View All",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (rentalProv.isLoading)
          const MsSkeleton(height: 80)
        else if (pendingRentals.isEmpty)
          _EmptyBox(
            title: "No pending rental requests",
            subtitle:
                "Rental requests submitted for your equipment will appear here.",
          )
        else
          Column(
            children: pendingRentals.map((rental) {
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
                      backgroundColor: Colors.orange.withAlpha(30),
                      child: const Icon(
                        Icons.handshake_outlined,
                        color: Colors.orange,
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
                            "Renter: ${rental.renterName} • ${rental.numberOfDays} days",
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
                        color: Colors.orange.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        rental.status.name.toUpperCase(),
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
            }).toList(),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────
class _DonorHeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DonorHeroStat({
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

class _DonorStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DonorStatCard({
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withAlpha(context.isDarkMode ? 30 : 5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(30),
              radius: 20,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonorActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DonorActionButton({
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

class _DonorEquipmentTile extends StatelessWidget {
  final EquipmentModel equipment;

  const _DonorEquipmentTile({required this.equipment});

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
        width: 200,
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
              "Mode: ${equipment.mode} • Qty: ${equipment.quantity}",
              style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
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
                    color: Colors.teal.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    equipment.status,
                    style: const TextStyle(
                      color: Colors.teal,
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

class _EmptyBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onAction;

  const _EmptyBox({
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
