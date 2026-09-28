/// Statut de vérification d'un compte nutritionniste.
enum VerificationStatus {
  pending, // profil soumis, en attente de contrôle par l'admin
  verified, // diplômes & agréments validés
  rejected, // informations refusées (à corriger)
}

extension VerificationStatusX on VerificationStatus {
  String get key => name;
  String get label => switch (this) {
        VerificationStatus.pending => 'En attente de vérification',
        VerificationStatus.verified => 'Vérifié',
        VerificationStatus.rejected => 'À corriger',
      };
  static VerificationStatus fromKey(String? key) => switch (key) {
        'verified' => VerificationStatus.verified,
        'rejected' => VerificationStatus.rejected,
        _ => VerificationStatus.pending,
      };
}

/// Profil professionnel d'un nutritionniste.
class NutritionistModel {
  final String id;
  final String email;
  String fullName;
  String? photoUrl;
  String specialization;
  String licenseNumber; // N° d'ordre / agrément
  String bio;
  String phone;
  String city;
  int experienceYears;
  List<String> diplomaUrls; // diplômes & attestations (images)
  List<String> patientIds;

  /// Rétro-compatibilité : [isVerified] reflète le statut de vérification.
  bool isVerified;
  VerificationStatus verificationStatus;
  String? verificationNote;
  final DateTime createdAt;

  NutritionistModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.photoUrl,
    this.specialization = 'Nutrition générale',
    this.licenseNumber = '',
    this.bio = '',
    this.phone = '',
    this.city = '',
    this.experienceYears = 0,
    List<String>? diplomaUrls,
    List<String>? patientIds,
    this.isVerified = false,
    this.verificationStatus = VerificationStatus.pending,
    this.verificationNote,
    DateTime? createdAt,
  })  : diplomaUrls = diplomaUrls ?? [],
        patientIds = patientIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Un nutritionniste n'accède à ses fonctions qu'une fois vérifié.
  bool get hasAccess => isVerified ||
      verificationStatus == VerificationStatus.verified;

  /// Le profil est-il assez complet pour être soumis à vérification ?
  bool get isProfileComplete =>
      fullName.trim().isNotEmpty &&
      specialization.trim().isNotEmpty &&
      licenseNumber.trim().isNotEmpty &&
      diplomaUrls.isNotEmpty;

  factory NutritionistModel.fromMap(Map<String, dynamic> map) {
    final verified = map['isVerified'] as bool? ?? false;
    final status = VerificationStatusX.fromKey(
        map['verificationStatus'] as String?);
    return NutritionistModel(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['fullName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      specialization:
          map['specialization'] as String? ?? 'Nutrition générale',
      licenseNumber: map['licenseNumber'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      city: map['city'] as String? ?? '',
      experienceYears: (map['experienceYears'] as num?)?.toInt() ?? 0,
      diplomaUrls: (map['diplomaUrls'] as List?)?.cast<String>() ?? [],
      patientIds: (map['patientIds'] as List?)?.cast<String>() ?? [],
      isVerified: verified,
      verificationStatus:
          verified ? VerificationStatus.verified : status,
      verificationNote: map['verificationNote'] as String?,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'photoUrl': photoUrl,
        'specialization': specialization,
        'licenseNumber': licenseNumber,
        'bio': bio,
        'phone': phone,
        'city': city,
        'experienceYears': experienceYears,
        'diplomaUrls': diplomaUrls,
        'patientIds': patientIds,
        'isVerified': isVerified,
        'verificationStatus': verificationStatus.key,
        'verificationNote': verificationNote,
        'createdAt': createdAt.toIso8601String(),
      };
}
