import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_model.dart';

class DeliveryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createRental(DeliveryModel delivery) async {
    await _db.collection('deliveries').doc(delivery.id).set({
      'id': delivery.id,
      'rentalId': delivery.rentalId,
      'deliveryPartnerId': delivery.deliveryPartnerId,
      'ngoId': delivery.ngoId,
      'type': delivery.type.name.toUpperCase(),
      'status': delivery.status.name.toUpperCase(),
      'pickupAddress': delivery.pickupAddress,
      'deliveryAddress': delivery.deliveryAddress,
      'createdAt': delivery.createdAt,
      'updatedAt': delivery.updatedAt,
    });
  }

  Future<DeliveryModel?> getDelivery(String id) async {
    final doc = await _db.collection('deliveries').doc(id).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return DeliveryModel(
        id: data['id'] ?? id,
        rentalId: data['rentalId'] ?? '',
        deliveryPartnerId: data['deliveryPartnerId'] ?? '',
        ngoId: data['ngoId'] ?? '',
        type: DeliveryType.values.firstWhere((e) => e.name == data['type'], orElse: () => DeliveryType.DELIVERY),
        status: DeliveryStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => DeliveryStatus.ASSIGNED),
        pickupAddress: data['pickupAddress'] ?? '',
        deliveryAddress: data['deliveryAddress'] ?? '',
        createdAt: data['createdAt'] ?? '',
        updatedAt: data['updatedAt'] ?? '',
      );
    }
    return null;
  }

  Future<void> updateDeliveryStatus(String deliveryId, DeliveryStatus status) async {
    final Map<String, dynamic> data = {
      'status': status.name.toUpperCase(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (status == DeliveryStatus.DELIVERED) {
      data['deliveredAt'] = DateTime.now().toIso8601String();
    } else if (status == DeliveryStatus.PICKED_UP) {
      data['pickedUpAt'] = DateTime.now().toIso8601String();
    }

    await _db.collection('deliveries').doc(deliveryId).update(data);
  }

  Future<String> generateDeliveryOtp(String deliveryId) async {
    final random = Random.secure();
    final otp = (1000 + random.nextInt(9000)).toString(); // 4 digit secure OTP

    final otpHash = sha256.convert(utf8.encode(otp)).toString();

    await _db.collection('deliveries').doc(deliveryId).update({
      'otpHash': otpHash,
      'otpCreatedAt': DateTime.now().toIso8601String(),
      'otpExpiresAt': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
      'otpAttempts': 0,
      'otpVerified': false,
    });

    return otp; // Return plaintext only to be shown in UI/Logged for dev
  }

  Future<bool> verifyDeliveryOtp(String deliveryId, String rentalId, String enteredOtp) async {
    final deliveryRef = _db.collection('deliveries').doc(deliveryId);
    final rentalRef = _db.collection('rentals').doc(rentalId);

    return await _db.runTransaction((transaction) async {
      final doc = await transaction.get(deliveryRef);
      if (!doc.exists) throw Exception('Delivery not found');

      final data = doc.data()!;
      
      if (data['otpVerified'] == true) {
        throw Exception('OTP already verified');
      }

      final attempts = data['otpAttempts'] ?? 0;
      if (attempts >= 5) {
        throw Exception('Too many attempts. Please request a new OTP.');
      }

      final expiresAtStr = data['otpExpiresAt'];
      if (expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        if (DateTime.now().isAfter(expiresAt)) {
          throw Exception('OTP expired. Please request a new OTP.');
        }
      }

      final storedHash = data['otpHash'];
      final enteredHash = sha256.convert(utf8.encode(enteredOtp)).toString();

      if (storedHash != enteredHash) {
        transaction.update(deliveryRef, {'otpAttempts': attempts + 1});
        throw Exception('Invalid OTP. Please try again.');
      }

      // Atomic Update
      transaction.update(deliveryRef, {
        'status': DeliveryStatus.DELIVERED.name.toUpperCase(),
        'deliveredAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'otpVerified': true,
        'verifiedAt': DateTime.now().toIso8601String(),
      });

      transaction.update(rentalRef, {
        'status': 'ACTIVE',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    });
  }

  Future<void> assignDeliveryPartner(String deliveryId, String partnerId) async {
    final batch = _db.batch();

    final deliveryRef = _db.collection('deliveries').doc(deliveryId);
    final partnerRef = _db.collection('deliveryPartners').doc(partnerId);

    batch.update(deliveryRef, {
      'deliveryPartnerId': partnerId,
      'status': DeliveryStatus.ASSIGNED.name.toUpperCase(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    batch.update(partnerRef, {
      'isAvailable': false,
      'currentDeliveryId': deliveryId,
    });

    await batch.commit();
  }

  Stream<List<DeliveryModel>> streamDeliveriesByPartner(String partnerId) {
    return _db.collection('deliveries')
        .where('deliveryPartnerId', isEqualTo: partnerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return DeliveryModel(
                id: data['id'] ?? doc.id,
                rentalId: data['rentalId'] ?? '',
                deliveryPartnerId: data['deliveryPartnerId'] ?? '',
                ngoId: data['ngoId'] ?? '',
                type: DeliveryType.values.firstWhere((e) => e.name == data['type'], orElse: () => DeliveryType.DELIVERY),
                status: DeliveryStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => DeliveryStatus.ASSIGNED),
                pickupAddress: data['pickupAddress'] ?? '',
                deliveryAddress: data['deliveryAddress'] ?? '',
                createdAt: data['createdAt'] ?? '',
                updatedAt: data['updatedAt'] ?? '',
              );
            }).toList());
  }
}
