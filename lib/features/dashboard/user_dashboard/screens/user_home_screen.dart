import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../foods/presentation/screens/foods_screen.dart';
import '../../../meals/presentation/screens/food_journal_screen.dart';
import '../../../profile/screens/profile_screen.dart';
import 'dashboard_screen.dart';

/// Coquille de navigation pour le rôle utilisateur (bottom nav 4 onglets).
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _index = 0;

  static const _tabs = [
    DashboardScreen(),
    FoodsScreen(),
    FoodJournalScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Aliments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined), label: 'Journal'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}

/// Petit badge réutilisable.
class RoleBadge extends StatelessWidget {
  final String label;
  const RoleBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
    );
  }
}
