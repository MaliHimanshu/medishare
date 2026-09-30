// Emergency Alert Models
// File: lib/models/emergency_alert_model.dart

class EmergencyAlertHospital {
  final String id;
  final String name;
  final String? organizationName;
  final String? phone;
  final String? address;

  const EmergencyAlertHospital({
    required this.id,
    required this.name,
    this.organizationName,
    this.phone,
    this.address,
  });

  factory EmergencyAlertHospital.fromJson(Map<String, dynamic> json) {
    return EmergencyAlertHospital(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      organizationName: json['organizationName']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
    );
  }

  String get displayName =>
      (organizationName != null && organizationName!.isNotEmpty)
      ? organizationName!
      : name;
}

class EmergencyAlertNgo {
  final String id;
  final String name;
  final String? organizationName;
  final String? phone;
  final String? address;

  const EmergencyAlertNgo({
    required this.id,
    required this.name,
    this.organizationName,
    this.phone,
    this.address,
  });

  factory EmergencyAlertNgo.fromJson(Map<String, dynamic> json) {
    return EmergencyAlertNgo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      organizationName: json['organizationName']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
    );
  }

  String get displayName =>
      (organizationName != null && organizationName!.isNotEmpty)
      ? organizationName!
      : name;
}

class EmergencyAlertResponseModel {
  final String id;
  final String emergencyAlertId;
  final String ngoId;
  final int quantityAvailable;
  final String? message;
  final String status;
  final String createdAt;
  final EmergencyAlertNgo? ngo;

  const EmergencyAlertResponseModel({
    required this.id,
    required this.emergencyAlertId,
    required this.ngoId,
    required this.quantityAvailable,
    this.message,
    required this.status,
    required this.createdAt,
    this.ngo,
  });

  factory EmergencyAlertResponseModel.fromJson(Map<String, dynamic> json) {
    return EmergencyAlertResponseModel(
      id: json['id']?.toString() ?? '',
      emergencyAlertId: json['emergencyAlertId']?.toString() ?? '',
      ngoId: json['ngoId']?.toString() ?? '',
      quantityAvailable: (json['quantityAvailable'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'OFFERED',
      createdAt: json['createdAt']?.toString() ?? '',
      ngo: json['ngo'] != null && json['ngo'] is Map<String, dynamic>
          ? EmergencyAlertNgo.fromJson(json['ngo'] as Map<String, dynamic>)
          : null,
    );
  }
}

class EmergencyAlertModel {
  final String id;
  final String hospitalId;
  final String equipmentName;
  final String? equipmentCategory;
  final int quantityRequired;
  final String? description;
  final String priority; // CRITICAL, HIGH, NORMAL
  final String
  status; // ACTIVE, PARTIALLY_FULFILLED, FULFILLED, CANCELLED, EXPIRED
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? expiresAt;
  final String createdAt;
  final String? updatedAt;
  final EmergencyAlertHospital? hospital;
  final int totalAvailable;
  final int responseCount;
  final EmergencyAlertResponseModel? myResponse;
  final List<EmergencyAlertResponseModel> responses;

  const EmergencyAlertModel({
    required this.id,
    required this.hospitalId,
    required this.equipmentName,
    this.equipmentCategory,
    required this.quantityRequired,
    this.description,
    required this.priority,
    required this.status,
    this.address,
    this.latitude,
    this.longitude,
    this.expiresAt,
    required this.createdAt,
    this.updatedAt,
    this.hospital,
    this.totalAvailable = 0,
    this.responseCount = 0,
    this.myResponse,
    this.responses = const [],
  });

  bool get isCritical => priority.toUpperCase() == 'CRITICAL';
  bool get isHigh => priority.toUpperCase() == 'HIGH';
  bool get isActive =>
      status.toUpperCase() == 'ACTIVE' ||
      status.toUpperCase() == 'PARTIALLY_FULFILLED';
  bool get isFulfilled => status.toUpperCase() == 'FULFILLED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';
  bool get hasResponded => myResponse != null;

  double get fulfillmentPercentage {
    if (quantityRequired <= 0) return 0.0;
    final pct = totalAvailable / quantityRequired;
    return pct > 1.0 ? 1.0 : pct;
  }

  factory EmergencyAlertModel.fromJson(Map<String, dynamic> json) {
    List<EmergencyAlertResponseModel> parsedResponses = [];
    if (json['responses'] != null && json['responses'] is List) {
      parsedResponses = (json['responses'] as List)
          .whereType<Map<String, dynamic>>()
          .map((r) => EmergencyAlertResponseModel.fromJson(r))
          .toList();
    }

    EmergencyAlertResponseModel? myResp;
    if (json['myResponse'] != null &&
        json['myResponse'] is Map<String, dynamic>) {
      myResp = EmergencyAlertResponseModel.fromJson(
        json['myResponse'] as Map<String, dynamic>,
      );
    }

    return EmergencyAlertModel(
      id: json['id']?.toString() ?? '',
      hospitalId: json['hospitalId']?.toString() ?? '',
      equipmentName: json['equipmentName']?.toString() ?? 'Equipment',
      equipmentCategory: json['equipmentCategory']?.toString(),
      quantityRequired: (json['quantityRequired'] as num?)?.toInt() ?? 1,
      description: json['description']?.toString(),
      priority: json['priority']?.toString().toUpperCase() ?? 'HIGH',
      status: json['status']?.toString().toUpperCase() ?? 'ACTIVE',
      address: json['address']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      expiresAt: json['expiresAt']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString(),
      hospital:
          json['hospital'] != null && json['hospital'] is Map<String, dynamic>
          ? EmergencyAlertHospital.fromJson(
              json['hospital'] as Map<String, dynamic>,
            )
          : null,
      totalAvailable: (json['totalAvailable'] as num?)?.toInt() ?? 0,
      responseCount:
          (json['responseCount'] as num?)?.toInt() ?? parsedResponses.length,
      myResponse: myResp,
      responses: parsedResponses,
    );
  }
}
