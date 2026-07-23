import 'equipment_model.dart';

class RequestModel {
  final String id;
  final String equipmentId;
  final String requesterId;
  final String reason;
  final String notes;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String requesterName;
  final String requesterEmail;
  final String hospital;
  final int quantity;
  final EquipmentModel? equipment;

  const RequestModel({
    required this.id,
    required this.equipmentId,
    required this.requesterId,
    required this.reason,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.requesterName,
    required this.requesterEmail,
    required this.hospital,
    required this.quantity,
    this.equipment,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    try {
      final requester = json['requester'] is Map ? json['requester'] as Map<String, dynamic> : null;
      final equipJson = json['equipment'] is Map ? json['equipment'] as Map<String, dynamic> : null;
      final equip = equipJson != null ? EquipmentModel.fromJson(equipJson) : null;

      int parsedQty = 1;
      if (json['quantity'] != null) {
        parsedQty = int.tryParse(json['quantity'].toString()) ?? 1;
      } else if (equip != null) {
        parsedQty = equip.quantity;
      }

      final hospitalName = json['hospital']?.toString() ??
          requester?['hospital']?.toString() ??
          requester?['address']?.toString() ??
          equip?.location ??
          'MediShare Partner Hospital';

      final reasonText = json['reason']?.toString() ??
          equip?.description ??
          'For patient medical care and recovery support.';

      final notesText = json['notes']?.toString() ??
          json['note']?.toString() ??
          'No extra notes.';

      return RequestModel(
        id: json['id']?.toString() ?? '',
        equipmentId: json['equipmentId']?.toString() ?? equipJson?['id']?.toString() ?? '',
        requesterId: json['requesterId']?.toString() ?? requester?['id']?.toString() ?? '',
        reason: reasonText,
        notes: notesText,
        status: json['status']?.toString() ?? 'PENDING',
        createdAt: json['createdAt']?.toString() ?? '',
        updatedAt: json['updatedAt']?.toString() ?? '',
        requesterName: requester?['name']?.toString() ?? 'Anonymous Requester',
        requesterEmail: requester?['email']?.toString() ?? '',
        hospital: hospitalName,
        quantity: parsedQty,
        equipment: equip,
      );
    } catch (_) {
      return RequestModel(
        id: json['id']?.toString() ?? 'unknown',
        equipmentId: json['equipmentId']?.toString() ?? '',
        requesterId: json['requesterId']?.toString() ?? '',
        reason: 'Patient medical care support',
        notes: '',
        status: json['status']?.toString() ?? 'PENDING',
        createdAt: json['createdAt']?.toString() ?? '',
        updatedAt: json['updatedAt']?.toString() ?? '',
        requesterName: 'Anonymous Requester',
        requesterEmail: '',
        hospital: 'MediShare Partner Hospital',
        quantity: 1,
        equipment: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "equipmentId": equipmentId,
      "requesterId": requesterId,
      "reason": reason,
      "notes": notes,
      "status": status,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "requesterName": requesterName,
      "requesterEmail": requesterEmail,
      "hospital": hospital,
      "quantity": quantity,
      "equipment": equipment?.toJson(),
    };
  }

  RequestModel copyWith({
    String? id,
    String? equipmentId,
    String? requesterId,
    String? reason,
    String? notes,
    String? status,
    String? createdAt,
    String? updatedAt,
    String? requesterName,
    String? requesterEmail,
    String? hospital,
    int? quantity,
    EquipmentModel? equipment,
  }) {
    return RequestModel(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      requesterId: requesterId ?? this.requesterId,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      requesterName: requesterName ?? this.requesterName,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      hospital: hospital ?? this.hospital,
      quantity: quantity ?? this.quantity,
      equipment: equipment ?? this.equipment,
    );
  }
}
