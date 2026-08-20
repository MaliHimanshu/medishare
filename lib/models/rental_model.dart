import 'equipment_model.dart';

class RentalModel {
  final String id;
  final String equipmentId;
  final String renterId;
  final String startDate;
  final String endDate;
  final int numberOfDays;
  final double rentalAmount;
  final double securityDeposit;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String createdAt;
  final String updatedAt;
  final String renterName;
  final String renterEmail;
  final String renterPhone;
  final EquipmentModel? equipment;

  const RentalModel({
    required this.id,
    required this.equipmentId,
    required this.renterId,
    required this.startDate,
    required this.endDate,
    required this.numberOfDays,
    required this.rentalAmount,
    required this.securityDeposit,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.createdAt,
    required this.updatedAt,
    required this.renterName,
    required this.renterEmail,
    required this.renterPhone,
    this.equipment,
  });

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  factory RentalModel.fromJson(Map<String, dynamic> json) {
    try {
      final renter = json['renter'] is Map ? json['renter'] as Map<String, dynamic> : null;
      final equipJson = json['equipment'] is Map ? json['equipment'] as Map<String, dynamic> : null;
      final equip = equipJson != null ? EquipmentModel.fromJson(equipJson) : null;

      int parsedDays = 1;
      if (json['numberOfDays'] != null) {
        parsedDays = int.tryParse(json['numberOfDays'].toString()) ?? 1;
      }

      return RentalModel(
        id: json['id']?.toString() ?? '',
        equipmentId: json['equipmentId']?.toString() ?? equipJson?['id']?.toString() ?? '',
        renterId: json['renterId']?.toString() ?? renter?['id']?.toString() ?? '',
        startDate: json['startDate']?.toString() ?? '',
        endDate: json['endDate']?.toString() ?? '',
        numberOfDays: parsedDays,
        rentalAmount: _parseDouble(json['rentalAmount']),
        securityDeposit: _parseDouble(json['securityDeposit']),
        totalAmount: _parseDouble(json['totalAmount']),
        status: json['status']?.toString() ?? 'PENDING',
        paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
        razorpayOrderId: json['razorpayOrderId']?.toString(),
        razorpayPaymentId: json['razorpayPaymentId']?.toString(),
        createdAt: json['createdAt']?.toString() ?? '',
        updatedAt: json['updatedAt']?.toString() ?? '',
        renterName: renter?['name']?.toString() ?? 'Anonymous Renter',
        renterEmail: renter?['email']?.toString() ?? '',
        renterPhone: renter?['phone']?.toString() ?? '',
        equipment: equip,
      );
    } catch (_) {
      return RentalModel(
        id: json['id']?.toString() ?? 'unknown',
        equipmentId: json['equipmentId']?.toString() ?? '',
        renterId: json['renterId']?.toString() ?? '',
        startDate: json['startDate']?.toString() ?? '',
        endDate: json['endDate']?.toString() ?? '',
        numberOfDays: 1,
        rentalAmount: 0.0,
        securityDeposit: 0.0,
        totalAmount: 0.0,
        status: 'PENDING',
        paymentStatus: 'PENDING',
        createdAt: '',
        updatedAt: '',
        renterName: 'Anonymous Renter',
        renterEmail: '',
        renterPhone: '',
        equipment: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "equipmentId": equipmentId,
      "renterId": renterId,
      "startDate": startDate,
      "endDate": endDate,
      "numberOfDays": numberOfDays,
      "rentalAmount": rentalAmount,
      "securityDeposit": securityDeposit,
      "totalAmount": totalAmount,
      "status": status,
      "paymentStatus": paymentStatus,
      "razorpayOrderId": razorpayOrderId,
      "razorpayPaymentId": razorpayPaymentId,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "renterName": renterName,
      "renterEmail": renterEmail,
      "renterPhone": renterPhone,
      "equipment": equipment?.toJson(),
    };
  }

  RentalModel copyWith({
    String? id,
    String? equipmentId,
    String? renterId,
    String? startDate,
    String? endDate,
    int? numberOfDays,
    double? rentalAmount,
    double? securityDeposit,
    double? totalAmount,
    String? status,
    String? paymentStatus,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? createdAt,
    String? updatedAt,
    String? renterName,
    String? renterEmail,
    String? renterPhone,
    EquipmentModel? equipment,
  }) {
    return RentalModel(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      renterId: renterId ?? this.renterId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      rentalAmount: rentalAmount ?? this.rentalAmount,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      renterName: renterName ?? this.renterName,
      renterEmail: renterEmail ?? this.renterEmail,
      renterPhone: renterPhone ?? this.renterPhone,
      equipment: equipment ?? this.equipment,
    );
  }
}
