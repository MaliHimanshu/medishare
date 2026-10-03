enum VehicleType {
  BIKE,
  CAR,
  VAN,
  OTHER
}

VehicleType _parseVehicleType(String? val) {
  if (val == null) return VehicleType.OTHER;
  try {
    return VehicleType.values.firstWhere((e) => e.name == val.toUpperCase());
  } catch (_) {
    return VehicleType.OTHER;
  }
}

class DeliveryPartnerModel {
  final String id;
  final String userId;
  final String ngoId;
  final String fullName;
  final String phone;
  final String profilePhoto;
  final VehicleType vehicleType;
  final String vehicleNumber;
  final bool isAvailable;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? lastLocationUpdate;
  final String createdAt;

  const DeliveryPartnerModel({
    required this.id,
    required this.userId,
    required this.ngoId,
    required this.fullName,
    required this.phone,
    required this.profilePhoto,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.isAvailable,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    required this.createdAt,
  });

  factory DeliveryPartnerModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      ngoId: json['ngoId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      profilePhoto: json['profilePhoto']?.toString() ?? '',
      vehicleType: _parseVehicleType(json['vehicleType']?.toString()),
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      isAvailable: json['isAvailable'] == true || json['isAvailable'] == 'true',
      currentLatitude: json['currentLatitude'] != null ? double.tryParse(json['currentLatitude'].toString()) : null,
      currentLongitude: json['currentLongitude'] != null ? double.tryParse(json['currentLongitude'].toString()) : null,
      lastLocationUpdate: json['lastLocationUpdate']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'ngoId': ngoId,
      'fullName': fullName,
      'phone': phone,
      'profilePhoto': profilePhoto,
      'vehicleType': vehicleType.name,
      'vehicleNumber': vehicleNumber,
      'isAvailable': isAvailable,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'lastLocationUpdate': lastLocationUpdate,
      'createdAt': createdAt,
    };
  }
}
