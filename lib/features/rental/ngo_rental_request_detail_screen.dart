import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/rental_model.dart';
import '../../providers/rental_provider.dart';
import 'package:provider/provider.dart';
import '../delivery/assign_delivery_partner_screen.dart';

class NgoRentalRequestDetailScreen extends StatelessWidget {
  final RentalModel rental;

  const NgoRentalRequestDetailScreen({super.key, required this.rental});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Detail'),
        backgroundColor: context.surfaceBg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Equipment: ${rental.equipment?.name ?? "Unknown"}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Recipient: ${rental.renterName}'),
            Text('Phone: ${rental.renterPhone}'),
            const SizedBox(height: 10),
            Text('Rental Period: ${rental.startDate.split("T").first} - ${rental.endDate.split("T").first}'),
            const SizedBox(height: 20),
            const Text('Action:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Handle rejection logic
                      context.read<RentalProvider>().updateRentalStatus(rental.id, 'REJECTED');
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      // Handle approval logic
                      context.read<RentalProvider>().updateRentalStatus(rental.id, 'APPROVED');
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
            if (rental.status == RentalStatus.APPROVED) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AssignDeliveryPartnerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delivery_dining),
                  label: const Text('Assign Delivery Partner'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
