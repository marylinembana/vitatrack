import 'package:flutter/material.dart';

import 'activity_logs_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_profile_screen.dart';
import 'statistics_screen.dart';
import 'users_management_screen.dart';

/// Coquille de navigation de l'administrateur (5 onglets).
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  static const _tabs = [
    AdminDashboardScreen(),
    UsersManagementScreen(),
    StatisticsScreen(),
    ActivityLogsScreen(),
    AdminProfileScreen(),
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
              icon: Icon(Icons.manage_accounts), label: 'Comptes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.insert_chart_outlined), label: 'Stats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Journal'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
