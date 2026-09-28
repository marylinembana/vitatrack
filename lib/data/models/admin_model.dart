/// Entrée du journal des activités (admin).
class ActivityLogModel {
  final String id;
  final String actorId;
  final String actorRole;
  final String action; // create_user, delete_food, ban_user…
  final String target;
  final DateTime createdAt;

  ActivityLogModel({
    required this.id,
    required this.actorId,
    required this.actorRole,
    required this.action,
    this.target = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ActivityLogModel.fromMap(Map<String, dynamic> map) =>
      ActivityLogModel(
        id: map['id'] as String,
        actorId: map['actorId'] as String? ?? '',
        actorRole: map['actorRole'] as String? ?? '',
        action: map['action'] as String? ?? '',
        target: map['target'] as String? ?? '',
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
                DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'actorId': actorId,
        'actorRole': actorRole,
        'action': action,
        'target': target,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Compte administrateur (role : super_admin | admin).
class AdminModel {
  final String id;
  final String email;
  String fullName;
  String role; // super_admin | admin
  String? photoUrl;
  final DateTime createdAt;

  AdminModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.role = 'admin',
    this.photoUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isSuperAdmin => role == 'super_admin';

  String get roleLabel => isSuperAdmin ? 'Super administrateur' : 'Administrateur';

  factory AdminModel.fromMap(Map<String, dynamic> map) => AdminModel(
        id: map['id'] as String,
        email: map['email'] as String,
        fullName: map['fullName'] as String? ?? '',
        role: map['role'] as String? ?? 'admin',
        photoUrl: map['photoUrl'] as String?,
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
                DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
        'photoUrl': photoUrl,
        'createdAt': createdAt.toIso8601String(),
      };
}
