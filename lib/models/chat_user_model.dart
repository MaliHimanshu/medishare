class ChatUser {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final String role;

  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.role,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImage: json['profileImage'] as String?,
      role: json['role'] as String? ?? 'DONOR',
    );
  }
}
