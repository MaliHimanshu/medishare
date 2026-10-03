
class InspectionEvidenceModel {
  final String id;
  final String rentalId;
  final String equipmentId;
  final String? deliveryId;
  final String stage; // PICKUP, DELIVERY, RETURN_INSPECTION
  final String storagePath;
  final String downloadUrl;
  final String uploadedBy;
  final String createdAt;

  const InspectionEvidenceModel({
    required this.id,
    required this.rentalId,
    required this.equipmentId,
    this.deliveryId,
    required this.stage,
    required this.storagePath,
    required this.downloadUrl,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory InspectionEvidenceModel.fromJson(Map<String, dynamic> json) {
    return InspectionEvidenceModel(
      id: json['id'] ?? '',
      rentalId: json['rentalId'] ?? '',
      equipmentId: json['equipmentId'] ?? '',
      deliveryId: json['deliveryId'],
      stage: json['stage'] ?? '',
      storagePath: json['storagePath'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      uploadedBy: json['uploadedBy'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rentalId': rentalId,
      'equipmentId': equipmentId,
      'deliveryId': deliveryId,
      'stage': stage,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'uploadedBy': uploadedBy,
      'createdAt': createdAt,
    };
  }
}
