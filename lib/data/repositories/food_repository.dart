import '../../core/services/local_store.dart';
import '../datasources/food_seed_data.dart';
import '../models/category_model.dart';
import '../models/food_model.dart';

/// Repository des aliments et catégories (seed local + ajouts administrateur).
class FoodRepository {
  FoodRepository._();
  static final FoodRepository instance = FoodRepository._();

  final LocalStore _store = LocalStore.instance;

  bool _seeded = false;

  Future<void> _ensureSeed() async {
    if (_seeded) return;
    final existingFoods = _store.readList(StoreKeys.foods);
    if (existingFoods.isEmpty) {
      await _store.writeList(
        StoreKeys.foods,
        FoodSeedData.foods.map((f) => f.toMap()).toList(),
      );
    }
    final existingCats = _store.readList(StoreKeys.categories);
    if (existingCats.isEmpty) {
      await _store.writeList(
        StoreKeys.categories,
        FoodSeedData.categories.map((c) => c.toMap()).toList(),
      );
    }
    _seeded = true;
  }

  Future<List<FoodModel>> all({bool includeInactive = false}) async {
    await _ensureSeed();
    return _store
        .readList(StoreKeys.foods)
        .map(FoodModel.fromMap)
        .where((f) => includeInactive || f.isActive)
        .toList();
  }

  Future<FoodModel?> byId(String id) async {
    final foods = await all(includeInactive: true);
    for (final f in foods) {
      if (f.id == id) return f;
    }
    return null;
  }

  Future<List<CategoryModel>> categories() async {
    await _ensureSeed();
    return _store.readList(StoreKeys.categories).map(CategoryModel.fromMap).toList();
  }

  /// Recherche par nom (insensible à la casse) et catégorie optionnelle.
  Future<List<FoodModel>> search(String query, {String? categoryId}) async {
    final foods = await all();
    final q = query.trim().toLowerCase();
    return foods.where((f) {
      final matchQuery =
          q.isEmpty || f.name.toLowerCase().contains(q);
      final matchCategory =
          categoryId == null || categoryId.isEmpty || f.categoryId == categoryId;
      return matchQuery && matchCategory;
    }).toList();
  }

  Future<void> save(FoodModel food) async {
    await _ensureSeed();
    final foods = await all(includeInactive: true);
    final index = foods.indexWhere((f) => f.id == food.id);
    if (index == -1) {
      foods.add(food);
    } else {
      foods[index] = food;
    }
    await _store.writeList(
      StoreKeys.foods,
      foods.map((f) => f.toMap()).toList(),
    );
  }

  /// Désactivation logique (un aliment référencé ne doit pas être supprimé).
  Future<void> setActive(String id, bool active) async {
    final food = await byId(id);
    if (food == null) return;
    food.isActive = active;
    await save(food);
  }

  Future<void> delete(String id) async {
    final foods = await all(includeInactive: true);
    foods.removeWhere((f) => f.id == id);
    await _store.writeList(
      StoreKeys.foods,
      foods.map((f) => f.toMap()).toList(),
    );
  }

  Future<void> saveCategory(CategoryModel category) async {
    await _ensureSeed();
    final cats = await categories();
    final index = cats.indexWhere((c) => c.id == category.id);
    if (index == -1) {
      cats.add(category);
    } else {
      cats[index] = category;
    }
    await _store.writeList(
      StoreKeys.categories,
      cats.map((c) => c.toMap()).toList(),
    );
  }

  Future<void> deleteCategory(String id) async {
    final cats = await categories();
    cats.removeWhere((c) => c.id == id);
    await _store.writeList(
      StoreKeys.categories,
      cats.map((c) => c.toMap()).toList(),
    );
  }
}
