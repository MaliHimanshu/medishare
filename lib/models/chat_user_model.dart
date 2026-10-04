class ChatUser {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final String role;
  final String? phone;
  final String? verificationStatus;
  final String? createdAt;

  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.role,
    this.phone,
    this.verificationStatus,
    this.createdAt,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      role: json['role']?.toString() ?? 'USER',
      phone: json['phone']?.toString(),
      verificationStatus: json['verificationStatus']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}
