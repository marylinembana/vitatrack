import '../../core/services/local_store.dart';
import '../models/weight_record_model.dart';

/// Repository du suivi de poids.
class WeightRepository {
  WeightRepository._();
  static final WeightRepository instance = WeightRepository._();

  final LocalStore _store = LocalStore.instance;

  List<WeightRecordModel> _load() => _store
      .readList(StoreKeys.weights)
      .map(WeightRecordModel.fromMap)
      .toList();

  Future<void> _save(List<WeightRecordModel> list) => _store.writeList(
        StoreKeys.weights,
        list.map((w) => w.toMap()).toList(),
      );

  /// Historique trié du plus récent au plus ancien.
  List<WeightRecordModel> history(String userId) {
    final list = _load().where((w) => w.userId == userId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  WeightRecordModel? latest(String userId) {
    final h = history(userId);
    return h.isEmpty ? null : h.first;
  }

  Future<WeightRecordModel> add({
    required String userId,
    required double weightKg,
    DateTime? date,
    String? note,
  }) async {
    final list = _load();
    final record = WeightRecordModel(
      id: 'weight_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      weightKg: weightKg,
      date: date,
      note: note,
    );
    list.add(record);
    await _save(list);
    return record;
  }

  Future<void> delete(String id) async {
    final list = _load()..removeWhere((w) => w.id == id);
    await _save(list);
  }
}
