// Hospital Emergency Alerts List Screen
// File: lib/features/emergency_alerts/hospital_emergency_alerts_screen.dart
//
// Lists all active and past emergency equipment alerts created by the hospital.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_page_transitions.dart';
import '../../providers/emergency_alert_provider.dart';
import 'create_emergency_alert_screen.dart';
import 'hospital_alert_detail_screen.dart';

class HospitalEmergencyAlertsScreen extends StatefulWidget {
  const HospitalEmergencyAlertsScreen({super.key});

  @override
  State<HospitalEmergencyAlertsScreen> createState() => _HospitalEmergencyAlertsScreenState();
}

class _HospitalEmergencyAlertsScreenState extends State<HospitalEmergencyAlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyAlertProvider>().fetchHospitalAlerts();
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.blue;
      case 'PARTIALLY_FULFILLED':
        return Colors.orange;
      case 'FULFILLED':
        return Colors.green;
      case 'CANCELLED':
      case 'EXPIRED':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<EmergencyAlertProvider>();
    final alerts = prov.hospitalAlerts;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Emergency Equipment Alerts',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            AppPageTransitions.slideUp(const CreateEmergencyAlertScreen()),
          );
        },
        backgroundColor: const Color(0xFFDC2626),
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: const Text(
          'New Alert 🚨',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => prov.fetchHospitalAlerts(),
        child: prov.isLoading && alerts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : alerts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.crisis_alert_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No Emergency Alerts Yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'When your facility faces a critical medical equipment shortage, broadcast an alert to immediately mobilize partner NGOs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: context.textSecondaryColor, height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                AppPageTransitions.slideUp(const CreateEmergencyAlertScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
                            label: const Text('Create Emergency Alert 🚨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: alerts.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            AppPageTransitions.slideRight(
                              HospitalAlertDetailScreen(alertId: alert.id),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: alert.isActive
                                  ? _getPriorityColor(alert.priority).withAlpha(80)
                                  : Colors.grey.withAlpha(40),
                              width: alert.isActive ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: alert.isActive
                                    ? _getPriorityColor(alert.priority).withAlpha(15)
                                    : Colors.black.withAlpha(5),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Priority & Status Chips
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(alert.priority).withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${alert.priority} PRIORITY',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getPriorityColor(alert.priority),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(alert.status).withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      alert.status.replaceAll('_', ' '),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(alert.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Equipment name & Required count
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

                              if (alert.address != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        alert.address!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),

                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: alert.fulfillmentPercentage,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    alert.totalAvailable >= alert.quantityRequired
                                        ? Colors.green
                                        : (alert.totalAvailable > 0 ? Colors.orange : Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Footer row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Available: ${alert.totalAvailable}/${alert.quantityRequired}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: alert.totalAvailable >= alert.quantityRequired
                                          ? Colors.green
                                          : AppColors.primary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${alert.responseCount} NGO offers',
                                        style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
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
