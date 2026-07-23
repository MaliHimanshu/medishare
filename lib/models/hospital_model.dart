class HospitalModel {
  final String id;
  final String hospitalName;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String phone;
  final String email;
  final String website;
  final String description;
  final String image;
  final String contactPerson;
  final double? latitude;
  final double? longitude;
  final int availableEquipmentCount;
  final int totalDonationsCount;
  final int activeRequestsCount;
  final double rating;
  final String createdAt;
  final String updatedAt;

  const HospitalModel({
    required this.id,
    required this.hospitalName,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
    required this.email,
    required this.website,
    required this.description,
    required this.image,
    required this.contactPerson,
    this.latitude,
    this.longitude,
    required this.availableEquipmentCount,
    required this.totalDonationsCount,
    required this.activeRequestsCount,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    try {
      final lat = json['latitude'] is num ? (json['latitude'] as num).toDouble() : double.tryParse(json['latitude']?.toString() ?? '');
      final lng = json['longitude'] is num ? (json['longitude'] as num).toDouble() : double.tryParse(json['longitude']?.toString() ?? '');

      final equipCount = json['availableEquipment'] is int
          ? json['availableEquipment'] as int
          : int.tryParse(json['availableEquipment']?.toString() ?? '') ?? 12;

      final donationCount = json['donationsReceived'] is int
          ? json['donationsReceived'] as int
          : int.tryParse(json['donationsReceived']?.toString() ?? '') ?? 28;

      final requestCount = json['activeRequests'] is int
          ? json['activeRequests'] as int
          : int.tryParse(json['activeRequests']?.toString() ?? '') ?? 5;

      final ratingVal = json['rating'] is num
          ? (json['rating'] as num).toDouble()
          : double.tryParse(json['rating']?.toString() ?? '') ?? 4.8;

      return HospitalModel(
        id: json['id']?.toString() ?? '',
        hospitalName: json['hospitalName']?.toString() ?? 'Medical Center',
        address: json['address']?.toString() ?? '',
        city: json['city']?.toString() ?? 'City Central',
        state: json['state']?.toString() ?? 'State Region',
        pincode: json['pincode']?.toString() ?? '000000',
        phone: json['phone']?.toString() ?? 'Not Provided',
        email: json['email']?.toString() ?? 'contact@hospital.org',
        website: json['website']?.toString() ?? '',
        description: json['description']?.toString() ?? 'Multi-specialty healthcare facility connected to MediShare Network.',
        image: json['image']?.toString() ?? '',
        contactPerson: json['contactPerson']?.toString() ?? 'Chief Administrator',
        latitude: lat,
        longitude: lng,
        availableEquipmentCount: equipCount,
        totalDonationsCount: donationCount,
        activeRequestsCount: requestCount,
        rating: ratingVal,
        createdAt: json['createdAt']?.toString() ?? '',
        updatedAt: json['updatedAt']?.toString() ?? '',
      );
    } catch (_) {
      return HospitalModel(
        id: json['id']?.toString() ?? 'unknown',
        hospitalName: json['hospitalName']?.toString() ?? 'Medical Facility',
        address: json['address']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        state: json['state']?.toString() ?? '',
        pincode: json['pincode']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        website: '',
        description: 'Healthcare facility connected to MediShare.',
        image: '',
        contactPerson: 'Administrator',
        availableEquipmentCount: 10,
        totalDonationsCount: 20,
        activeRequestsCount: 4,
        rating: 4.8,
        createdAt: '',
        updatedAt: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "hospitalName": hospitalName,
      "address": address,
      "city": city,
      "state": state,
      "pincode": pincode,
      "phone": phone,
      "email": email,
      "website": website,
      "description": description,
      "image": image,
      "contactPerson": contactPerson,
      "latitude": latitude,
      "longitude": longitude,
      "availableEquipment": availableEquipmentCount,
      "donationsReceived": totalDonationsCount,
      "activeRequests": activeRequestsCount,
      "rating": rating,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  HospitalModel copyWith({
    String? id,
    String? hospitalName,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? phone,
    String? email,
    String? website,
    String? description,
    String? image,
    String? contactPerson,
    double? latitude,
    double? longitude,
    int? availableEquipmentCount,
    int? totalDonationsCount,
    int? activeRequestsCount,
    double? rating,
    String? createdAt,
    String? updatedAt,
  }) {
    return HospitalModel(
      id: id ?? this.id,
      hospitalName: hospitalName ?? this.hospitalName,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      description: description ?? this.description,
      image: image ?? this.image,
      contactPerson: contactPerson ?? this.contactPerson,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      availableEquipmentCount: availableEquipmentCount ?? this.availableEquipmentCount,
      totalDonationsCount: totalDonationsCount ?? this.totalDonationsCount,
      activeRequestsCount: activeRequestsCount ?? this.activeRequestsCount,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
