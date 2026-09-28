import '../../core/services/local_store.dart';
import '../../core/utils/date_utils.dart';
import '../models/meal_item_model.dart';
import '../models/meal_plan_model.dart';
import '../models/nutrition_goal_model.dart';
import '../models/weight_record_model.dart';
import 'food_seed_data.dart';

/// Insère des données de démonstration au premier lancement pour le compte
/// `user@vitatrack.app` (poids, repas, objectif, plan, notifications,
/// conversation), afin que l'application soit présentable immédiatement.
class DemoSeeder {
  DemoSeeder._();

  static const demoUserId = 'acc_demo_user';
  static const demoNutritionistId = 'acc_demo_nutritionist';

  static Future<void> seedIfFirstRun() async {
    final store = LocalStore.instance;
    if (store.hasKey(StoreKeys.seeded)) return;

    // --- Catalogue initial camerounais ---
    await store.writeList(StoreKeys.foods, FoodSeedData.foods.map((f) => f.toMap()).toList());
    await store.writeList(StoreKeys.categories, FoodSeedData.categories.map((c) => c.toMap()).toList());

    // --- Poids : tendance à la baisse sur 30 jours ---
    final weights = <Map<String, dynamic>>[];
    for (var i = 0; i < 10; i++) {
      final date = DateTime.now().subtract(Duration(days: 27 - i * 3));
      weights.add(WeightRecordModel(
        id: 'weight_demo_$i',
        userId: demoUserId,
        weightKg: 68.4 - i * 0.45,
        date: date,
      ).toMap());
    }
    await store.writeList(StoreKeys.weights, weights);

    // --- Objectif actif ---
    await store.writeList(StoreKeys.goals, [
      NutritionGoalModel(
        id: 'goal_demo',
        userId: demoUserId,
        calorieTarget: 1650,
        proteinTargetG: 124,
        carbTargetG: 186,
        fatTargetG: 46,
      ).toMap(),
    ]);

    // --- Repas des 4 derniers jours ---
    final meals = <Map<String, dynamic>>[];
    final plan = [
      ['Petit-déjeuner', 'food_avoine', 200, 'food_lait', 150],
      ['Déjeuner', 'food_tchep', 250, 'food_poisson', 150],
      ['Dîner', 'food_ateke', 200, 'food_sauce_gombo', 200],
    ];
    var mealIndex = 0;
    for (var d = 3; d >= 0; d--) {
      final day = DateTime.now().subtract(Duration(days: d));
      for (final entry in plan) {
        final time = DateTime(day.year, day.month, day.day,
            entry[0] == 'Petit-déjeuner' ? 7 : entry[0] == 'Déjeuner' ? 13 : 20);
        meals.add({
          'id': 'meal_demo_${mealIndex++}',
          'userId': demoUserId,
          'type': entry[0],
          'date': time.toIso8601String(),
          'items': [
            _item(entry[1] as String, entry[2] as double),
            _item(entry[3] as String, entry[4] as double),
          ],
        });
      }
    }
    await store.writeList(StoreKeys.meals, meals);

    // --- Notifications ---
    await store.writeList(StoreKeys.notifications, [
      {
        'id': 'notif_demo_1',
        'userId': demoUserId,
        'title': 'Rappel : déjeuner',
        'body': 'N\'oubliez pas d\'enregistrer votre déjeuner.',
        'type': 'reminder',
        'createdAt':
            DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        'isRead': false,
      },
      {
        'id': 'notif_demo_2',
        'userId': demoUserId,
        'title': 'Nouveau plan alimentaire',
        'body': 'Dr. Adjovi a partagé un plan avec vous.',
        'type': 'plan',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'isRead': false,
      },
      {
        'id': 'notif_demo_3',
        'userId': demoUserId,
        'title': 'Bravo !',
        'body': 'Objectif atteind sur 3 des 7 derniers jours.',
        'type': 'system',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'isRead': true,
      },
    ]);

    // --- Plan alimentaire du nutritionniste ---
    final nutritionistPlans = <Map<String, dynamic>>[
      MealPlanModel(
        id: 'plan_demo_1',
        nutritionistId: demoNutritionistId,
        patientId: demoUserId,
        title: 'Semaine équilibrée — perte de poids',
        description: 'Déjeuner léger, dîner sans féculent raffiné, '
            '2 L d\'eau par jour.',
        startDate: DateUtils.dateOnly(DateTime.now()),
        entries: [
          MealPlanEntry(
              mealType: 'Petit-déjeuner',
              foodId: 'food_avoine',
              foodName: 'Flocons d\'avoine cuits',
              quantityG: 200),
          MealPlanEntry(
              mealType: 'Déjeuner',
              foodId: 'food_riz_blanc',
              foodName: 'Riz blanc cuit',
              quantityG: 150),
          MealPlanEntry(
              mealType: 'Déjeuner',
              foodId: 'food_poisson',
              foodName: 'Poisson grillé (tilapia)',
              quantityG: 150),
          MealPlanEntry(
              mealType: 'Dîner',
              foodId: 'food_sauce_gombo',
              foodName: 'Sauce gombo au poisson',
              quantityG: 200),
        ],
      ).toMap(),
    ];
    await store.writeList(StoreKeys.mealPlans, nutritionistPlans);

    // --- Conversation ---
    await store.writeList(StoreKeys.conversations, [
      {
        'id': 'conv_demo_1',
        'userId': demoUserId,
        'nutritionistId': demoNutritionistId,
        'messages': [
          {
            'id': 'msg_demo_1',
            'conversationId': 'conv_demo_1',
            'senderId': demoNutritionistId,
            'senderRole': 'nutritionist',
            'text': 'Bonjour Afiwa, j\'ai analysé votre semaine : '
                'belles progressions ! Le déjeuner est équilibré.',
            'sentAt': DateTime.now()
                .subtract(const Duration(hours: 30))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': 'msg_demo_2',
            'conversationId': 'conv_demo_1',
            'senderId': demoUserId,
            'senderRole': 'user',
            'text': 'Merci Docteur ! Je dois encore réduire le sucre le '
                'soir, c\'est bien ça ?',
            'sentAt':
                DateTime.now().subtract(const Duration(hours: 28)).toIso8601String(),
            'isRead': true,
          },
          {
            'id': 'msg_demo_3',
            'conversationId': 'conv_demo_1',
            'senderId': demoNutritionistId,
            'senderRole': 'nutritionist',
            'text': 'Exactement. Privilégiez une soupe ou une sauce '
                'légère au dîner.',
            'sentAt':
                DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
            'isRead': false,
          },
        ],
      },
    ]);

    // --- Recommandations automatiques ---
    await store.writeList(StoreKeys.recommendations, [
      {
        'id': 'rec_demo_1',
        'userId': demoUserId,
        'title': 'Hydratation',
        'body': 'Buvez au moins 1,5 L d\'eau par jour, idéalement avant '
            'chaque repas.',
        'category': 'hydratation',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'isRead': false,
      },
      {
        'id': 'rec_demo_2',
        'userId': demoUserId,
        'title': 'Protéines au petit-déjeuner',
        'body': 'Ajoutez un œuf ou du yaourt au petit-déjeuner pour '
            'augmenter votre apport en protéines.',
        'category': 'nutrition',
        'createdAt':
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'isRead': true,
      },
    ]);

    await store.writeString(StoreKeys.seeded, '1');
  }

  static Map<String, dynamic> _item(String foodId, double qty) {
    final food = FoodSeedData.foods.firstWhere((f) => f.id == foodId);
    return MealItemModel.fromFood(food, quantityG: qty).toMap();
  }
}
