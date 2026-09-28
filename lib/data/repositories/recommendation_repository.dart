import '../../core/services/local_store.dart';
import '../models/recommendation_model.dart';

/// Repository des recommandations personnalisées.
class RecommendationRepository {
  RecommendationRepository._();
  static final RecommendationRepository instance =
      RecommendationRepository._();

  final LocalStore _store = LocalStore.instance;

  List<RecommendationModel> _load() => _store
      .readList(StoreKeys.recommendations)
      .map(RecommendationModel.fromMap)
      .toList();

  Future<void> _save(List<RecommendationModel> list) => _store.writeList(
        StoreKeys.recommendations,
        list.map((r) => r.toMap()).toList(),
      );

  List<RecommendationModel> forUser(String userId) {
    final list = _load().where((r) => r.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<RecommendationModel> add({
    required String userId,
    required String title,
    required String body,
    String category = 'nutrition',
    String? authorId,
  }) async {
    final list = _load();
    final rec = RecommendationModel(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      body: body,
      category: category,
      authorId: authorId,
    );
    list.add(rec);
    await _save(list);
    return rec;
  }

  Future<void> markRead(String id) async {
    final list = _load();
    final rec = list.firstWhere((r) => r.id == id);
    rec.isRead = true;
    await _save(list);
  }

  Future<void> delete(String id) async {
    final list = _load()..removeWhere((r) => r.id == id);
    await _save(list);
  }
}
