enum DeliveryType {
  PICKUP,
  DELIVERY,
  RETURN_PICKUP
}

enum DeliveryStatus {
  ASSIGNED,
  GOING_TO_PICKUP,
  PICKED_UP,
  IN_TRANSIT,
  ARRIVING,
  DELIVERED,
  CANCELLED,
  COMPLETED
}

DeliveryType _parseDeliveryType(String? val) {
  if (val == null) return DeliveryType.DELIVERY;
  try {
    return DeliveryType.values.firstWhere((e) => e.name == val.toUpperCase());
  } catch (_) {
    return DeliveryType.DELIVERY;
  }
}

DeliveryStatus _parseDeliveryStatus(String? val) {
  if (val == null) return DeliveryStatus.ASSIGNED;
  try {
    return DeliveryStatus.values.firstWhere((e) => e.name == val.toUpperCase());
  } catch (_) {
    return DeliveryStatus.ASSIGNED;
  }
}

class DeliveryModel {
  final String id;
  final String rentalId;
  final String deliveryPartnerId;
  final String ngoId;
  final DeliveryType type;
  final DeliveryStatus status;
  final String pickupAddress;
  final String deliveryAddress;
  final String? startedAt;
  final String? pickedUpAt;
  final String? deliveredAt;
  final String? estimatedArrival;
  final String createdAt;
  final String updatedAt;

  const DeliveryModel({
    required this.id,
    required this.rentalId,
    required this.deliveryPartnerId,
    required this.ngoId,
    required this.type,
    required this.status,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.startedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.estimatedArrival,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id']?.toString() ?? '',
      rentalId: json['rentalId']?.toString() ?? '',
      deliveryPartnerId: json['deliveryPartnerId']?.toString() ?? '',
      ngoId: json['ngoId']?.toString() ?? '',
      type: _parseDeliveryType(json['type']?.toString()),
      status: _parseDeliveryStatus(json['status']?.toString()),
      pickupAddress: json['pickupAddress']?.toString() ?? '',
      deliveryAddress: json['deliveryAddress']?.toString() ?? '',
      startedAt: json['startedAt']?.toString(),
      pickedUpAt: json['pickedUpAt']?.toString(),
      deliveredAt: json['deliveredAt']?.toString(),
      estimatedArrival: json['estimatedArrival']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rentalId': rentalId,
      'deliveryPartnerId': deliveryPartnerId,
      'ngoId': ngoId,
      'type': type.name,
      'status': status.name,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'startedAt': startedAt,
      'pickedUpAt': pickedUpAt,
      'deliveredAt': deliveredAt,
      'estimatedArrival': estimatedArrival,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
