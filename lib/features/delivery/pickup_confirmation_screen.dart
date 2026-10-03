import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../services/evidence_service.dart';
import '../../models/inspection_evidence_model.dart';
import '../../services/delivery_service.dart';
import '../../models/delivery_model.dart';

class PickupConfirmationScreen extends StatefulWidget {
  final String deliveryId;
  final String rentalId;
  final String equipmentId;

  const PickupConfirmationScreen({
    super.key,
    required this.deliveryId,
    required this.rentalId,
    required this.equipmentId,
  });

  @override
  State<PickupConfirmationScreen> createState() => _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen> {
  String _selectedCondition = 'Excellent';
  final _notesController = TextEditingController();

  final _evidenceService = EvidenceService();
  final _imagePicker = ImagePicker();

  List<InspectionEvidenceModel> _uploadedEvidence = [];
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final File file = File(pickedFile.path);

      final evidence = await _evidenceService.uploadEvidence(
        imageFile: file,
        rentalId: widget.rentalId,
        equipmentId: widget.equipmentId,
        deliveryId: widget.deliveryId,
        stage: 'PICKUP',
      );

      setState(() {
        _uploadedEvidence.add(evidence);
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvidence(InspectionEvidenceModel evidence) async {
    try {
      await _evidenceService.deleteEvidence(evidence);
      setState(() {
        _uploadedEvidence.removeWhere((e) => e.id == evidence.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  void _previewImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPickup() async {
    if (_selectedCondition == 'Damaged' && _uploadedEvidence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one photo showing the damage before pickup.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final deliveryService = DeliveryService();
      await deliveryService.updateDeliveryStatus(widget.deliveryId, DeliveryStatus.PICKED_UP);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pickup confirmed successfully! (Firestore Sync)'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm pickup: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Pickup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Equipment Condition',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ['Excellent', 'Good', 'Fair', 'Damaged']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCondition = val);
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Pickup Evidence Photos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // Photo Gallery
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ..._uploadedEvidence.map((evidence) => _buildPhotoThumbnail(evidence)),
                _buildAddPhotoButton(),
              ],
            ),

            const SizedBox(height: 20),
            const Text(
              'Notes (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter any additional notes',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: (_isUploading || _isSubmitting) ? null : _confirmPickup,
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm Pickup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(InspectionEvidenceModel evidence) {
    return GestureDetector(
      onTap: () => _previewImage(evidence.downloadUrl),
      child: Stack(
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade200,
              image: DecorationImage(
                image: NetworkImage(evidence.downloadUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _deleteEvidence(evidence),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _showImagePickerOptions,
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
          color: Colors.grey.shade100,
        ),
        child: _isUploading
            ? const Center(child: CircularProgressIndicator())
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Colors.grey),
                  SizedBox(height: 4),
                  Text('Add Photo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
      ),
    );
  }
}
