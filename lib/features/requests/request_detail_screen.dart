import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/request_model.dart';
import '../../providers/request_provider.dart';
import '../../shared/widgets/ms_image.dart';
import 'edit_request_dialog.dart';

class RequestDetailScreen extends StatefulWidget {
  final RequestModel request;

  const RequestDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late RequestModel _currentRequest;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'COMPLETED':
        return Colors.blue;
      case 'REJECTED':
      case 'CANCELLED':
        return Colors.red;
      case 'PENDING':
      default:
        return Colors.orange;
    }
  }

  bool get _isPending => _currentRequest.status.toUpperCase() == 'PENDING';

  void _showStatusDialog() {
    final requestProvider = context.read<RequestProvider>();
    String selectedStatus = _currentRequest.status.toUpperCase();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Request Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['PENDING', 'APPROVED', 'REJECTED', 'COMPLETED']
                        .map((st) {
                      final isSelected = selectedStatus == st;
                      final color = _getStatusColor(st);
                      return ChoiceChip(
                        label: Text(st),
                        selected: isSelected,
                        selectedColor: color.withAlpha(50),
                        labelStyle: TextStyle(
                          color: isSelected ? color : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => selectedStatus = st);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        navigator.pop();

                        final success = await requestProvider
                            .updateRequestStatus(_currentRequest.id, selectedStatus);

                        if (mounted) {
                          if (success) {
                            setState(() {
                              _currentRequest = requestProvider.requests
                                  .firstWhere((r) => r.id == _currentRequest.id,
                                      orElse: () => _currentRequest.copyWith(status: selectedStatus));
                            });
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Request status updated!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(requestProvider.errorMessage.isNotEmpty
                                    ? requestProvider.errorMessage
                                    : 'Failed to update status.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Confirm Status Update',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openEditDialog() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => EditRequestDialog(request: _currentRequest),
    );

    if (updated == true && mounted) {
      final provider = context.read<RequestProvider>();
      setState(() {
        _currentRequest = provider.requests.firstWhere(
          (r) => r.id == _currentRequest.id,
          orElse: () => _currentRequest,
        );
      });
    }
  }

  void _confirmDelete() {
    final requestProvider = context.read<RequestProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Request?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this equipment request? This action cannot be undone.',
        ),
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

              final success =
                  await requestProvider.deleteRequest(_currentRequest.id);

              if (mounted) {
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Request deleted successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  navigator.pop(true);
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(requestProvider.errorMessage.isNotEmpty
                          ? requestProvider.errorMessage
                          : 'Failed to delete request.'),
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
    final equip = _currentRequest.equipment;
    final statusColor = _getStatusColor(_currentRequest.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Request Details'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Equipment Image
            Hero(
              tag: 'request_image_${_currentRequest.id}',
              child: MsImage(
                imageUrl: equip?.image,
                width: double.infinity,
                height: 200,
                borderRadius: BorderRadius.circular(20),
                placeholderIcon: Icons.medical_services_outlined,
              ),
            ),

            const SizedBox(height: 20),

            // Title, ID & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equip?.name ?? 'Requested Equipment',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Request ID: #${_currentRequest.id}',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withAlpha(100)),
                  ),
                  child: Text(
                    _currentRequest.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Information Grid Card
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
                      backgroundColor: Colors.purple.shade50,
                      child: const Icon(Icons.category, color: Colors.purple),
                    ),
                    title: const Text('Category'),
                    subtitle: Text(equip?.category ?? 'General Medical'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade50,
                      child: const Icon(Icons.numbers, color: Colors.orange),
                    ),
                    title: const Text('Requested Quantity'),
                    subtitle: Text('${_currentRequest.quantity} units'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.person, color: Colors.blue),
                    ),
                    title: const Text('Requester'),
                    subtitle: Text(_currentRequest.requesterName),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade50,
                      child: const Icon(Icons.local_hospital, color: Colors.red),
                    ),
                    title: const Text('Hospital / NGO Location'),
                    subtitle: Text(_currentRequest.hospital),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade50,
                      child: const Icon(Icons.calendar_today,
                          color: Colors.indigo),
                    ),
                    title: const Text('Request Date'),
                    subtitle: Text(_currentRequest.createdAt.isNotEmpty
                        ? _currentRequest.createdAt.split('T').first
                        : 'Recently'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Purpose & Reason Card
            const Text(
              'Purpose of Request',
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
                  _currentRequest.reason.isNotEmpty
                      ? _currentRequest.reason
                      : 'No explicit reason provided.',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Additional Notes Card
            const Text(
              'Additional Notes',
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
                  _currentRequest.notes.isNotEmpty
                      ? _currentRequest.notes
                      : 'No additional notes attached.',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Actions Row
            Row(
              children: [
                if (_isPending) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openEditDialog,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showStatusDialog,
                    icon: const Icon(Icons.sync_alt),
                    label: const Text('Status'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
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
}