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
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Request Detail'),
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Equipment: ${rental.equipment?.name ?? "Unknown"}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              'Recipient: ${rental.renterName}',
              style: TextStyle(color: context.textSecondaryColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Phone: ${rental.renterPhone}',
              style: TextStyle(color: context.textSecondaryColor),
            ),
            const SizedBox(height: 10),
            Text(
              'Rental Period: ${rental.startDate.split("T").first} - ${rental.endDate.split("T").first}',
              style: TextStyle(color: context.textSecondaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Action:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<RentalProvider>().updateRentalStatus(rental.id, 'REJECTED');
                      Navigator.pop(context);
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
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      context.read<RentalProvider>().updateRentalStatus(rental.id, 'APPROVED');
                      Navigator.pop(context);
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
            ]
          ],
        ),
      ),
    );
  }
}
