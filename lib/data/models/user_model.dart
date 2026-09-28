import '../../core/utils/nutrition_calculator.dart';

/// Sexe de l'utilisateur.
enum Gender { male, female }

extension GenderX on Gender {
  String get label => this == Gender.male ? 'Homme' : 'Femme';
  String get key => name;
  static Gender fromKey(String? key) => key == 'male'
      ? Gender.male
      : Gender.female;
}

/// Modèle utilisateur (rôle simple utilisateur).
class UserModel {
  final String id;
  final String email;
  String fullName;
  Gender gender;
  DateTime birthDate;
  double heightCm;
  double activityFactor;
  GoalType goalType;
  double targetWeightKg;
  double calorieGoal;
  String? photoUrl;
  bool isOnboarded;
  bool emailVerified;
  final List<String> favoriteFoodIds;
  String? nutritionistId;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.gender = Gender.male,
    DateTime? birthDate,
    this.heightCm = 170,
    this.activityFactor = 1.375,
    this.goalType = GoalType.maintain,
    this.targetWeightKg = 70,
    this.calorieGoal = 2200,
    this.photoUrl,
    this.isOnboarded = false,
    this.emailVerified = false,
    List<String>? favoriteFoodIds,
    this.nutritionistId,
    DateTime? createdAt,
  })  : birthDate = birthDate ?? DateTime(1995, 1, 1),
        favoriteFoodIds = favoriteFoodIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  int get age {
    final now = DateTime.now();
    var a = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      a--;
    }
    return a;
  }

  bool get isMale => gender == Gender.male;

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        email: map['email'] as String,
        fullName: map['fullName'] as String? ?? '',
        gender: GenderX.fromKey(map['gender'] as String?),
        birthDate: DateTime.tryParse(map['birthDate'] as String? ?? ''),
        heightCm: (map['heightCm'] as num?)?.toDouble() ?? 170,
        activityFactor: (map['activityFactor'] as num?)?.toDouble() ?? 1.375,
        goalType: GoalTypeX.fromKey(map['goalType'] as String? ?? 'maintain'),
        targetWeightKg: (map['targetWeightKg'] as num?)?.toDouble() ?? 70,
        calorieGoal: (map['calorieGoal'] as num?)?.toDouble() ?? 2200,
        photoUrl: map['photoUrl'] as String?,
        isOnboarded: map['isOnboarded'] as bool? ?? false,
        emailVerified: map['emailVerified'] as bool? ?? false,
        favoriteFoodIds:
            (map['favoriteFoodIds'] as List?)?.cast<String>() ?? [],
        nutritionistId: map['nutritionistId'] as String?,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'gender': gender.key,
        'birthDate': birthDate.toIso8601String(),
        'heightCm': heightCm,
        'activityFactor': activityFactor,
        'goalType': goalType.key,
        'targetWeightKg': targetWeightKg,
        'calorieGoal': calorieGoal,
        'photoUrl': photoUrl,
        'isOnboarded': isOnboarded,
        'emailVerified': emailVerified,
        'favoriteFoodIds': favoriteFoodIds,
        'nutritionistId': nutritionistId,
        'goal': goalType.key,
        'dailyCalorieGoal': calorieGoal,
        'createdAt': createdAt.toIso8601String(),
      };
}
