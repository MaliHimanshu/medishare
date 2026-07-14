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
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      location: json['location'],
      quantity: json['quantity'],
      status: json['status'],
      donor: json['donor'],
      condition: json['condition'],
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
    };
  }
}