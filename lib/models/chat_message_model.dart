import 'equipment_model.dart';

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

enum ChatMessageType {
  text,
  menu,
  equipmentList,
  radiusPicker,
  requestList,
  trackingList,
  hospitalList,
  successNotice,
  helpInfo,
}

class ChatMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final MessageStatus status;
  final ChatMessageType messageType;
  final List<EquipmentModel>? equipmentList;
  final List<String>? options;
  final Map<String, dynamic>? customData;
  final bool showMainMenuButton;

  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.status = MessageStatus.read,
    this.messageType = ChatMessageType.text,
    this.equipmentList,
    this.options,
    this.customData,
    this.showMainMenuButton = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isError': isError,
      'status': status.name,
      'messageType': messageType.name,
      'showMainMenuButton': showMainMenuButton,
      if (options != null) 'options': options,
      if (customData != null) 'customData': customData,
      if (equipmentList != null)
        'equipmentList': equipmentList!.map((e) => e.toJson()).toList(),
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    List<EquipmentModel>? parsedEquip;
    if (json['equipmentList'] is List) {
      parsedEquip = (json['equipmentList'] as List)
          .map((item) => EquipmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    List<String>? parsedOptions;
    if (json['options'] is List) {
      parsedOptions =
          (json['options'] as List).map((e) => e.toString()).toList();
    }

    MessageStatus parsedStatus = MessageStatus.read;
    if (json['status'] != null) {
      parsedStatus = MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.read,
      );
    }

    ChatMessageType parsedType = ChatMessageType.text;
    if (json['messageType'] != null) {
      parsedType = ChatMessageType.values.firstWhere(
        (t) => t.name == json['messageType'],
        orElse: () => ChatMessageType.text,
      );
    }

    return ChatMessageModel(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text']?.toString() ?? '',
      isUser: json['isUser'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isError: json['isError'] as bool? ?? false,
      status: parsedStatus,
      messageType: parsedType,
      equipmentList: parsedEquip,
      options: parsedOptions,
      customData: json['customData'] as Map<String, dynamic>?,
      showMainMenuButton: json['showMainMenuButton'] as bool? ?? false,
    );
  }

  ChatMessageModel copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isError,
    MessageStatus? status,
    ChatMessageType? messageType,
    List<EquipmentModel>? equipmentList,
    List<String>? options,
    Map<String, dynamic>? customData,
    bool? showMainMenuButton,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
      status: status ?? this.status,
      messageType: messageType ?? this.messageType,
      equipmentList: equipmentList ?? this.equipmentList,
      options: options ?? this.options,
      customData: customData ?? this.customData,
      showMainMenuButton: showMainMenuButton ?? this.showMainMenuButton,
    );
  }
}

class ChatConversationModel {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastTimestamp;
  final int unreadCount;
  final bool isOnline;
  final bool isSupport;
  final String category;

  const ChatConversationModel({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastTimestamp,
    this.unreadCount = 0,
    this.isOnline = true,
    this.isSupport = false,
    this.category = 'Support',
  });
}
