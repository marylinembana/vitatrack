/// Une entrée de plan : aliment + quantité + moment de la journée.
class MealPlanEntry {
  final String mealType;
  final String foodId;
  final String foodName;
  final double quantityG;

  MealPlanEntry({
    required this.mealType,
    required this.foodId,
    required this.foodName,
    this.quantityG = 100,
  });

  factory MealPlanEntry.fromMap(Map<String, dynamic> map) => MealPlanEntry(
        mealType: map['mealType'] as String? ?? '',
        foodId: map['foodId'] as String? ?? '',
        foodName: map['foodName'] as String? ?? '',
        quantityG: (map['quantityG'] as num?)?.toDouble() ?? 100,
      );

  Map<String, dynamic> toMap() => {
        'mealType': mealType,
        'foodId': foodId,
        'foodName': foodName,
        'quantityG': quantityG,
      };
}

/// Plan alimentaire créé par un nutritionniste pour un patient.
class MealPlanModel {
  final String id;
  final String nutritionistId;
  final String patientId;
  String title;
  String description;
  DateTime startDate;
  int days;
  final List<MealPlanEntry> entries;
  bool isActive;
  final DateTime createdAt;

  MealPlanModel({
    required this.id,
    required this.nutritionistId,
    required this.patientId,
    required this.title,
    this.description = '',
    DateTime? startDate,
    this.days = 7,
    List<MealPlanEntry>? entries,
    this.isActive = true,
    DateTime? createdAt,
  })  : startDate = startDate ?? DateTime.now(),
        entries = entries ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory MealPlanModel.fromMap(Map<String, dynamic> map) => MealPlanModel(
        id: map['id'] as String,
        nutritionistId: map['nutritionistId'] as String? ?? '',
        patientId: map['patientId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        startDate:
            DateTime.tryParse(map['startDate'] as String? ?? '') ??
                DateTime.now(),
        days: (map['days'] as num?)?.toInt() ?? 7,
        entries: (map['entries'] as List?)
                ?.map((e) =>
                    MealPlanEntry.fromMap((e as Map).cast<String, dynamic>()))
                .toList() ??
            [],
        isActive: map['isActive'] as bool? ?? true,
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
                DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nutritionistId': nutritionistId,
        'patientId': patientId,
        'title': title,
        'description': description,
        'startDate': startDate.toIso8601String(),
        'days': days,
        'entries': entries.map((e) => e.toMap()).toList(),
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };
}
