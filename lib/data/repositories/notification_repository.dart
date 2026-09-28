import '../../core/services/local_store.dart';
import '../models/notification_model.dart';

/// Repository des notifications in-app.
class NotificationRepository {
  NotificationRepository._();
  static final NotificationRepository instance = NotificationRepository._();

  final LocalStore _store = LocalStore.instance;

  List<NotificationModel> _load() => _store
      .readList(StoreKeys.notifications)
      .map(NotificationModel.fromMap)
      .toList();

  Future<void> _save(List<NotificationModel> list) => _store.writeList(
        StoreKeys.notifications,
        list.map((n) => n.toMap()).toList(),
      );

  List<NotificationModel> forUser(String userId) {
    final list = _load().where((n) => n.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int unreadCount(String userId) =>
      forUser(userId).where((n) => !n.isRead).length;

  Future<NotificationModel> add({
    required String userId,
    required String title,
    required String body,
    String type = 'system',
  }) async {
    final list = _load();
    final notification = NotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      body: body,
      type: type,
    );
    list.add(notification);
    await _save(list);
    return notification;
  }

  Future<void> markRead(String id) async {
    final list = _load();
    final index = list.indexWhere((n) => n.id == id);
    if (index != -1) {
      list[index].isRead = true;
      await _save(list);
    }
  }

  Future<void> markAllRead(String userId) async {
    final list = _load();
    for (final n in list.where((n) => n.userId == userId)) {
      n.isRead = true;
    }
    await _save(list);
  }

  Future<void> delete(String id) async {
    final list = _load()..removeWhere((n) => n.id == id);
    await _save(list);
  }
}
