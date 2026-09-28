/// Catégorie d'aliments (céréales, protéines, fruits…).
class CategoryModel {
  final String id;
  String name;
  String emoji;

  CategoryModel({
    required this.id,
    required this.name,
    this.emoji = '🍽️',
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        emoji: map['emoji'] as String? ?? '🍽️',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
      };
}
