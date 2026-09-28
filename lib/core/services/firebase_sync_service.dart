import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_bootstrap.dart';
import 'local_store.dart';

import '../../data/repositories/food_repository.dart';

/// Réplique les collections locales vers Firestore et recharge les données
/// Firebase utiles à la session courante. Firestore reste la base distante.
class FirebaseSyncService {
  FirebaseSyncService._();
  static final instance = FirebaseSyncService._();
  FirebaseFirestore get db => FirebaseFirestore.instance;

  Future<void> syncStoreList(String key, List<Map<String, dynamic>> rows) async {
    if (!FirebaseBootstrap.ready || FirebaseAuth.instance.currentUser == null) return;
    final collection = _collectionForKey(key);
    if (collection == null) return;
    final batch = db.batch();
    for (final row in rows) {
      final id = row['id']?.toString();
      if (id == null || id.isEmpty) continue;
      batch.set(db.collection(collection).doc(id), _shape(collection, row), SetOptions(merge: true));
    }
    try { await batch.commit(); } catch (_) {}
  }

  Future<void> pullForCurrentAccount({required String role}) async {
    if (!FirebaseBootstrap.ready || FirebaseAuth.instance.currentUser == null) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      var localFoods = LocalStore.instance.readList(StoreKeys.foods);
      if (localFoods.isEmpty) {
        await FoodRepository.instance.all();
        localFoods = LocalStore.instance.readList(StoreKeys.foods);
      }
      if (localFoods.isNotEmpty) {
        await syncStoreList(StoreKeys.foods, localFoods);
      }
      var localCats = LocalStore.instance.readList(StoreKeys.categories);
      if (localCats.isNotEmpty) {
        await syncStoreList(StoreKeys.categories, localCats);
      }
      await _pullCollection('foods', StoreKeys.foods);
      await _pullCollection('categories', StoreKeys.categories);
      await _pullWhere('meals', StoreKeys.meals, 'userId', uid);
      await _pullWhere('weightEntries', StoreKeys.weights, 'userId', uid);
      await _pullWhere('nutritionGoals', StoreKeys.goals, 'userId', uid);
      await _pullWhere('nutritionPlans', StoreKeys.mealPlans, 'patientId', uid);
      await _pullWhere('recommendations', StoreKeys.recommendations, 'userId', uid);
      await _pullWhere('notifications', StoreKeys.notifications, 'userId', uid);
      await _pullWhere('conversations', StoreKeys.conversations, 'userId', uid);
      if (role == 'admin') {
        await _pullCollection('users', StoreKeys.accounts, transform: (m) => {
          'id': m['id'], 'email': m['email'] ?? '', 'role': m['role'] ?? 'user',
          'passwordHash': '', 'profile': m,
        });
        await _pullCollection('activityLogs', StoreKeys.activityLogs);
        await _pullCollection('meals', StoreKeys.meals);
      }
    } catch (_) {}
    await LocalStore.instance.writeString('vitatrack_last_firebase_sync', DateTime.now().toIso8601String());
  }

  Future<void> _pullCollection(String collection, String key, {Map<String,dynamic> Function(Map<String,dynamic>)? transform}) async {
    final snap = await db.collection(collection).get();
    if (snap.docs.isEmpty) return;
    final rows = snap.docs.map((d) {
      final m = <String,dynamic>{'id': d.id, ...d.data()};
      return transform == null ? m : transform(m);
    }).toList();
    await LocalStore.instance.writeList(key, rows, syncFirebase: false);
  }

  Future<void> _pullWhere(String collection, String key, String field, String value) async {
    final snap = await db.collection(collection).where(field, isEqualTo: value).get();
    if (snap.docs.isEmpty) return;
    final rows = snap.docs.map((d) => <String,dynamic>{'id': d.id, ...d.data()}).toList();
    await LocalStore.instance.writeList(key, rows, syncFirebase: false);
  }

  String? _collectionForKey(String key) => switch (key) {
    StoreKeys.foods => 'foods', StoreKeys.categories => 'categories', StoreKeys.meals => 'meals',
    StoreKeys.weights => 'weightEntries', StoreKeys.goals => 'nutritionGoals',
    StoreKeys.mealPlans => 'nutritionPlans', StoreKeys.recommendations => 'recommendations',
    StoreKeys.notifications => 'notifications', StoreKeys.conversations => 'conversations',
    StoreKeys.activityLogs => 'activityLogs', _ => null,
  };

  Map<String,dynamic> _shape(String collection, Map<String,dynamic> row) {
    final out = Map<String,dynamic>.from(row);
    if (collection == 'foods') {
      final f = (row['per100g'] as Map?)?.cast<String,dynamic>() ?? {};
      out.addAll({'calories': f['calories'] ?? 0, 'protein': f['proteins'] ?? 0, 'carbs': f['carbs'] ?? 0, 'fat': f['fats'] ?? 0, 'servingUnit': '100 g', 'country': 'Cameroun'});
    } else if (collection == 'meals') {
      final totals = _mealTotals(row['items']);
      out.addAll({'mealType': row['type'] ?? '', 'mealDate': row['date'], 'foods': row['items'] ?? [], 'totalCalories': totals[0], 'totalProtein': totals[1], 'totalCarbs': totals[2], 'totalFat': totals[3]});
    } else if (collection == 'weightEntries') {
      out['entryDate'] = row['date'];
    } else if (collection == 'nutritionPlans') {
      out.addAll({'userId': row['patientId'], 'status': row['isActive'] == true ? 'active' : 'inactive', 'objective': row['description'] ?? ''});
    } else if (collection == 'recommendations') {
      out.addAll({'content': row['body'] ?? '', 'nutritionistId': row['authorId'], 'type': row['category'] ?? 'nutrition'});
    } else if (collection == 'notifications') {
      out['read'] = row['isRead'] ?? false;
      out['scheduledAt'] ??= row['createdAt'];
    } else if (collection == 'activityLogs') {
      out.addAll({'targetId': row['target'] ?? '', 'description': row['action'] ?? ''});
    }
    out['updatedAt'] = FieldValue.serverTimestamp();
    return out;
  }

  List<double> _mealTotals(dynamic items) {
    double c=0,p=0,carb=0,f=0;
    if (items is List) for (final raw in items) {
      if (raw is! Map) continue;
      final q=(raw['quantityG'] as num?)?.toDouble() ?? 100;
      final facts=(raw['per100g'] as Map?)?.cast<String,dynamic>() ?? {};
      final k=q/100;
      c+=((facts['calories'] as num?)?.toDouble() ?? 0)*k;
      p+=((facts['proteins'] as num?)?.toDouble() ?? 0)*k;
      carb+=((facts['carbs'] as num?)?.toDouble() ?? 0)*k;
      f+=((facts['fats'] as num?)?.toDouble() ?? 0)*k;
    }
    return [c,p,carb,f];
  }
}
