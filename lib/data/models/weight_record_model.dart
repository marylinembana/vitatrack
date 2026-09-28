/// Enregistrement d'un point de poids.
class WeightRecordModel {
  final String id;
  final String userId;
  final double weightKg;
  final DateTime date;
  final String? note;

  WeightRecordModel({
    required this.id,
    required this.userId,
    required this.weightKg,
    DateTime? date,
    this.note,
  }) : date = date ?? DateTime.now();

  factory WeightRecordModel.fromMap(Map<String, dynamic> map) =>
      WeightRecordModel(
        id: map['id'] as String,
        userId: map['userId'] as String,
        weightKg: (map['weightKg'] as num).toDouble(),
        date: DateTime.tryParse(map['date'] as String? ?? '') ??
            DateTime.now(),
        note: map['note'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'weightKg': weightKg,
        'date': date.toIso8601String(),
        'note': note,
      };
}
