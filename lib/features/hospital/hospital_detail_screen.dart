import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/hospital_model.dart';
import '../../providers/hospital_provider.dart';
import '../../shared/widgets/ms_image.dart';
import 'edit_hospital_screen.dart';

class HospitalDetailScreen extends StatefulWidget {
  final dynamic hospital; // Accepts HospitalModel or Map<String, dynamic>

  const HospitalDetailScreen({
    super.key,
    required this.hospital,
  });

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
      _currentHospital = HospitalModel.fromJson(widget.hospital as Map<String, dynamic>);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Hospital?'),
          ],
        ),
        content: Text('Are you sure you want to delete "${_currentHospital.hospitalName}" from the MediShare network?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              Navigator.pop(ctx);

              final success = await provider.deleteHospital(_currentHospital.id);

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
                      content: Text(provider.errorMessage.isNotEmpty
                          ? provider.errorMessage
                          : 'Failed to delete hospital.'),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hospital Details'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: _openEditScreen,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Registration ID: #${h.id.isNotEmpty ? h.id : 'MS-HOSP-001'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade300),
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
                          color: Colors.black87,
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
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Equipment', h.availableEquipmentCount.toString(), Icons.medical_services_outlined, Colors.teal),
                  Container(height: 30, width: 1, color: Colors.grey.shade300),
                  _buildStatItem('Donations', h.totalDonationsCount.toString(), Icons.volunteer_activism_outlined, Colors.pink),
                  Container(height: 30, width: 1, color: Colors.grey.shade300),
                  _buildStatItem('Requests', h.activeRequestsCount.toString(), Icons.assignment_outlined, Colors.orange),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Facility Information Card
            Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade50,
                      child: const Icon(Icons.location_on, color: Colors.red),
                    ),
                    title: const Text('Full Address'),
                    subtitle: Text('${h.address}, ${h.city}, ${h.state} - ${h.pincode}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: const Icon(Icons.phone, color: Colors.green),
                    ),
                    title: const Text('Phone Number'),
                    subtitle: Text(h.phone.isNotEmpty ? h.phone : 'Not Provided'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.email, color: Colors.blue),
                    ),
                    title: const Text('Email Address'),
                    subtitle: Text(h.email.isNotEmpty ? h.email : 'Not Provided'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade50,
                      child: const Icon(Icons.person, color: Colors.purple),
                    ),
                    title: const Text('Contact Person'),
                    subtitle: Text(h.contactPerson),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade50,
                      child: const Icon(Icons.language, color: Colors.indigo),
                    ),
                    title: const Text('Website'),
                    subtitle: Text(h.website.isNotEmpty ? h.website : 'None listed'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade50,
                      child: const Icon(Icons.calendar_month, color: Colors.teal),
                    ),
                    title: const Text('Joined Date'),
                    subtitle: Text(h.createdAt.isNotEmpty ? h.createdAt.split('T').first : 'Recently Joined'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Description Header & Body
            const Text(
              'Facility Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  h.description.isNotEmpty ? h.description : 'No description provided for this healthcare center.',
                  style: const TextStyle(fontSize: 14, height: 1.4),
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
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Facility'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}