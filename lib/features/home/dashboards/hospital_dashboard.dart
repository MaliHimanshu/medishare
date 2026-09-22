import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_page_transitions.dart';
import '../../../models/equipment_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/equipment_provider.dart';
import '../../../providers/request_provider.dart';
import '../../../providers/rental_provider.dart';
import '../../../providers/donation_provider.dart';
import '../../../shared/widgets/ms_skeleton.dart';
import '../../donations/my_donations_screen.dart';
import '../../equipment/add_equipment_screen.dart';
import '../../equipment/equipment_list_screen.dart';
import '../../equipment/equipment_detail_screen.dart';
import '../../equipment/my_equipment_screen.dart';
import '../../requests/request_screen.dart';
import '../../requests/create_request_screen.dart';
import '../../rental/my_rentals_screen.dart';

class HospitalDashboard extends StatefulWidget {
  final UserModel user;

  const HospitalDashboard({super.key, required this.user});

  @override
  State<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends State<HospitalDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchAll();
      context.read<EquipmentProvider>().fetchEquipment();
      context.read<RequestProvider>().fetchRequests();
      context.read<RentalProvider>().fetchRentals();
      context.read<DonationProvider>().fetchDonations();
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
    final reqProv = context.watch<RequestProvider>();
    final rentalProv = context.watch<RentalProvider>();

    final hospitalEquipmentCount = equipProv.equipment.where((e) => e.ownerId == widget.user.id).length;
    final equipmentRequestsCount = reqProv.requests.length;
    final activeRentalsCount = rentalProv.rentals.where((r) => r.status.toUpperCase() == 'ACTIVE').length;
    final availableEquipmentCount = equipProv.equipment.where((e) => e.status == 'AVAILABLE').length;

    final hospitalEquipmentList = equipProv.equipment.where((e) => e.ownerId == widget.user.id).take(5).toList();
    final recentRequestsList = reqProv.requests.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hospital Hero Banner ───────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withAlpha(50),
                blurRadius: 14,
                offset: const Offset(0, 5),
              )
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "HOSPITAL",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 2),
              Text(
                "${widget.user.name}! 🏥",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Coordinate medical apparatus, manage rentals, and procure emergency equipment.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              // Highlights
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(40), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _HospitalHeroStat(
                      label: "Hospital Equip",
                      value: hospitalEquipmentCount.toString(),
                      icon: Icons.local_hospital_outlined,
                    ),
                    Container(height: 24, width: 1, color: Colors.white30),
                    _HospitalHeroStat(
                      label: "Requests",
                      value: equipmentRequestsCount.toString(),
                      icon: Icons.assignment_outlined,
                    ),
                    Container(height: 24, width: 1, color: Colors.white30),
                    _HospitalHeroStat(
                      label: "Active Rentals",
                      value: activeRentalsCount.toString(),
                      icon: Icons.handshake_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Hospital Stats 2x2 Grid ────────────────────────────
        Row(
          children: [
            Expanded(
              child: _HospitalStatCard(
                title: "Hospital Equipment",
                value: hospitalEquipmentCount.toString(),
                icon: Icons.local_hospital_rounded,
                color: Colors.blue,
                onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const MyEquipmentScreen())),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _HospitalStatCard(
                title: "Equipment Requests",
                value: equipmentRequestsCount.toString(),
                icon: Icons.assignment_turned_in_rounded,
                color: Colors.orange,
                onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const RequestScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _HospitalStatCard(
                title: "Active Rentals",
                value: activeRentalsCount.toString(),
                icon: Icons.handshake_rounded,
                color: Colors.teal,
                onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const MyRentalsScreen())),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _HospitalStatCard(
                title: "Available Catalog",
                value: availableEquipmentCount.toString(),
                icon: Icons.inventory_rounded,
                color: Colors.purple,
                onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const EquipmentListScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Hospital Quick Actions ─────────────────────────────
        Text(
          "Hospital Quick Actions",
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
            _HospitalActionButton(
              title: "Add Equip",
              icon: Icons.add_circle_outline,
              color: Colors.blue,
              onTap: () => Navigator.push(context, AppPageTransitions.slideUp(const AddEquipmentScreen())),
            ),
            _HospitalActionButton(
              title: "Request",
              icon: Icons.assignment_outlined,
              color: Colors.orange,
              onTap: () => Navigator.push(context, AppPageTransitions.slideUp(const CreateRequestScreen())),
            ),
            _HospitalActionButton(
              title: "Rent Equip",
              icon: Icons.handshake_outlined,
              color: Colors.teal,
              onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const EquipmentListScreen())),
            ),
            _HospitalActionButton(
              title: "Donate",
              icon: Icons.volunteer_activism_outlined,
              color: Colors.pink,
              onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const MyDonationsScreen())),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Prioritized Section: Hospital Equipment ────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Hospital Equipment ($hospitalEquipmentCount)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, AppPageTransitions.slideRight(const MyEquipmentScreen())),
              child: const Text("Manage All", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (equipProv.isLoading)
          const MsSkeleton(height: 120)
        else if (hospitalEquipmentList.isEmpty)
          _HospitalEmptyBox(
            title: "No hospital equipment registered",
            subtitle: "Register your hospital's equipment for rental or donation transfer.",
            buttonText: "Register Equipment",
            onAction: () => Navigator.push(context, AppPageTransitions.slideUp(const AddEquipmentScreen())),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hospitalEquipmentList.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = hospitalEquipmentList[index];
                return _HospitalEquipmentTile(equipment: item);
              },
            ),
          ),
        const SizedBox(height: 28),

        // ── Prioritized Section: Track Equipment Requests ──────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Equipment Requests & Rentals",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, AppPageTransitions.slideRight(const RequestScreen())),
              child: const Text("View All", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (reqProv.isLoading)
          const MsSkeleton(height: 80)
        else if (recentRequestsList.isEmpty)
          const _HospitalEmptyBox(
            title: "No equipment requests pending",
            subtitle: "Requests from clinics or patients will appear here.",
          )
        else
          Column(
            children: recentRequestsList.map((req) {
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
                      backgroundColor: Colors.blue.withAlpha(25),
                      child: const Icon(Icons.medical_information_outlined, color: Colors.blue),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.equipment?.name ?? "Equipment",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimaryColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Requester: ${req.requesterName}",
                            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        req.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.blue,
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
class _HospitalHeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HospitalHeroStat({required this.label, required this.value, required this.icon});

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
          style: TextStyle(
            color: Colors.white.withAlpha(190),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _HospitalStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HospitalStatCard({
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
              color: Colors.black.withAlpha(context.isDarkMode ? 30 : 5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
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

class _HospitalActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HospitalActionButton({
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

class _HospitalEquipmentTile extends StatelessWidget {
  final EquipmentModel equipment;

  const _HospitalEquipmentTile({required this.equipment});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        AppPageTransitions.slideRight(EquipmentDetailScreen(equipment: equipment)),
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
                  backgroundColor: Colors.blue.withAlpha(25),
                  radius: 16,
                  child: const Icon(Icons.local_hospital_outlined, color: Colors.blue, size: 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    equipment.status,
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HospitalEmptyBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onAction;

  const _HospitalEmptyBox({
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimaryColor),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: onAction,
              child: Text(buttonText!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            )
          ]
        ],
      ),
    );
  }
}
