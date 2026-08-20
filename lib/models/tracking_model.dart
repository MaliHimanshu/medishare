class TrackingPingModel {
  final String id;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime recordedAt;

  TrackingPingModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    required this.recordedAt,
  });

  factory TrackingPingModel.fromJson(Map<String, dynamic> json) {
    return TrackingPingModel(
      id: json['id']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      accuracy: json['accuracy'] != null ? _toDouble(json['accuracy']) : null,
      speed: json['speed'] != null ? _toDouble(json['speed']) : null,
      heading: json['heading'] != null ? _toDouble(json['heading']) : null,
      recordedAt: DateTime.parse(
        json['recordedAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}

class LiveTrackingSessionModel {
  final String rentalId;
  final String status;
  final bool isTrackingActive;
  final String equipmentId;
  final String equipmentName;
  final String equipmentCategory;
  final double? equipmentLatitude;
  final double? equipmentLongitude;
  final String? equipmentAddress;
  final String renterId;
  final String renterName;
  final String renterPhone;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final TrackingPingModel? latestPing;

  LiveTrackingSessionModel({
    required this.rentalId,
    required this.status,
    required this.isTrackingActive,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentCategory,
    this.equipmentLatitude,
    this.equipmentLongitude,
    this.equipmentAddress,
    required this.renterId,
    required this.renterName,
    required this.renterPhone,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    this.latestPing,
  });

  factory LiveTrackingSessionModel.fromJson(Map<String, dynamic> json) {
    final equip = json['equipment'] is Map ? json['equipment'] as Map<String, dynamic> : <String, dynamic>{};
    final renter = json['renter'] is Map ? json['renter'] as Map<String, dynamic> : <String, dynamic>{};
    final owner = json['owner'] is Map ? json['owner'] as Map<String, dynamic> : <String, dynamic>{};
    final latestJson = json['latest'] is Map ? json['latest'] as Map<String, dynamic> : null;

    return LiveTrackingSessionModel(
      rentalId: json['rentalId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isTrackingActive: json['isTrackingActive'] ?? false,
      equipmentId: equip['id']?.toString() ?? '',
      equipmentName: equip['name']?.toString() ?? '',
      equipmentCategory: equip['category']?.toString() ?? '',
      equipmentLatitude: equip['latitude'] != null ? _toDouble(equip['latitude']) : null,
      equipmentLongitude: equip['longitude'] != null ? _toDouble(equip['longitude']) : null,
      equipmentAddress: equip['address']?.toString(),
      renterId: renter['id']?.toString() ?? '',
      renterName: renter['name']?.toString() ?? '',
      renterPhone: renter['phone']?.toString() ?? '',
      ownerId: owner['id']?.toString() ?? '',
      ownerName: owner['name']?.toString() ?? '',
      ownerPhone: owner['phone']?.toString() ?? '',
      latestPing: latestJson != null ? TrackingPingModel.fromJson({
        'id': 'latest',
        'latitude': latestJson['latitude'],
        'longitude': latestJson['longitude'],
        'recordedAt': latestJson['recordedAt'],
      }) : null,
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
