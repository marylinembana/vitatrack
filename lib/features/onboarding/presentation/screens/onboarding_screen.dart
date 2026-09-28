import 'package:flutter/material.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/services/local_store.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../authentication/presentation/screens/login_screen.dart';

/// Parcours de découverte en 3 étapes.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const _slides = [
    (
      icon: '🥗',
      title: 'Suivez vos repas',
      body: 'Enregistrez vos repas en quelques secondes et visualisez '
          'vos calories, protéines, glucides et lipides.',
    ),
    (
      icon: '🎯',
      title: 'Atteignez vos objectifs',
      body: 'Perte, maintien ou prise de poids : VitaTrack calcule vos '
          'besoins caloriques personnalisés.',
    ),
    (
      icon: '👩‍⚕️',
      title: 'Accompagnement expert',
      body: 'Échangez avec un nutritionniste, recevez des plans alimentaires '
          'et suivez votre progression.',
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  Future<void> _finish() async {
    await LocalStore.instance
        .writeString(StoreKeys.onboardingSeen, '1');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingSm),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Passer'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingXl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s.icon, style: const TextStyle(fontSize: 96)),
                        const SizedBox(height: AppDimensions.paddingXl),
                        Text(s.title,
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: AppDimensions.paddingMd),
                        Text(
                          s.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _page == i ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? AppColors.primary
                        : AppColors.primaryLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              child: AppButton(
                label: _isLast ? 'Commencer' : 'Suivant',
                icon: _isLast ? Icons.check : Icons.arrow_forward,
                onPressed: () {
                  if (_isLast) {
                    _finish();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Point d'entrée onboarding (évite un import direct de AppConstants ici).
const String onboardingRouteName = AppConstants.appName;
