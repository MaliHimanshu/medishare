import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../services/location_service.dart';
import '../rental/active_rental_screen.dart';
import '../../models/rental_model.dart';
import '../../models/inspection_evidence_model.dart';
import '../../services/delivery_service.dart';
import '../../services/evidence_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String deliveryId;
  final RentalModel rental;

  const OtpVerificationScreen({
    super.key,
    required this.deliveryId,
    required this.rental,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  final _evidenceService = EvidenceService();
  final _imagePicker = ImagePicker();

  List<InspectionEvidenceModel> _uploadedEvidence = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _generateDevOtp();
  }

  Future<void> _generateDevOtp() async {
    try {
      final deliveryService = DeliveryService();
      final result = await deliveryService.generateDeliveryOtp(widget.deliveryId);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result == "SMS Sent" ? 'Delivery OTP sent to recipient via SMS.' : result),
              duration: Duration(seconds: result == "SMS Sent" ? 5 : 15),
              backgroundColor: result == "SMS Sent" ? Colors.green : Colors.orange,
            ),
         );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to generate OTP: $e'), backgroundColor: Colors.red),
         );
      }
    }
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
        rentalId: widget.rental.id,
        equipmentId: widget.rental.equipmentId,
        deliveryId: widget.deliveryId,
        stage: 'DELIVERY',
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

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final deliveryService = DeliveryService();

      await deliveryService.verifyDeliveryOtp(widget.deliveryId, widget.rental.id, otp);

      LocationService().stopTracking();

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery Completed! Rental Active (Firestore Sync).'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveRentalScreen(rental: widget.rental),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Delivery'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            const Icon(Icons.security, size: 64, color: AppColors.primary),
            const SizedBox(height: 20),
            const Text(
              'Enter Delivery OTP',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask the recipient for the 4-digit OTP to complete this delivery.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, letterSpacing: 8),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading ? null : _generateDevOtp,
              child: const Text('Resend OTP via SMS'),
            ),
            const SizedBox(height: 24),
            
            // Delivery Photos
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Delivery Photos (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ..._uploadedEvidence.map((evidence) => _buildPhotoThumbnail(evidence)),
                  _buildAddPhotoButton(),
                ],
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: (_isLoading || _isUploading) ? null : _verifyOtp,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify & Complete Delivery', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
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
