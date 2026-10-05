import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/inspection_evidence_model.dart';
import 'image_upload_service.dart';

class EvidenceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<InspectionEvidenceModel> uploadEvidence({
    required File imageFile,
    required String rentalId,
    required String equipmentId,
    String? deliveryId,
    required String stage,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Unauthorized');
    }

    final String evidenceId = const Uuid().v4();

    // Upload to Cloudinary via backend (same flow as equipment images)
    final String downloadUrl = await ImageUploadService.instance.uploadImage(imageFile);

    // 2. Create Firestore Record
    final evidence = InspectionEvidenceModel(
      id: evidenceId,
      rentalId: rentalId,
      equipmentId: equipmentId,
      deliveryId: deliveryId,
      stage: stage,
      storagePath: 'cloudinary',
      downloadUrl: downloadUrl,
      uploadedBy: currentUser.uid,
      createdAt: DateTime.now().toIso8601String(),
    );

    final docRef = _db.collection('evidence').doc(evidenceId);
    print('[FIRESTORE WRITE] Path: ${docRef.path}');
    await docRef.set(evidence.toJson());

    return evidence;
  }

  Future<List<InspectionEvidenceModel>> getEvidenceForRental(String rentalId) async {
    final snapshot = await _db.collection('evidence').where('rentalId', isEqualTo: rentalId).get();
    return snapshot.docs.map((doc) => InspectionEvidenceModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteEvidence(InspectionEvidenceModel evidence) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != evidence.uploadedBy) {
      throw Exception('Unauthorized to delete this evidence');
    }

    // Note: Cloudinary deletion requires backend call with public_id.
    // For now, we only delete the Firestore record.
    // TODO: Call DELETE /api/upload/:publicId when implemented.
    await _db.collection('evidence').doc(evidence.id).delete();
  }
}
