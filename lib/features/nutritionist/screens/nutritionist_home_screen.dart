import 'package:flutter/material.dart';

import '../screens/meal_plans_screen.dart';
import '../screens/nutritionist_dashboard_screen.dart';
import '../screens/nutritionist_profile_screen.dart';
import '../screens/patients_screen.dart';
import '../screens/reports_screen.dart';

/// Coquille de navigation du nutritionniste (5 onglets).
class NutritionistHomeScreen extends StatefulWidget {
  const NutritionistHomeScreen({super.key});

  @override
  State<NutritionistHomeScreen> createState() =>
      _NutritionistHomeScreenState();
}

class _NutritionistHomeScreenState extends State<NutritionistHomeScreen> {
  int _index = 0;

  static const _tabs = [
    NutritionistDashboardScreen(),
    PatientsScreen(),
    MealPlansScreen(),
    ReportsScreen(),
    NutritionistProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.groups), label: 'Patients'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu), label: 'Plans'),
          BottomNavigationBarItem(
              icon: Icon(Icons.insert_chart_outlined), label: 'Rapports'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
