/// Message échangé entre un utilisateur et un nutritionniste.
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderRole; // user | nutritionist
  final String text;
  final DateTime sentAt;
  bool isRead;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    DateTime? sentAt,
    this.isRead = false,
  }) : sentAt = sentAt ?? DateTime.now();

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        id: map['id'] as String,
        conversationId: map['conversationId'] as String? ?? '',
        senderId: map['senderId'] as String? ?? '',
        senderRole: map['senderRole'] as String? ?? 'user',
        text: map['text'] as String? ?? '',
        sentAt: DateTime.tryParse(map['sentAt'] as String? ?? '') ??
            DateTime.now(),
        isRead: map['isRead'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderRole': senderRole,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
        'isRead': isRead,
      };
}

/// Une conversation entre un utilisateur et un nutritionniste.
class ConversationModel {
  final String id;
  final String userId;
  final String nutritionistId;
  final List<MessageModel> messages;

  ConversationModel({
    required this.id,
    required this.userId,
    required this.nutritionistId,
    List<MessageModel>? messages,
  }) : messages = messages ?? [];

  MessageModel? get lastMessage =>
      messages.isEmpty ? null : messages.last;

  factory ConversationModel.fromMap(Map<String, dynamic> map) =>
      ConversationModel(
        id: map['id'] as String,
        userId: map['userId'] as String? ?? '',
        nutritionistId: map['nutritionistId'] as String? ?? '',
        messages: (map['messages'] as List?)
                ?.map((e) =>
                    MessageModel.fromMap((e as Map).cast<String, dynamic>()))
                .toList() ??
            [],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'nutritionistId': nutritionistId,
        'messages': messages.map((m) => m.toMap()).toList(),
      };
}
