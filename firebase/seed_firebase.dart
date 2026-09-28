// ignore_for_file: avoid_print
/// Script de seeding Firebase pour VitaTrack.
/// Usage : flutter run -t firebase/seed_firebase.dart -d chrome
///
/// Ce script crée :
///   1. Les 3 comptes de démonstration dans Firebase Authentication
///   2. Leurs profils dans Firestore (collection `users`)
///   3. Les catégories d'aliments (collection `categories`)
///   4. Le catalogue d'aliments camerounais (collection `foods`)
///
/// ⚠️  À exécuter UNE SEULE FOIS après avoir activé Firebase Auth +
///     créé la base Firestore dans la Console Firebase.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vitatrack/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('=== VitaTrack — Firebase Seeder ===');

  await _createDemoAccounts();
  await _seedCategories();
  await _seedFoods();

  print('\n✅  Seeding terminé avec succès !');
  print('   Utilisez les comptes :');
  print('   • user@vitatrack.app / demo1234');
  print('   • nutritionist@vitatrack.app / demo1234');
  print('   • admin@vitatrack.app / demo1234');
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPTES DE DÉMONSTRATION
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _createDemoAccounts() async {
  print('\n[1/3] Création des comptes Firebase Auth…');
  final db = FirebaseFirestore.instance;
  final now = DateTime.now().toIso8601String();

  final accounts = [
    {
      'email': 'user@vitatrack.app',
      'password': 'demo1234',
      'displayName': 'Afiwa Mbarga',
      'profile': {
        'email': 'user@vitatrack.app',
        'role': 'user',
        'fullName': 'Afiwa Mbarga',
        'gender': 'female',
        'birthDate': '1998-05-12T00:00:00.000',
        'heightCm': 165,
        'activityFactor': 1.375,
        'goalType': 'lose',
        'targetWeightKg': 62,
        'calorieGoal': 1650,
        'isOnboarded': true,
        'emailVerified': false,
        'favoriteFoodIds': ['food_001', 'food_015'],
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      },
    },
    {
      'email': 'nutritionist@vitatrack.app',
      'password': 'demo1234',
      'displayName': 'Dr. Renaud Adjovi',
      'profile': {
        'email': 'nutritionist@vitatrack.app',
        'role': 'nutritionist',
        'fullName': 'Dr. Renaud Adjovi',
        'specialization': 'Nutrition générale',
        'licenseNumber': 'NUT-DEMO-001',
        'bio': 'Nutritionniste certifié, spécialisé dans les habitudes '
            'alimentaires camerounaises.',
        'city': 'Yaoundé',
        'phone': '+237600000001',
        'experienceYears': 8,
        'isVerified': true,
        'verificationStatus': 'verified',
        'hasAccess': true,
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      },
    },
    {
      'email': 'admin@vitatrack.app',
      'password': 'demo1234',
      'displayName': 'Administrateur VitaTrack',
      'profile': {
        'email': 'admin@vitatrack.app',
        'role': 'admin',
        'fullName': 'Administrateur VitaTrack',
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      },
    },
  ];

  for (final account in accounts) {
    final email = account['email'] as String;
    final password = account['password'] as String;
    final displayName = account['displayName'] as String;
    final profileData = account['profile'] as Map<String, dynamic>;

    try {
      // Tentative de création du compte
      UserCredential cred;
      try {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('   ✓ Compte créé : $email');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Si le compte existe déjà, on se connecte pour récupérer l'UID
          cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          print('   ~ Compte existant (mise à jour profil) : $email');
        } else {
          print('   ✗ Erreur pour $email : ${e.message}');
          continue;
        }
      }

      await cred.user?.updateDisplayName(displayName);
      final uid = cred.user!.uid;

      // Écriture du profil dans Firestore
      final fullProfile = {
        ...profileData,
        'id': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await db
          .collection('users')
          .doc(uid)
          .set(fullProfile, SetOptions(merge: true));
      print('   ✓ Profil Firestore : users/$uid');

      // Déconnexion pour pouvoir créer le compte suivant
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('   ✗ Erreur inattendue pour $email : $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATÉGORIES D'ALIMENTS
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _seedCategories() async {
  print('\n[2/3] Seeding des catégories…');
  final db = FirebaseFirestore.instance;
  final batch = db.batch();

  final categories = [
    {'id': 'cat_local', 'name': 'Plats locaux', 'icon': '🍲', 'order': 1},
    {'id': 'cat_tubercules', 'name': 'Tubercules', 'icon': '🥔', 'order': 2},
    {'id': 'cat_fec', 'name': 'Féculents', 'icon': '🌾', 'order': 3},
    {'id': 'cat_cereales', 'name': 'Céréales', 'icon': '🌽', 'order': 4},
    {'id': 'cat_legumes', 'name': 'Légumes', 'icon': '🥦', 'order': 5},
    {'id': 'cat_legum', 'name': 'Légumineuses', 'icon': '🫘', 'order': 6},
    {'id': 'cat_proteines', 'name': 'Protéines', 'icon': '🥩', 'order': 7},
    {'id': 'cat_fruits', 'name': 'Fruits', 'icon': '🍌', 'order': 8},
    {'id': 'cat_laitiers', 'name': 'Produits laitiers', 'icon': '🥛', 'order': 9},
    {'id': 'cat_boissons', 'name': 'Boissons', 'icon': '🧃', 'order': 10},
    {'id': 'cat_snacks', 'name': 'Snacks & sucreries', 'icon': '🍪', 'order': 11},
  ];

  for (final cat in categories) {
    final id = cat['id'] as String;
    batch.set(
      db.collection('categories').doc(id),
      {...cat, 'isActive': true, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  await batch.commit();
  print('   ✓ ${categories.length} catégories ajoutées');
}

// ─────────────────────────────────────────────────────────────────────────────
// CATALOGUE D'ALIMENTS CAMEROUNAIS
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _seedFoods() async {
  print('\n[3/3] Seeding des aliments camerounais…');
  final db = FirebaseFirestore.instance;

  // Utiliser plusieurs batches car Firebase limite à 500 ops par batch
  final foods = _getFoods();
  const batchSize = 400;

  for (var i = 0; i < foods.length; i += batchSize) {
    final chunk = foods.sublist(i, (i + batchSize).clamp(0, foods.length));
    final batch = db.batch();
    for (final food in chunk) {
      final id = food['id'] as String;
      batch.set(
        db.collection('foods').doc(id),
        {
          ...food,
          'isActive': true,
          'country': 'Cameroun',
          'servingUnit': '100 g',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  print('   ✓ ${foods.length} aliments ajoutés');
}

List<Map<String, dynamic>> _getFoods() => [
      // ── Plats locaux ──────────────────────────────────────────────────────
      _food('food_001', 'Ndolé', 'cat_local', cal: 145, prot: 7.5, carb: 8.2, fat: 9.1),
      _food('food_002', 'Eru', 'cat_local', cal: 118, prot: 7.0, carb: 6.0, fat: 7.2),
      _food('food_003', 'Koki', 'cat_local', cal: 190, prot: 8.0, carb: 24.0, fat: 6.5),
      _food('food_004', 'Achu', 'cat_local', cal: 160, prot: 3.0, carb: 30.0, fat: 3.5),
      _food('food_005b', 'Beignets haricots (accra)', 'cat_local', cal: 280, prot: 9.0, carb: 32.0, fat: 13.0),
      _food('food_006b', 'Sauce gombo', 'cat_local', cal: 85, prot: 4.5, carb: 7.0, fat: 5.0),
      _food('food_007b', 'Mbongo tchôbi', 'cat_local', cal: 175, prot: 18.0, carb: 4.0, fat: 9.5),
      _food('food_008b', 'Nkui (soupe)', 'cat_local', cal: 95, prot: 5.0, carb: 8.0, fat: 5.5),
      _food('food_009b', 'Okok / Gnetum', 'cat_local', cal: 110, prot: 8.5, carb: 5.5, fat: 6.0),
      _food('food_010b', 'Tchiep (riz au poisson)', 'cat_local', cal: 200, prot: 14.0, carb: 25.0, fat: 5.0),
      // ── Tubercules ────────────────────────────────────────────────────────
      _food('food_005', 'Taro cuit', 'cat_tubercules', cal: 142, prot: 1.5, carb: 34.0, fat: 0.2),
      _food('food_007', 'Manioc cuit', 'cat_tubercules', cal: 160, prot: 1.4, carb: 38.1, fat: 0.3),
      _food('food_008', 'Macabo cuit', 'cat_tubercules', cal: 145, prot: 2.0, carb: 34.0, fat: 0.4),
      _food('food_t4', 'Igname cuite', 'cat_tubercules', cal: 118, prot: 1.5, carb: 27.9, fat: 0.1),
      _food('food_t5', 'Patate douce cuite', 'cat_tubercules', cal: 86, prot: 1.6, carb: 20.1, fat: 0.1),
      // ── Féculents ─────────────────────────────────────────────────────────
      _food('food_006', 'Plantain mûr cuit', 'cat_fec', cal: 122, prot: 1.3, carb: 31.9, fat: 0.4),
      _food('food_f2', 'Plantain vert cuit', 'cat_fec', cal: 116, prot: 1.0, carb: 28.5, fat: 0.3),
      _food('food_f3', 'Plantain frit (alloco)', 'cat_fec', cal: 246, prot: 1.4, carb: 36.5, fat: 10.5),
      // ── Céréales ─────────────────────────────────────────────────────────
      _food('food_009', 'Riz blanc cuit', 'cat_cereales', cal: 130, prot: 2.7, carb: 28.2, fat: 0.3),
      _food('food_010', 'Couscous de maïs', 'cat_cereales', cal: 112, prot: 2.5, carb: 23.5, fat: 0.8),
      _food('food_c3', 'Farine de manioc (gari)', 'cat_cereales', cal: 357, prot: 1.0, carb: 86.0, fat: 0.5),
      _food('food_c4', 'Flocons d\'avoine cuits', 'cat_cereales', cal: 71, prot: 2.5, carb: 12.0, fat: 1.5),
      _food('food_c5', 'Pain baguette', 'cat_cereales', cal: 270, prot: 8.5, carb: 54.0, fat: 2.5),
      _food('food_c6', 'Pâtes cuites', 'cat_cereales', cal: 131, prot: 5.0, carb: 25.0, fat: 1.1),
      // ── Légumes ───────────────────────────────────────────────────────────
      _food('food_l1', 'Épinards cuits', 'cat_legumes', cal: 23, prot: 2.9, carb: 3.6, fat: 0.4),
      _food('food_l2', 'Gombo cru', 'cat_legumes', cal: 33, prot: 1.9, carb: 7.5, fat: 0.2),
      _food('food_l3', 'Tomate fraîche', 'cat_legumes', cal: 18, prot: 0.9, carb: 3.9, fat: 0.2),
      _food('food_l4', 'Oignon', 'cat_legumes', cal: 40, prot: 1.1, carb: 9.3, fat: 0.1),
      _food('food_l5', 'Poivron', 'cat_legumes', cal: 31, prot: 1.0, carb: 6.0, fat: 0.3),
      _food('food_l6', 'Concombre', 'cat_legumes', cal: 15, prot: 0.7, carb: 3.6, fat: 0.1),
      _food('food_l7', 'Aubergine cuite', 'cat_legumes', cal: 35, prot: 0.8, carb: 8.7, fat: 0.2),
      _food('food_l8', 'Chou blanc', 'cat_legumes', cal: 25, prot: 1.3, carb: 5.8, fat: 0.1),
      // ── Légumineuses ─────────────────────────────────────────────────────
      _food('food_011', 'Haricot rouge cuit', 'cat_legum', cal: 127, prot: 8.7, carb: 22.8, fat: 0.5),
      _food('food_012', 'Arachide (cacahuète)', 'cat_legum', cal: 567, prot: 25.8, carb: 16.1, fat: 49.2),
      _food('food_lg3', 'Lentilles cuites', 'cat_legum', cal: 116, prot: 9.0, carb: 20.0, fat: 0.4),
      _food('food_lg4', 'Haricot blanc cuit', 'cat_legum', cal: 139, prot: 9.7, carb: 25.0, fat: 0.5),
      _food('food_lg5', 'Pois chiches cuits', 'cat_legum', cal: 164, prot: 8.9, carb: 27.4, fat: 2.6),
      _food('food_lg6', 'Soja graines cuites', 'cat_legum', cal: 173, prot: 16.6, carb: 9.9, fat: 9.0),
      // ── Protéines ─────────────────────────────────────────────────────────
      _food('food_013', 'Poulet cuit', 'cat_proteines', cal: 239, prot: 27.3, carb: 0.0, fat: 13.6),
      _food('food_014', 'Poisson braisé (tilapia)', 'cat_proteines', cal: 160, prot: 24.0, carb: 0.0, fat: 6.0),
      _food('food_p3', 'Bœuf cuit', 'cat_proteines', cal: 250, prot: 26.0, carb: 0.0, fat: 15.0),
      _food('food_p4', 'Œuf entier cuit', 'cat_proteines', cal: 155, prot: 13.0, carb: 1.1, fat: 11.0),
      _food('food_p5', 'Crevettes cuites', 'cat_proteines', cal: 99, prot: 24.0, carb: 0.2, fat: 0.3),
      _food('food_p6', 'Sardines en conserve', 'cat_proteines', cal: 208, prot: 24.6, carb: 0.0, fat: 11.5),
      _food('food_p7', 'Thon en conserve', 'cat_proteines', cal: 116, prot: 26.0, carb: 0.0, fat: 1.0),
      _food('food_p8', 'Porc cuit', 'cat_proteines', cal: 242, prot: 27.0, carb: 0.0, fat: 14.0),
      _food('food_p9', 'Foie de bœuf cuit', 'cat_proteines', cal: 175, prot: 27.0, carb: 4.4, fat: 5.0),
      // ── Fruits ────────────────────────────────────────────────────────────
      _food('food_015', 'Avocat', 'cat_fruits', cal: 160, prot: 2.0, carb: 8.5, fat: 14.7),
      _food('food_016', 'Banane', 'cat_fruits', cal: 89, prot: 1.1, carb: 22.8, fat: 0.3),
      _food('food_017', 'Papaye', 'cat_fruits', cal: 43, prot: 0.5, carb: 10.8, fat: 0.3),
      _food('food_018', 'Ananas', 'cat_fruits', cal: 50, prot: 0.5, carb: 13.1, fat: 0.1),
      _food('food_fr5', 'Mangue', 'cat_fruits', cal: 60, prot: 0.8, carb: 15.0, fat: 0.4),
      _food('food_fr6', 'Orange', 'cat_fruits', cal: 47, prot: 0.9, carb: 11.8, fat: 0.1),
      _food('food_fr7', 'Goyave', 'cat_fruits', cal: 68, prot: 2.6, carb: 14.3, fat: 1.0),
      _food('food_fr8', 'Pastèque', 'cat_fruits', cal: 30, prot: 0.6, carb: 7.6, fat: 0.2),
      _food('food_fr9', 'Citron', 'cat_fruits', cal: 29, prot: 1.1, carb: 9.3, fat: 0.3),
      _food('food_fr10', 'Coco (chair fraîche)', 'cat_fruits', cal: 354, prot: 3.3, carb: 15.2, fat: 33.5),
      // ── Produits laitiers ─────────────────────────────────────────────────
      _food('food_d1', 'Lait entier', 'cat_laitiers', cal: 61, prot: 3.2, carb: 4.8, fat: 3.3),
      _food('food_d2', 'Yaourt nature', 'cat_laitiers', cal: 59, prot: 3.5, carb: 4.7, fat: 3.3),
      _food('food_d3', 'Fromage blanc', 'cat_laitiers', cal: 82, prot: 8.0, carb: 3.8, fat: 3.6),
      _food('food_d4', 'Beurre', 'cat_laitiers', cal: 717, prot: 0.9, carb: 0.1, fat: 81.0),
      // ── Boissons ─────────────────────────────────────────────────────────
      _food('food_b1', 'Bissap (hibiscus)', 'cat_boissons', cal: 12, prot: 0.1, carb: 3.0, fat: 0.0),
      _food('food_b2', 'Jus d\'orange frais', 'cat_boissons', cal: 45, prot: 0.7, carb: 10.4, fat: 0.2),
      _food('food_b3', 'Eau de coco', 'cat_boissons', cal: 19, prot: 0.7, carb: 3.7, fat: 0.2),
      _food('food_b4', 'Lait de soja', 'cat_boissons', cal: 33, prot: 2.9, carb: 1.7, fat: 1.8),
      // ── Snacks ────────────────────────────────────────────────────────────
      _food('food_s1', 'Beignets sucrés', 'cat_snacks', cal: 370, prot: 5.0, carb: 50.0, fat: 17.0),
      _food('food_s2', 'Chocolat noir 70%', 'cat_snacks', cal: 598, prot: 7.8, carb: 45.9, fat: 42.6),
      _food('food_s3', 'Chips de plantain', 'cat_snacks', cal: 529, prot: 2.3, carb: 59.8, fat: 31.8),
    ];

Map<String, dynamic> _food(
  String id,
  String name,
  String categoryId, {
  required double cal,
  required double prot,
  required double carb,
  required double fat,
}) =>
    {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'calories': cal,
      'protein': prot,
      'carbs': carb,
      'fat': fat,
      // Valeurs per100g pour compatibilité avec le modèle local
      'per100g': {
        'calories': cal,
        'proteins': prot,
        'carbs': carb,
        'fats': fat,
        'fiber': 0.0,
      },
    };
