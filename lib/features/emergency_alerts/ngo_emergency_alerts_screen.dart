// NGO Emergency Alerts Screen
// File: lib/features/emergency_alerts/ngo_emergency_alerts_screen.dart
//
// Lists critical medical equipment shortage alerts from nearby hospitals
// requiring urgent NGO inventory contributions.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../providers/emergency_alert_provider.dart';
import 'ngo_emergency_detail_screen.dart';

class NgoEmergencyAlertsScreen extends StatefulWidget {
  const NgoEmergencyAlertsScreen({super.key});

  @override
  State<NgoEmergencyAlertsScreen> createState() =>
      _NgoEmergencyAlertsScreenState();
}

class _NgoEmergencyAlertsScreenState extends State<NgoEmergencyAlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyAlertProvider>().fetchActiveAlerts();
    });
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      case 'HIGH':
        return const Color(0xFFEA580C);
      case 'NORMAL':
      default:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<EmergencyAlertProvider>();
    final alerts = prov.activeNgoAlerts;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Emergency Equipment Alerts 🚨',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => prov.fetchActiveAlerts(),
        child: prov.isLoading && alerts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : alerts.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 64,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Active Emergency Alerts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All hospital equipment requirements in your area are currently fulfilled. You will receive high-priority alerts when an urgent shortage occurs.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: alerts.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  final isCritical = alert.isCritical;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        AppPageTransitions.slideRight(
                          NgoEmergencyDetailScreen(alertId: alert.id),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isCritical
                              ? const Color(0xFFDC2626).withAlpha(120)
                              : _getPriorityColor(alert.priority).withAlpha(60),
                          width: isCritical ? 2.0 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isCritical
                                ? Colors.red.withAlpha(25)
                                : Colors.black.withAlpha(5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Priority & Response Tag
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(
                                    alert.priority,
                                  ).withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.crisis_alert_rounded,
                                      size: 13,
                                      color: _getPriorityColor(alert.priority),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${alert.priority} PRIORITY',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getPriorityColor(
                                          alert.priority,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (alert.hasResponded)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Offered: ${alert.myResponse?.quantityAvailable ?? 0} units',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFDC2626,
                                    ).withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Needs Response 🚨',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Equipment Name & Required units
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  alert.equipmentName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                              ),
                              Text(
                                '${alert.quantityRequired} units',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),

                          // Hospital Name & Address
                          if (alert.hospital != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_hospital_rounded,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    alert.hospital!.displayName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          if (alert.address != null ||
                              alert.hospital?.address != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    alert.address ?? alert.hospital!.address!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.textSecondaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Card Footer / Action
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                alert.description != null &&
                                        alert.description!.isNotEmpty
                                    ? alert.description!
                                    : 'Urgent equipment request',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                              Row(
                                children: const [
                                  Text(
                                    'VIEW EMERGENCY',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
