import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/hospital_model.dart';
import '../../providers/hospital_provider.dart';
import '../../shared/widgets/ms_image.dart';
import 'edit_hospital_screen.dart';

class HospitalDetailScreen extends StatefulWidget {
  final dynamic hospital; // Accepts HospitalModel or Map<String, dynamic>

  const HospitalDetailScreen({super.key, required this.hospital});

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen> {
  late HospitalModel _currentHospital;

  @override
  void initState() {
    super.initState();
    if (widget.hospital is HospitalModel) {
      _currentHospital = widget.hospital as HospitalModel;
    } else if (widget.hospital is Map<String, dynamic>) {
      _currentHospital = HospitalModel.fromJson(
        widget.hospital as Map<String, dynamic>,
      );
    } else {
      _currentHospital = const HospitalModel(
        id: '',
        hospitalName: 'Hospital Facility',
        address: '',
        city: '',
        state: '',
        pincode: '',
        phone: '',
        email: '',
        website: '',
        description: '',
        image: '',
        contactPerson: 'Administrator',
        availableEquipmentCount: 12,
        totalDonationsCount: 28,
        activeRequestsCount: 5,
        rating: 4.8,
        createdAt: '',
        updatedAt: '',
      );
    }
  }

  void _openEditScreen() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditHospitalScreen(hospital: _currentHospital),
      ),
    );

    if (updated == true && mounted) {
      final provider = context.read<HospitalProvider>();
      setState(() {
        _currentHospital = provider.hospitals.firstWhere(
          (h) => h.id == _currentHospital.id,
          orElse: () => _currentHospital,
        );
      });
    }
  }

  void _confirmDelete() {
    final provider = context.read<HospitalProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.borderColor),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 10),
            Text(
              'Delete Hospital?',
              style: TextStyle(color: context.textPrimaryColor),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_currentHospital.hospitalName}" from the MediShare network?',
          style: TextStyle(color: context.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.textSecondaryColor),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              Navigator.pop(ctx);

              final success = await provider.deleteHospital(
                _currentHospital.id,
              );

              if (mounted) {
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Hospital deleted successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  navigator.pop(true);
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage.isNotEmpty
                            ? provider.errorMessage
                            : 'Failed to delete hospital.',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = _currentHospital;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Hospital Details',
          style: TextStyle(color: context.textPrimaryColor),
        ),
        centerTitle: true,
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: _openEditScreen,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Header
            Hero(
              tag: 'hospital_logo_${h.id}',
              child: MsImage(
                imageUrl: h.image,
                width: double.infinity,
                height: 180,
                borderRadius: BorderRadius.circular(20),
                placeholderIcon: Icons.local_hospital,
              ),
            ),

            const SizedBox(height: 20),

            // Title & Rating Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.hospitalName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Registration ID: #${h.id.isNotEmpty ? h.id : 'MS-HOSP-001'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        h.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Stats 3-Column Banner
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 14,
              ),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    'Equipment',
                    h.availableEquipmentCount.toString(),
                    Icons.medical_services_outlined,
                    Colors.teal,
                  ),
                  Container(height: 30, width: 1, color: context.borderColor),
                  _buildStatItem(
                    context,
                    'Donations',
                    h.totalDonationsCount.toString(),
                    Icons.volunteer_activism_outlined,
                    Colors.pinkAccent,
                  ),
                  Container(height: 30, width: 1, color: context.borderColor),
                  _buildStatItem(
                    context,
                    'Requests',
                    h.activeRequestsCount.toString(),
                    Icons.assignment_outlined,
                    Colors.orange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Facility Information Card
            Card(
              elevation: 0,
              color: context.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.withValues(alpha: 0.15),
                      child: const Icon(Icons.location_on, color: Colors.redAccent),
                    ),
                    title: Text(
                      'Full Address',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    subtitle: Text(
                      '${h.address}, ${h.city}, ${h.state} - ${h.pincode}',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: context.borderColor),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      child: const Icon(Icons.phone, color: Colors.green),
                    ),
                    title: Text(
                      'Phone Number',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    subtitle: Text(
                      h.phone.isNotEmpty ? h.phone : 'Not Provided',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: context.borderColor),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withValues(alpha: 0.15),
                      child: const Icon(Icons.email, color: AppColors.primary),
                    ),
                    title: Text(
                      'Email Address',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    subtitle: Text(
                      h.email.isNotEmpty ? h.email : 'Not Provided',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: context.borderColor),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.withValues(alpha: 0.15),
                      child: const Icon(Icons.person, color: Colors.purpleAccent),
                    ),
                    title: Text(
                      'Contact Person',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    subtitle: Text(
                      h.contactPerson,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: context.borderColor),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.withValues(alpha: 0.15),
                      child: const Icon(Icons.language, color: Colors.indigoAccent),
                    ),
                    title: Text(
                      'Website',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    subtitle: Text(
                      h.website.isNotEmpty ? h.website : 'None listed',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: context.borderColor),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.calendar_month,
                        color: Colors.teal,
                      ),
                    ),
                    title: Text(
                      'Joined Date',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    subtitle: Text(
                      h.createdAt.isNotEmpty
                          ? h.createdAt.split('T').first
                          : 'Recently Joined',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Description Header & Body
            Text(
              'Facility Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: context.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: context.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  h.description.isNotEmpty
                      ? h.description
                      : 'No description provided for this healthcare center.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openEditScreen,
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    label: const Text('Edit Facility'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: context.textPrimaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

