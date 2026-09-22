/// User model matching the backend Prisma schema
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final bool phoneVerified;
  final String? address;
  final String? profileImage;
  final String? organizationName;
  final String? registrationNumber;
  final String? contactPerson;
  final String? equipmentPreference;
  final String verificationStatus;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.phoneVerified = false,
    this.address,
    this.profileImage,
    this.organizationName,
    this.registrationNumber,
    this.contactPerson,
    this.equipmentPreference,
    this.verificationStatus = 'VERIFIED',
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:                  json['id']?.toString() ?? '',
      name:                json['name']?.toString() ?? '',
      email:               json['email']?.toString() ?? '',
      role:                json['role']?.toString() ?? 'DONOR',
      phone:               json['phone']?.toString(),
      phoneVerified:       json['phoneVerified'] == true,
      address:             json['address']?.toString(),
      profileImage:        json['profileImage']?.toString(),
      organizationName:    json['organizationName']?.toString(),
      registrationNumber:  json['registrationNumber']?.toString(),
      contactPerson:       json['contactPerson']?.toString(),
      equipmentPreference: json['equipmentPreference']?.toString(),
      verificationStatus:  json['verificationStatus']?.toString() ?? 'VERIFIED',
      createdAt:           json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':                  id,
    'name':                name,
    'email':               email,
    'role':                role,
    'phone':               phone,
    'phoneVerified':       phoneVerified,
    'address':             address,
    'profileImage':        profileImage,
    'organizationName':    organizationName,
    'registrationNumber':  registrationNumber,
    'contactPerson':       contactPerson,
    'equipmentPreference': equipmentPreference,
    'verificationStatus':  verificationStatus,
    'createdAt':           createdAt.toIso8601String(),
  };

  /// Avatar initial letter
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'U';

  /// Pretty role label
  String get roleLabel {
    switch (role) {
      case 'ADMIN':     return 'Administrator';
      case 'DONOR':     return 'Donor';
      case 'NGO':       return 'NGO Partner';
      case 'HOSPITAL':  return 'Hospital';
      case 'RECIPIENT': return 'Recipient';
      default:          return role;
    }
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email, role: $role)';
}