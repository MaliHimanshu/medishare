import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental_model.dart';

class RentalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createRental(RentalModel rental) async {
    // Basic mapping since toJson might not exist
    await _db.collection('rentals').doc(rental.id).set({
      'id': rental.id,
      'equipmentId': rental.equipmentId,
      'renterId': rental.renterId,
      'ownerId': rental.ownerId,
      'ngoId': rental.ngoId,
      'startDate': rental.startDate,
      'expectedReturnDate': rental.expectedReturnDate,
      'status': rental.status.name.toUpperCase(),
    });
  }

  Future<RentalModel?> getRental(String id) async {
    final doc = await _db.collection('rentals').doc(id).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      // Assuming basic reconstruction to satisfy the return type safely.
      return RentalModel(
        id: data['id'] ?? id,
        equipmentId: data['equipmentId'] ?? '',
        renterId: data['renterId'] ?? '',
        ownerId: data['ownerId'] ?? '',
        ngoId: data['ngoId'] ?? '',
        startDate: data['startDate'] ?? '',
        expectedReturnDate: data['expectedReturnDate'] ?? '',
        status: RentalStatus.values.firstWhere(
            (e) => e.name == data['status'],
            orElse: () => RentalStatus.REQUESTED,
        ),
        agreementAccepted: data['agreementAccepted'] ?? true,
        createdAt: data['createdAt'] ?? '',
        updatedAt: data['updatedAt'] ?? '',
      );
    }
    return null;
  }

  Future<void> updateRentalStatus(String rentalId, RentalStatus status) async {
    await _db.collection('rentals').doc(rentalId).update({
      'status': status.name.toUpperCase(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> submitInspection({
    required String rentalId,
    required String equipmentId,
    required bool hasDamage,
    required String afterCondition,
    required String notes,
  }) async {
    final batch = _db.batch();
    
    final rentalRef = _db.collection('rentals').doc(rentalId);
    final equipmentRef = _db.collection('equipment').doc(equipmentId);

    if (hasDamage) {
      batch.update(rentalRef, {
        'status': RentalStatus.DISPUTED.name.toUpperCase(),
        'updatedAt': DateTime.now().toIso8601String(),
        'inspectionCondition': afterCondition,
        'inspectionNotes': notes,
        'hasDamage': true,
      });
      batch.update(equipmentRef, {
        'status': 'UNDER_REVIEW', // Using string as EquipmentStatus might not be defined the same way
        'condition': afterCondition,
      });
    } else {
      batch.update(rentalRef, {
        'status': RentalStatus.COMPLETED.name.toUpperCase(),
        'updatedAt': DateTime.now().toIso8601String(),
        'inspectionCondition': afterCondition,
        'inspectionNotes': notes,
        'hasDamage': false,
      });
      batch.update(equipmentRef, {
        'status': 'AVAILABLE',
        'condition': afterCondition,
      });
    }

    await batch.commit();
  }

  Stream<List<RentalModel>> streamRentalsByNgo(String ngoId) {
    return _db.collection('rentals')
        .where('ngoId', isEqualTo: ngoId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return RentalModel(
                id: data['id'] ?? doc.id,
                equipmentId: data['equipmentId'] ?? '',
                renterId: data['renterId'] ?? '',
                ownerId: data['ownerId'] ?? '',
                ngoId: data['ngoId'] ?? '',
                startDate: data['startDate'] ?? '',
                expectedReturnDate: data['expectedReturnDate'] ?? '',
                status: RentalStatus.values.firstWhere(
                  (e) => e.name == data['status'],
                  orElse: () => RentalStatus.REQUESTED,
                ),
                agreementAccepted: data['agreementAccepted'] ?? true,
                createdAt: data['createdAt'] ?? '',
                updatedAt: data['updatedAt'] ?? '',
                renterName: data['renterName'] ?? 'Unknown Renter',
              );
            }).toList());
  }
}
