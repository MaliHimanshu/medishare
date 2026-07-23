class EquipmentModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String location;
  final int quantity;
  final String status;
  final String donor;
  final String condition;
  final String manufacturer;
  final String image;
  final String ownerId;
  final String createdAt;
  final String updatedAt;

  EquipmentModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    required this.quantity,
    required this.status,
    required this.donor,
    required this.condition,
    required this.manufacturer,
    required this.image,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    
    return EquipmentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? owner?['address']?.toString() ?? 'MediShare Network',
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
      status: json['status']?.toString() ?? 'AVAILABLE',
      donor: owner?['name']?.toString() ?? json['donor']?.toString() ?? 'Anonymous',
      condition: json['condition']?.toString() ?? 'GOOD',
      manufacturer: json['manufacturer']?.toString() ?? 'Standard Manufacturer',
      image: json['image']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? owner?['id']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "category": category,
      "description": description,
      "location": location,
      "quantity": quantity,
      "status": status,
      "donor": donor,
      "condition": condition,
      "manufacturer": manufacturer,
      "image": image,
      "ownerId": ownerId,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }
}