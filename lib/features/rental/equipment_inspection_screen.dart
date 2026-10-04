import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../models/rental_model.dart';
import '../../models/inspection_evidence_model.dart';
import '../../services/rental_service.dart';
import '../../services/evidence_service.dart';

class EquipmentInspectionScreen extends StatefulWidget {
  final RentalModel rental;

  const EquipmentInspectionScreen({
    super.key,
    required this.rental,
  });

  @override
  State<EquipmentInspectionScreen> createState() => _EquipmentInspectionScreenState();
}

class _EquipmentInspectionScreenState extends State<EquipmentInspectionScreen> {
  String _afterCondition = 'Good';
  bool _hasDamage = false;
  final _descriptionController = TextEditingController();

  final _rentalService = RentalService();
  final _evidenceService = EvidenceService();
  final _imagePicker = ImagePicker();

  List<InspectionEvidenceModel> _uploadedEvidence = [];
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingEvidence();
  }

  Future<void> _loadExistingEvidence() async {
    setState(() => _isLoading = true);
    try {
      final evidence = await _evidenceService.getEvidenceForRental(widget.rental.id);
      setState(() {
        _uploadedEvidence = evidence.where((e) => e.stage == 'RETURN_INSPECTION').toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load evidence: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70, // Optimize image size
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final File file = File(pickedFile.path);

      final evidence = await _evidenceService.uploadEvidence(
        imageFile: file,
        rentalId: widget.rental.id,
        equipmentId: widget.rental.equipmentId,
        stage: 'RETURN_INSPECTION',
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

  Future<void> _submitInspection() async {
    if (_hasDamage && _uploadedEvidence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one photo showing the damage.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _rentalService.submitInspection(
        rentalId: widget.rental.id,
        equipmentId: widget.rental.equipmentId,
        hasDamage: _hasDamage,
        afterCondition: _afterCondition,
        notes: _descriptionController.text,
      );

      if (!mounted) return;

      if (_hasDamage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspection Completed: Rental DISPUTED, Equipment UNDER_REVIEW (Firestore Sync)'), backgroundColor: Colors.orange),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspection Completed: Rental COMPLETED, Equipment AVAILABLE (Firestore Sync)'), backgroundColor: Colors.green),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Return Inspection'),
        backgroundColor: context.surfaceBg,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Equipment: ${widget.rental.equipment?.name ?? "Unknown"}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.textPrimaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Rental ID: ${widget.rental.id}',
                  style: TextStyle(color: context.textSecondaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Before Condition: ${widget.rental.equipment?.condition ?? "Unknown"}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                
                const SizedBox(height: 24),
                Text(
                  'After Condition:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimaryColor),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _afterCondition,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    fillColor: context.inputBg,
                    filled: true,
                  ),
                  items: ['Excellent', 'Good', 'Fair', 'Damaged']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _afterCondition = val);
                  },
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Damage Reported?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimaryColor),
                    ),
                    const Spacer(),
                    Switch(
                      value: _hasDamage,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _hasDamage = val);
                      },
                    ),
                  ],
                ),

                if (_hasDamage) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    style: TextStyle(color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      labelText: 'Damage Description',
                      border: const OutlineInputBorder(),
                      fillColor: context.inputBg,
                      filled: true,
                    ),
                    maxLines: 3,
                  ),
                ],

                const SizedBox(height: 24),
                Text(
                  'Inspection Photos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimaryColor),
                ),
                const SizedBox(height: 8),
                
                // Photo Gallery
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ..._uploadedEvidence.map((evidence) => _buildPhotoThumbnail(evidence)),
                    _buildAddPhotoButton(),
                  ],
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: (_isUploading || _isLoading) ? null : _submitInspection,
                    style: FilledButton.styleFrom(
                      backgroundColor: _hasDamage ? Colors.orange : AppColors.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _hasDamage ? 'Submit Disputed Inspection' : 'Submit Clean Inspection',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
