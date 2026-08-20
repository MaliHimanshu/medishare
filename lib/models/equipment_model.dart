class EquipmentModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String location;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int quantity;
  final String status;
  final String mode; // DONATE, RENT, BOTH
  final double? rentalPricePerDay;
  final double? securityDeposit;
  final String donor;
  final String condition;
  final String manufacturer;
  final String image;
  final List<String> images;
  final String ownerId;
  final String createdAt;
  final String updatedAt;

  EquipmentModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    this.address,
    this.latitude,
    this.longitude,
    required this.quantity,
    required this.status,
    required this.mode,
    this.rentalPricePerDay,
    this.securityDeposit,
    required this.donor,
    required this.condition,
    required this.manufacturer,
    required this.image,
    required this.images,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;

    // Extract images array safely
    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
    }

    final addr = json['address']?.toString() ??
        json['location']?.toString() ??
        owner?['address']?.toString();

    return EquipmentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: addr ?? 'MediShare Network',
      address: addr,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
      status: json['status']?.toString() ?? 'AVAILABLE',
      mode: json['mode']?.toString() ?? 'DONATE',
      rentalPricePerDay: _parseDouble(json['rentalPricePerDay']),
      securityDeposit: _parseDouble(json['securityDeposit']),
      donor: owner?['name']?.toString() ??
          json['donor']?.toString() ??
          'Anonymous',
      condition: json['condition']?.toString() ?? 'GOOD',
      manufacturer:
          json['manufacturer']?.toString() ?? 'Standard Manufacturer',
      image: json['image']?.toString() ?? '',
      images: parsedImages,
      ownerId: json['ownerId']?.toString() ?? owner?['id']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'location': location,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'quantity': quantity,
      'status': status,
      'mode': mode,
      'rentalPricePerDay': rentalPricePerDay,
      'securityDeposit': securityDeposit,
      'donor': donor,
      'condition': condition,
      'manufacturer': manufacturer,
      'image': image,
      'images': images,
      'ownerId': ownerId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}