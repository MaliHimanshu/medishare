/// User model matching the backend Prisma schema
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final String? profileImage;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
    this.profileImage,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:        json['id']?.toString() ?? '',
      name:      json['name']?.toString() ?? '',
      email:     json['email']?.toString() ?? '',
      role:      json['role']?.toString() ?? 'DONOR',
      phone:     json['phone']?.toString(),
      address:   json['address']?.toString(),
      profileImage: json['profileImage']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':           id,
    'name':         name,
    'email':        email,
    'role':         role,
    'phone':        phone,
    'address':      address,
    'profileImage': profileImage,
    'createdAt':    createdAt.toIso8601String(),
  };

  /// Avatar initial letter
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'U';

  /// Pretty role label
  String get roleLabel {
    switch (role) {
      case 'ADMIN':     return 'Administrator';
      case 'DONOR':     return 'Donor';
      case 'NGO':       return 'NGO Partner';
      case 'RECIPIENT': return 'Healthcare Recipient';
      default:          return role;
    }
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email, role: $role)';
}