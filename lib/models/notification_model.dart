class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String module;
  final bool isRead;
  final String createdAt;
  final String updatedAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.module,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    try {
      final titleText = json['title']?.toString() ?? 'Alert';
      final msgText = json['message']?.toString() ?? '';
      final rawType = json['type']?.toString().toUpperCase() ?? 'GENERAL';

      // Infer module based on title, message, or type
      String parsedModule = 'Announcement';
      final lowerTitle = titleText.toLowerCase();
      final lowerMsg = msgText.toLowerCase();

      if (rawType == 'DONATION' || lowerTitle.contains('donat') || lowerMsg.contains('donat')) {
        parsedModule = 'Donations';
      } else if (rawType == 'REQUEST' || lowerTitle.contains('request') || lowerMsg.contains('request')) {
        parsedModule = 'Requests';
      } else if (lowerTitle.contains('hospital') || lowerMsg.contains('hospital')) {
        parsedModule = 'Hospitals';
      } else if (lowerTitle.contains('equipment') || lowerMsg.contains('equipment')) {
        parsedModule = 'Equipment';
      } else if (lowerTitle.contains('ai') || lowerTitle.contains('chat') || lowerMsg.contains('ai')) {
        parsedModule = 'AI';
      }

      return NotificationModel(
        id: json['id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        title: titleText,
        message: msgText,
        type: rawType,
        module: json['module']?.toString() ?? parsedModule,
        isRead: json['isRead'] as bool? ?? false,
        createdAt: json['createdAt']?.toString() ?? '',
        updatedAt: json['updatedAt']?.toString() ?? '',
      );
    } catch (_) {
      return NotificationModel(
        id: json['id']?.toString() ?? 'unknown',
        userId: '',
        title: 'System Notification',
        message: 'No message content.',
        type: 'GENERAL',
        module: 'Announcement',
        isRead: false,
        createdAt: '',
        updatedAt: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "title": title,
      "message": message,
      "type": type,
      "module": module,
      "isRead": isRead,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? module,
    bool? isRead,
    String? createdAt,
    String? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      module: module ?? this.module,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
