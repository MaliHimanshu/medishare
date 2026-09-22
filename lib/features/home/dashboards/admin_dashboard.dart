import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_page_transitions.dart';
import '../../../models/user_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../shared/widgets/ms_skeleton.dart';
import '../../equipment/equipment_list_screen.dart';
import '../../requests/request_screen.dart';
import '../../hospital/hospital_screen.dart';
import '../../chatbot/chat_home_screen.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel user;

  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final sum = dash.summary;

    final totalUsers = sum?['totalUsers']?.toString() ?? '0';
    final totalEquipment = sum?['totalEquipment']?.toString() ?? '0';
    final totalRequests = sum?['totalRequests']?.toString() ?? '0';
    final totalHospitals = sum?['totalHospitals']?.toString() ?? '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Admin Hero Banner ──────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
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
                  const Text(
                    "System Control,",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "ADMINISTRATOR",
                      style: TextStyle(
                        color: Colors.redAccent,
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
                "${widget.user.name} 🛡️",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "System-wide management across all donors, NGOs, hospitals, and recipients.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Stats 2x2 Grid ─────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _AdminStatCard(
                title: "Total Equipment",
                value: totalEquipment,
                icon: Icons.inventory_2_rounded,
                color: Colors.teal,
                onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const EquipmentListScreen())),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _AdminStatCard(
                title: "Total Users",
                value: totalUsers,
                icon: Icons.people_rounded,
                color: Colors.blue,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AdminStatCard(
                title: "Total Requests",
                value: totalRequests,
                icon: Icons.assignment_turned_in_rounded,
                color: Colors.orange,
                onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const RequestScreen())),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _AdminStatCard(
                title: "Hospitals",
                value: totalHospitals,
                icon: Icons.local_hospital_rounded,
                color: Colors.indigo,
                onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const HospitalScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Admin Quick Actions ────────────────────────────────
        Text(
          "Admin Actions",
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
            _AdminActionButton(
              title: "Equipment",
              icon: Icons.medical_services_outlined,
              color: Colors.teal,
              onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const EquipmentListScreen())),
            ),
            _AdminActionButton(
              title: "Requests",
              icon: Icons.assignment_outlined,
              color: Colors.orange,
              onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const RequestScreen())),
            ),
            _AdminActionButton(
              title: "Hospitals",
              icon: Icons.local_hospital_outlined,
              color: Colors.blue,
              onTap: () => Navigator.push(context, AppPageTransitions.slideRight(const HospitalScreen())),
            ),
            _AdminActionButton(
              title: "Assistant",
              icon: Icons.smart_toy_outlined,
              color: Colors.green,
              onTap: () => Navigator.push(context, AppPageTransitions.slideUp(const ChatHomeScreen())),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Recent Activity ────────────────────────────────────
        Text(
          "Platform Activity",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimaryColor),
        ),
        const SizedBox(height: 10),
        if (dash.isLoadingRequests)
          const MsSkeleton(height: 100)
        else
          Column(
            children: dash.recentRequests.take(5).map((req) {
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
                    const CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      child: Icon(Icons.hub_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req['equipment']?['name']?.toString() ?? "Equipment Request",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimaryColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "By: ${req['requester']?['name'] ?? 'User'}",
                            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        (req['status']?.toString() ?? 'PENDING').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
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

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminStatCard({
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

class _AdminActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionButton({
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
