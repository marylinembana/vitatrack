import '../../core/services/local_store.dart';
import '../models/message_model.dart';

/// Repository des conversations utilisateur ↔ nutritionniste.
class MessageRepository {
  MessageRepository._();
  static final MessageRepository instance = MessageRepository._();

  final LocalStore _store = LocalStore.instance;

  List<ConversationModel> _load() => _store
      .readList(StoreKeys.conversations)
      .map(ConversationModel.fromMap)
      .toList();

  Future<void> _save(List<ConversationModel> list) => _store.writeList(
        StoreKeys.conversations,
        list.map((c) => c.toMap()).toList(),
      );

  /// Conversations impliquant un compte (côté utilisateur ou nutritionniste).
  List<ConversationModel> forAccount(String accountId) {
    final list = _load()
        .where((c) => c.userId == accountId || c.nutritionistId == accountId)
        .toList();
    list.sort((a, b) {
      final da = a.lastMessage?.sentAt ?? DateTime(2000);
      final db = b.lastMessage?.sentAt ?? DateTime(2000);
      return db.compareTo(da);
    });
    return list;
  }

  ConversationModel? byId(String conversationId) {
    final list = _load().where((c) => c.id == conversationId);
    return list.isEmpty ? null : list.first;
  }

  /// Retrouve ou crée la conversation entre un patient et son nutritionniste.
  Future<ConversationModel> openConversation({
    required String userId,
    required String nutritionistId,
  }) async {
    final list = _load();
    final existing = list
        .where((c) => c.userId == userId && c.nutritionistId == nutritionistId)
        .toList();
    if (existing.isNotEmpty) return existing.first;
    final conversation = ConversationModel(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      nutritionistId: nutritionistId,
    );
    list.add(conversation);
    await _save(list);
    return conversation;
  }

  Future<void> send({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String text,
  }) async {
    final list = _load();
    final conversation =
        list.firstWhere((c) => c.id == conversationId);
    conversation.messages.add(MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      senderRole: senderRole,
      text: text,
    ));
    await _save(list);
  }

  Future<void> markConversationRead(
      String conversationId, String readerId) async {
    final list = _load();
    final conversation =
        list.firstWhere((c) => c.id == conversationId);
    for (final m in conversation.messages) {
      if (m.senderId != readerId) m.isRead = true;
    }
    await _save(list);
  }
}
