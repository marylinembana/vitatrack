/// Recommandation personnalisée (générée par l'app ou un nutritionniste).
class RecommendationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String category; // hydratation, proteinnes, sommeil…
  final String? authorId; // nutritionniste si personnalisé
  final DateTime createdAt;
  bool isRead;

  RecommendationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.category = 'nutrition',
    this.authorId,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RecommendationModel.fromMap(Map<String, dynamic> map) =>
      RecommendationModel(
        id: map['id'] as String,
        userId: map['userId'] as String,
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        category: map['category'] as String? ?? 'nutrition',
        authorId: map['authorId'] as String?,
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
                DateTime.now(),
        isRead: map['isRead'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'category': category,
        'authorId': authorId,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };
}
