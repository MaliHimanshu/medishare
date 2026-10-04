import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../delivery/assign_delivery_partner_screen.dart';
import 'equipment_inspection_screen.dart';
import '../../models/rental_model.dart';
import '../../providers/rental_provider.dart';

class NgoRentalManagementScreen extends StatefulWidget {
  const NgoRentalManagementScreen({super.key});

  @override
  State<NgoRentalManagementScreen> createState() => _NgoRentalManagementScreenState();
}

class _NgoRentalManagementScreenState extends State<NgoRentalManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalProvider>().fetchRentals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rentalProvider = context.watch<RentalProvider>();
    final rentals = rentalProvider.rentals;

    final requests = rentals.where((r) => r.status == RentalStatus.REQUESTED).toList();
    final active = rentals.where((r) => r.status == RentalStatus.ACTIVE || r.status == RentalStatus.APPROVED).toList();
    final returns = rentals.where((r) => r.status == RentalStatus.RETURN_REQUESTED || r.status == RentalStatus.RETURNED).toList();
    final history = rentals.where((r) => r.status == RentalStatus.COMPLETED || r.status == RentalStatus.CANCELLED || r.status == RentalStatus.DISPUTED).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          title: const Text('NGO Rental Management'),
          backgroundColor: context.surfaceBg,
          foregroundColor: context.textPrimaryColor,
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Requests'),
              Tab(text: 'Active'),
              Tab(text: 'Returns'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: rentalProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildList(requests, context, 'Pending Requests', emptyMsg: 'No pending requests.', isRequest: true),
                  _buildList(active, context, 'Active Rentals', emptyMsg: 'No active rentals.', isActive: true),
                  _buildList(returns, context, 'Pending Returns', emptyMsg: 'No returns pending.', isReturns: true),
                  _buildList(history, context, 'Rental History', emptyMsg: 'No history found.'),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<RentalModel> list, BuildContext context, String title, {required String emptyMsg, bool isActive = false, bool isReturns = false, bool isRequest = false}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(emptyMsg, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final rental = list[index];
        return Card(
          color: context.cardBg,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: context.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rental ID: #${rental.id}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Renter: ${rental.renterName}',
                  style: TextStyle(color: context.textSecondaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${rental.status.name}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (isRequest)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            RentalService().updateRentalStatus(rental.id, RentalStatus.REJECTED);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            RentalService().updateRentalStatus(rental.id, RentalStatus.APPROVED);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                  
                if (isActive && rental.status == RentalStatus.APPROVED)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AssignDeliveryPartnerScreen(rental: rental)));
                      },
                      icon: const Icon(Icons.delivery_dining),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Assign Delivery Partner'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                if (isReturns)
                  Column(
                    children: [
                      if (rental.status == RentalStatus.RETURN_REQUESTED)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // Reject return
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => AssignDeliveryPartnerScreen(rental: rental)));
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Approve & Assign'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (rental.status == RentalStatus.RETURNED)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EquipmentInspectionScreen(rental: rental),
                                ),
                              );
                            },
                            icon: const Icon(Icons.fact_check),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Inspect Equipment'),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
