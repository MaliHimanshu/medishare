import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_page_transitions.dart';
import '../../../models/equipment_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/equipment_provider.dart';
import '../../../providers/request_provider.dart';
import '../../../providers/donation_provider.dart';
import '../../../shared/widgets/ms_skeleton.dart';
import '../../donations/my_donations_screen.dart';
import '../../equipment/equipment_list_screen.dart';
import '../../equipment/equipment_detail_screen.dart';
import '../../requests/request_screen.dart';
import '../../requests/create_request_screen.dart';
import '../../../providers/emergency_alert_provider.dart';
import '../../emergency_alerts/ngo_emergency_alerts_screen.dart';

class NgoDashboard extends StatefulWidget {
  final UserModel user;

  const NgoDashboard({super.key, required this.user});

  @override
  State<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends State<NgoDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchAll();
      context.read<EquipmentProvider>().fetchEquipment();
      context.read<RequestProvider>().fetchRequests();
      context.read<DonationProvider>().fetchDonations();
      context.read<EmergencyAlertProvider>().fetchActiveAlerts();
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
    final reqProv = context.watch<RequestProvider>();
    final donProv = context.watch<DonationProvider>();

    final sum = dash.summary;
    final availableCount = equipProv.equipment.where((e) => e.status == 'AVAILABLE').length;
    final pendingRequestsCount = reqProv.requests.where((r) => r.status.toUpperCase() == 'PENDING').length;
    final donationsCount = donProv.donations.isNotEmpty
        ? donProv.donations.length.toString()
        : (sum?['donations']?.toString() ?? sum?['completedDonations']?.toString() ?? '0');
    final beneficiariesCount = sum?['beneficiaries']?.toString() ?? sum?['totalUsers']?.toString() ?? '1';

    final availableList = equipProv.equipment.where((e) => e.status == 'AVAILABLE').take(6).toList();
    final activeRequestsList = reqProv.requests.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── NGO Hero Banner ────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withAlpha(50),
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
                      "NGO PARTNER",
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
                "${widget.user.name}! 🤝",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Coordinate and redistribute medical supplies directly to communities in need.",
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
                    _NgoHeroStat(
                      label: "Available",
                      value: availableCount.toString(),
                      icon: Icons.check_circle_outline,
                    ),
                    Container(height: 24, width: 1, color: Colors.white30),
                    _NgoHeroStat(
                      label: "Pending Requests",
                      value: pendingRequestsCount.toString(),
                      icon: Icons.assignment_outlined,
                    ),
                    Container(height: 24, width: 1, color: Colors.white30),
                    _NgoHeroStat(
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

        // ── Emergency Alerts Banner ────────────────────────────
        Consumer<EmergencyAlertProvider>(
          builder: (context, emProv, _) {
            final activeCount = emProv.activeNgoAlertsCount;
            final hasCritical = emProv.activeNgoAlerts.any((a) => a.isCritical && a.isActive);

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasCritical
                      ? [const Color(0xFF7F1D1D), const Color(0xFFDC2626)]
                      : [const Color(0xFF0F766E), const Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (hasCritical ? Colors.red : Colors.teal).withAlpha(40),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.crisis_alert_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasCritical
                                  ? "🚨 CRITICAL EQUIPMENT SHORTAGE"
                                  : "Emergency Equipment Alerts 🚨",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              activeCount > 0
                                  ? "$activeCount hospital request(s) awaiting partner response"
                                  : "Hospital emergency equipment requests in your area",
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          AppPageTransitions.slideRight(const NgoEmergencyAlertsScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: hasCritical ? const Color(0xFFDC2626) : const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: const Icon(Icons.emergency_rounded, size: 18),
                      label: Text(
                        activeCount > 0 ? "VIEW $activeCount EMERGENCY ALERTS 🚨" : "VIEW EMERGENCY ALERTS",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // ── NGO Stats 2x2 Grid ─────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _NgoStatCard(
                title: "Available Equipment",
                value: availableCount.toString(),
                icon: Icons.medical_services_rounded,
                color: Colors.teal,
                onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const EquipmentListScreen())),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _NgoStatCard(
                title: "Pending Requests",
                value: pendingRequestsCount.toString(),
                icon: Icons.pending_actions_rounded,
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
              child: _NgoStatCard(
                title: "Donations",
                value: donationsCount,
                icon: Icons.volunteer_activism_rounded,
                color: Colors.pink,
                onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const MyDonationsScreen())),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _NgoStatCard(
                title: "Beneficiaries",
                value: beneficiariesCount,
                icon: Icons.diversity_3_rounded,
                color: Colors.indigo,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── NGO Quick Actions ──────────────────────────────────
        Text(
          "NGO Quick Actions",
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
            _NgoActionButton(
              title: "Alerts 🚨",
              icon: Icons.crisis_alert_rounded,
              color: Colors.red,
              onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const NgoEmergencyAlertsScreen())),
            ),
            _NgoActionButton(
              title: "Browse Equip",
              icon: Icons.search_rounded,
              color: Colors.teal,
              onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const EquipmentListScreen())),
            ),
            _NgoActionButton(
              title: "Request",
              icon: Icons.assignment_outlined,
              color: Colors.orange,
              onTap: () => Navigator.push(context, AppPageTransitions.slideUp(const CreateRequestScreen())),
            ),
            _NgoActionButton(
              title: "Donations",
              icon: Icons.favorite_border_outlined,
              color: Colors.pink,
              onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const MyDonationsScreen())),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Prioritized Section: Available Equipment ───────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Available Equipment ($availableCount)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, AppPageTransitions.slideRight(const EquipmentListScreen())),
              child: const Text("View Catalog", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (equipProv.isLoading)
          const MsSkeleton(height: 120)
        else if (availableList.isEmpty)
          const _NgoEmptyBox(
            title: "No equipment available right now",
            subtitle: "Equipment listed by donors and hospitals will appear here for allocation.",
          )
        else
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: availableList.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = availableList[index];
                return _NgoEquipmentCard(equipment: item);
              },
            ),
          ),
        const SizedBox(height: 28),

        // ── Prioritized Section: Active Equipment Requests ─────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Active Equipment Requests (${activeRequestsList.length})",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, AppPageTransitions.slideRight(const RequestScreen())),
              child: const Text("Manage Requests", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (reqProv.isLoading)
          const MsSkeleton(height: 90)
        else if (activeRequestsList.isEmpty)
          _NgoEmptyBox(
            title: "No active equipment requests",
            subtitle: "Submit equipment requests on behalf of beneficiaries.",
            buttonText: "Create Request",
            onAction: () => Navigator.push(context, AppPageTransitions.slideUp(const CreateRequestScreen())),
          )
        else
          Column(
            children: activeRequestsList.map((req) {
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
                      child: const Icon(Icons.assignment_outlined, color: Colors.orange),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.equipment?.name ?? "Equipment Request",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimaryColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            req.reason.isNotEmpty ? req.reason : "No reason provided",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(30),
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
            }).toList(),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────
class _NgoHeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _NgoHeroStat({required this.label, required this.value, required this.icon});

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

class _NgoStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NgoStatCard({
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

class _NgoActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NgoActionButton({
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

class _NgoEquipmentCard extends StatelessWidget {
  final EquipmentModel equipment;

  const _NgoEquipmentCard({required this.equipment});

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
                  backgroundColor: Colors.teal.withAlpha(25),
                  radius: 16,
                  child: const Icon(Icons.medical_services_outlined, color: Colors.teal, size: 16),
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
              "Cat: ${equipment.category} • Condition: ${equipment.condition}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Request Info",
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
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

class _NgoEmptyBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onAction;

  const _NgoEmptyBox({
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
