import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/food_model.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/dashboard/user_dashboard/controllers/app_provider.dart';
import '../../features/dashboard/user_dashboard/screens/user_home_screen.dart';
import '../../features/foods/presentation/screens/categories_screen.dart';
import '../../features/foods/presentation/screens/food_details_screen.dart';
import '../../features/foods/presentation/screens/food_search_screen.dart';
import '../../features/foods/presentation/screens/foods_screen.dart';
import '../../features/goals/screens/goal_setup_screen.dart';
import '../../features/meals/presentation/screens/add_meal_screen.dart';
import '../../features/meals/presentation/screens/food_journal_screen.dart';
import '../../features/messaging/screens/conversations_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/nutritionist/screens/nutritionist_home_screen.dart';
import '../../features/nutritionist/screens/nutritionist_verification_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/recommendations/screens/recommendations_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/weight/screens/weight_screen.dart';
import 'app_routes.dart';

/// Fabrique les routes nommées de l'application.
class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashScreen(), settings);
      case AppRoutes.onboarding:
        return _page(const OnboardingScreen(), settings);
      case AppRoutes.login:
        return _page(const LoginScreen(), settings);
      case AppRoutes.register:
        return _page(const RegisterScreen(), settings);
      case AppRoutes.forgotPassword:
        return _page(const ForgotPasswordScreen(), settings);
      case AppRoutes.onboardingSetup:
        return _page(const GoalSetupScreen(isOnboarding: true), settings);
      case AppRoutes.userHome:
        return _page(const UserHomeScreen(), settings);
      case AppRoutes.nutritionistHome:
        return _page(const NutritionistHomeScreen(), settings);
      case AppRoutes.nutritionistVerification:
        return _page(const NutritionistVerificationScreen(), settings);
      case AppRoutes.adminHome:
        return _page(const AdminHomeScreen(), settings);
      case AppRoutes.foods:
        return _page(const FoodsScreen(), settings);
      case AppRoutes.foodSearch:
        return _page(const FoodSearchScreen(), settings);
      case AppRoutes.categories:
        return _page(const CategoriesScreen(), settings);
      case AppRoutes.foodDetail:
        return _page(_FoodDetailRoute(settings: settings), settings);
      case AppRoutes.addMeal:
        final args = settings.arguments;
        final (DateTime? date, String? type) = switch (args) {
          Map<String, dynamic> m => (
              m['date'] as DateTime?,
              m['type'] as String?,
            ),
          _ => (null, null),
        };
        return _page(AddMealScreen(initialDate: date, initialType: type),
            settings);
      case AppRoutes.journal:
        return _page(const FoodJournalScreen(), settings);
      case AppRoutes.goals:
        return _page(const GoalSetupScreen(), settings);
      case AppRoutes.weight:
        return _page(const WeightScreen(), settings);
      case AppRoutes.recommendations:
        return _page(const RecommendationsScreen(), settings);
      case AppRoutes.notifications:
        return _page(const NotificationsScreen(), settings);
      case AppRoutes.messaging:
        return _page(const ConversationsScreen(), settings);
      case AppRoutes.profile:
        return _page(const ProfileScreen(), settings);
      case AppRoutes.editProfile:
        return _page(const EditProfileScreen(), settings);
      case AppRoutes.settings:
        return _page(const SettingsScreen(), settings);
      default:
        return _page(ErrorRouteView(routeName: settings.name), settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget child, RouteSettings settings) =>
      MaterialPageRoute(builder: (_) => child, settings: settings);
}

/// Résolution de la fiche aliment depuis l'identifiant passé en arguments.
class _FoodDetailRoute extends StatelessWidget {
  final RouteSettings settings;
  const _FoodDetailRoute({required this.settings});

  @override
  Widget build(BuildContext context) {
    final id = settings.arguments;
    final FoodModel? food = id is String
        ? context.read<AppProvider>().foodById(id)
        : (id is FoodModel ? id : null);
    if (food == null) {
      return const Scaffold(
        body: Center(child: Text('Aliment introuvable')),
      );
    }
    return FoodDetailsScreen(food: food);
  }
}

/// Écran affiché pour une route inconnue.
class ErrorRouteView extends StatelessWidget {
  final String? routeName;
  const ErrorRouteView({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page introuvable')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Route inconnue : ${routeName ?? '—'}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.splash, (_) => false),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}
