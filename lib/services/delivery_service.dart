import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/delivery_model.dart';
import '../core/network/dio_client.dart';

class DeliveryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Dio _dio = DioClient.instance;

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

  String _extractErrorMessage(dynamic data, String defaultMsg) {
    if (data == null) return defaultMsg;
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ?? defaultMsg;
    }
    return data.toString();
  }

  Future<String> generateDeliveryOtp(String deliveryId) async {
    try {
      debugPrint('[DELIVERY OTP DEBUG] BASE URL: ${_dio.options.baseUrl}');
      final requestPath = '/delivery/$deliveryId/otp/generate';
      debugPrint('[DELIVERY OTP DEBUG] REQUEST URL: ${_dio.options.baseUrl}$requestPath');
      
      final response = await _dio.post(requestPath);
      
      debugPrint('[DELIVERY OTP DEBUG] HTTP STATUS: ${response.statusCode}');
      
      final data = response.data;
      if (data is Map<String, dynamic>) {
        debugPrint('[DELIVERY OTP DEBUG] RESPONSE demoMode: ${data['demoMode']}');
        debugPrint('[DELIVERY OTP DEBUG] RESPONSE success: ${data['success']}');
        debugPrint('[DELIVERY OTP DEBUG] RESPONSE message: ${data['message']}');
      }
      
      if (response.statusCode == 200) {
        if (data is Map<String, dynamic> && data['demoMode'] == true) {
          return "DEMO MODE — Delivery OTP: ${data['otp']}";
        }
        return "SMS Sent";
      } else {
        throw Exception(_extractErrorMessage(response.data, 'Failed to send OTP'));
      }
    } catch (e) {
      if (e is DioException) {
        debugPrint('[DELIVERY OTP DEBUG] HTTP STATUS: ${e.response?.statusCode}');
        if (e.response?.data is Map<String, dynamic>) {
           debugPrint('[DELIVERY OTP DEBUG] RESPONSE demoMode: ${e.response?.data['demoMode']}');
           debugPrint('[DELIVERY OTP DEBUG] RESPONSE success: ${e.response?.data['success']}');
           debugPrint('[DELIVERY OTP DEBUG] RESPONSE message: ${e.response?.data['message']}');
        }
        throw Exception(_extractErrorMessage(e.response?.data, e.message ?? 'Network error'));
      }
      throw Exception(e.toString());
    }
  }

  Future<bool> verifyDeliveryOtp(String deliveryId, String rentalId, String enteredOtp) async {
    try {
      final response = await _dio.post(
        '/delivery/$deliveryId/otp/verify',
        data: {
          'otp': enteredOtp,
          'rentalId': rentalId,
        },
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(_extractErrorMessage(response.data, 'Invalid OTP'));
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(_extractErrorMessage(e.response?.data, e.message ?? 'Network error'));
      }
      throw Exception(e.toString());
    }
  }

  Future<void> assignDeliveryPartner(String deliveryId, String partnerId) async {
    final deliveryRef = _db.collection('deliveries').doc(deliveryId);

    await deliveryRef.update({
      'deliveryPartnerId': partnerId,
      'status': DeliveryStatus.ASSIGNED.name.toUpperCase(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<DeliveryModel>> streamDeliveriesByPartner(String partnerId) {
    return _db.collection('deliveries')
        .where('deliveryPartnerId', isEqualTo: partnerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return DeliveryModel.fromJson(data);
            }).toList());
  }

  Stream<List<DeliveryModel>> streamAllDeliveries() {
    return _db.collection('deliveries')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id; // ensure ID is passed
              return DeliveryModel.fromJson(data);
            }).toList());
  }

  Stream<DeliveryModel?> streamDelivery(String deliveryId) {
    return _db.collection('deliveries').doc(deliveryId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return DeliveryModel.fromJson(data);
    });
  }
}
