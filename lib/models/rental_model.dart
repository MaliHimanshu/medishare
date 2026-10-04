import 'equipment_model.dart';

enum RentalStatus {
  REQUESTED,
  APPROVED,
  REJECTED,
  PARTNER_ASSIGNED,
  OUT_FOR_PICKUP,
  PICKED_UP,
  DELIVERED,
  ACTIVE,
  RETURN_REQUESTED,
  RETURN_ASSIGNED,
  RETURN_PICKUP,
  RETURNED,
  UNDER_INSPECTION,
  COMPLETED,
  CANCELLED,
  DISPUTED,
}

RentalStatus _parseRentalStatus(String? statusStr) {
  if (statusStr == null) return RentalStatus.REQUESTED;
  try {
    return RentalStatus.values.firstWhere(
        (e) => e.name == statusStr.toUpperCase());
  } catch (_) {
    return RentalStatus.REQUESTED;
  }
}

class RentalModel {
  final String id;
  final String equipmentId;
  final String renterId;
  final String ownerId;
  final String ngoId;
  final String startDate;
  final String expectedReturnDate;
  final String? actualReturnDate;
  final RentalStatus status;
  final bool agreementAccepted;
  final String createdAt;
  final String updatedAt;
  final EquipmentModel? equipment; // kept for convenience

  // Backward compatible fields for UI
  final String endDate;
  final int numberOfDays;
  final double rentalAmount;
  final double securityDeposit;
  final double totalAmount;
  final String paymentStatus;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String renterName;
  final String renterEmail;
  final String renterPhone;

  const RentalModel({
    required this.id,
    required this.equipmentId,
    required this.renterId,
    required this.ownerId,
    required this.ngoId,
    required this.startDate,
    required this.expectedReturnDate,
    this.actualReturnDate,
    required this.status,
    required this.agreementAccepted,
    required this.createdAt,
    required this.updatedAt,
    this.equipment,
    // Backward compatibility
    this.endDate = '',
    this.numberOfDays = 1,
    this.rentalAmount = 0.0,
    this.securityDeposit = 0.0,
    this.totalAmount = 0.0,
    this.paymentStatus = 'PENDING',
    this.razorpayOrderId = '',
    this.razorpayPaymentId = '',
    this.renterName = 'Anonymous',
    this.renterEmail = '',
    this.renterPhone = '',
  });

  factory RentalModel.fromJson(Map<String, dynamic> json) {
    try {
      final equipJson = json['equipment'] is Map
          ? json['equipment'] as Map<String, dynamic>
          : null;
      final equip = equipJson != null ? EquipmentModel.fromJson(equipJson) : null;
      final renterJson = json['renter'] is Map
          ? json['renter'] as Map<String, dynamic>
          : null;

      final startDateStr = json['startDate']?.toString() ?? '';
      final endDateStr = json['endDate']?.toString() ?? json['expectedReturnDate']?.toString() ?? '';

      double parsedRentalAmount = double.tryParse(json['rentalAmount']?.toString() ?? '0') ?? 0.0;
      double parsedSecurityDeposit = double.tryParse(json['securityDeposit']?.toString() ?? '0') ?? 0.0;
      double parsedTotalAmount = double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0;

      final days = int.tryParse(json['numberOfDays']?.toString() ?? '1') ?? 1;

      // Mathematical fallback for rentalAmount if 0 but totalAmount/securityDeposit or equipment rate exists
      if (parsedRentalAmount == 0.0 && parsedTotalAmount > parsedSecurityDeposit) {
        parsedRentalAmount = parsedTotalAmount - parsedSecurityDeposit;
      } else if (parsedRentalAmount == 0.0 && equip != null && equip.rentalPricePerDay != null) {
        parsedRentalAmount = equip.rentalPricePerDay! * days;
      }

      if (parsedTotalAmount == 0.0) {
        parsedTotalAmount = parsedRentalAmount + parsedSecurityDeposit;
      }

      return RentalModel(
        id: json['id']?.toString() ?? '',
        equipmentId: json['equipmentId']?.toString() ?? '',
        renterId: json['renterId']?.toString() ?? renterJson?['id']?.toString() ?? '',
        ownerId: json['ownerId']?.toString() ?? equipJson?['ownerId']?.toString() ?? '',
        ngoId: json['ngoId']?.toString() ?? '',
        startDate: startDateStr,
        expectedReturnDate: endDateStr,
        actualReturnDate: json['actualReturnDate']?.toString(),
        status: _parseRentalStatus(json['status']?.toString()),
        agreementAccepted: json['agreementAccepted'] == true || json['agreementAccepted'] == 'true',
        createdAt: json['createdAt']?.toString() ?? '',
        updatedAt: json['updatedAt']?.toString() ?? '',
        equipment: equip,
        endDate: endDateStr,
        numberOfDays: days,
        rentalAmount: parsedRentalAmount,
        securityDeposit: parsedSecurityDeposit,
        totalAmount: parsedTotalAmount,
        paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
        razorpayOrderId: json['razorpayOrderId']?.toString() ?? '',
        razorpayPaymentId: json['razorpayPaymentId']?.toString() ?? '',
        renterName: renterJson?['name']?.toString() ?? json['renterName']?.toString() ?? 'Anonymous',
        renterEmail: renterJson?['email']?.toString() ?? json['renterEmail']?.toString() ?? '',
        renterPhone: renterJson?['phone']?.toString() ?? json['renterPhone']?.toString() ?? '',
      );
    } catch (_) {
      return RentalModel(
        id: json['id']?.toString() ?? 'unknown',
        equipmentId: '',
        renterId: '',
        ownerId: '',
        ngoId: '',
        startDate: '',
        expectedReturnDate: '',
        status: RentalStatus.REQUESTED,
        agreementAccepted: false,
        createdAt: '',
        updatedAt: '',
        equipment: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "equipmentId": equipmentId,
      "renterId": renterId,
      "ownerId": ownerId,
      "ngoId": ngoId,
      "startDate": startDate,
      "expectedReturnDate": expectedReturnDate,
      "actualReturnDate": actualReturnDate,
      "status": status.name,
      "agreementAccepted": agreementAccepted,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "equipment": equipment?.toJson(),
      "endDate": endDate,
      "numberOfDays": numberOfDays,
      "rentalAmount": rentalAmount,
      "securityDeposit": securityDeposit,
      "totalAmount": totalAmount,
      "paymentStatus": paymentStatus,
      "razorpayOrderId": razorpayOrderId,
      "razorpayPaymentId": razorpayPaymentId,
      "renterName": renterName,
      "renterEmail": renterEmail,
      "renterPhone": renterPhone,
    };
  }

  RentalModel copyWith({
    String? id,
    String? equipmentId,
    String? renterId,
    String? ownerId,
    String? ngoId,
    String? startDate,
    String? expectedReturnDate,
    String? actualReturnDate,
    RentalStatus? status,
    bool? agreementAccepted,
    String? createdAt,
    String? updatedAt,
    EquipmentModel? equipment,
    String? endDate,
    int? numberOfDays,
    double? rentalAmount,
    double? securityDeposit,
    double? totalAmount,
    String? paymentStatus,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? renterName,
    String? renterEmail,
    String? renterPhone,
  }) {
    return RentalModel(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      renterId: renterId ?? this.renterId,
      ownerId: ownerId ?? this.ownerId,
      ngoId: ngoId ?? this.ngoId,
      startDate: startDate ?? this.startDate,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      actualReturnDate: actualReturnDate ?? this.actualReturnDate,
      status: status ?? this.status,
      agreementAccepted: agreementAccepted ?? this.agreementAccepted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      equipment: equipment ?? this.equipment,
      endDate: endDate ?? this.endDate,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      rentalAmount: rentalAmount ?? this.rentalAmount,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      renterName: renterName ?? this.renterName,
      renterEmail: renterEmail ?? this.renterEmail,
      renterPhone: renterPhone ?? this.renterPhone,
    );
  }
}
