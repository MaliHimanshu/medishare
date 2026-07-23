import 'equipment_model.dart';

class DonationModel {
  final String id;
  final String donorId;
  final String equipmentId;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String donorName;
  final String donorEmail;
  final String hospital;
  final String notes;
  final int quantity;
  final EquipmentModel? equipment;

  const DonationModel({
    required this.id,
    required this.donorId,
    required this.equipmentId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.donorName,
    required this.donorEmail,
    required this.hospital,
    required this.notes,
    required this.quantity,
    this.equipment,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    try {
      final donor = json['donor'] is Map ? json['donor'] as Map<String, dynamic> : null;
      final equipJson = json['equipment'] is Map ? json['equipment'] as Map<String, dynamic> : null;
      final equip = equipJson != null ? EquipmentModel.fromJson(equipJson) : null;

      int parsedQty = 1;
      if (json['quantity'] != null) {
        parsedQty = int.tryParse(json['quantity'].toString()) ?? 1;
      } else if (equip != null) {
        parsedQty = equip.quantity;
      }

      final hospitalName = json['hospital']?.toString() ??
          donor?['hospital']?.toString() ??
          donor?['address']?.toString() ??
          equip?.location ??
          'MediShare Partner Hospital';

      final notesText = json['notes']?.toString() ??
          json['note']?.toString() ??
          equip?.description ??
          'No additional notes provided.';

      return DonationModel(
        id: json['id']?.toString() ?? '',
        donorId: json['donorId']?.toString() ?? donor?['id']?.toString() ?? '',
        equipmentId: json['equipmentId']?.toString() ?? equipJson?['id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'PENDING',
        createdAt: json['createdAt']?.toString() ?? '',
        updatedAt: json['updatedAt']?.toString() ?? '',
        donorName: donor?['name']?.toString() ?? 'Anonymous Donor',
        donorEmail: donor?['email']?.toString() ?? '',
        hospital: hospitalName,
        notes: notesText,
        quantity: parsedQty,
        equipment: equip,
      );
    } catch (_) {
      return DonationModel(
        id: json['id']?.toString() ?? 'unknown',
        donorId: json['donorId']?.toString() ?? '',
        equipmentId: json['equipmentId']?.toString() ?? '',
        status: json['status']?.toString() ?? 'PENDING',
        createdAt: json['createdAt']?.toString() ?? '',
        updatedAt: json['updatedAt']?.toString() ?? '',
        donorName: 'Anonymous Donor',
        donorEmail: '',
        hospital: 'MediShare Partner Hospital',
        notes: 'No notes provided.',
        quantity: 1,
        equipment: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "donorId": donorId,
      "equipmentId": equipmentId,
      "status": status,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "donorName": donorName,
      "donorEmail": donorEmail,
      "hospital": hospital,
      "notes": notes,
      "quantity": quantity,
      "equipment": equipment?.toJson(),
    };
  }

  DonationModel copyWith({
    String? id,
    String? donorId,
    String? equipmentId,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? donorName,
    String? donorEmail,
    String? hospital,
    String? notes,
    int? quantity,
    EquipmentModel? equipment,
  }) {
    return DonationModel(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      equipmentId: equipmentId ?? this.equipmentId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      donorName: donorName ?? this.donorName,
      donorEmail: donorEmail ?? this.donorEmail,
      hospital: hospital ?? this.hospital,
      notes: notes ?? this.notes,
      quantity: quantity ?? this.quantity,
      equipment: equipment ?? this.equipment,
    );
  }
}
