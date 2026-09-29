import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/constants/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';

/// Écran de démarrage : logo + redirection selon la session.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    // Lien de réinitialisation ouvert : on va directement choisir le mot de
    // passe, avant toute redirection selon le rôle.
    if (auth.isPasswordRecovery) {
      Navigator.of(context).pushReplacementNamed('/auth/reset');
      return;
    }
    final target = auth.isSignedIn ? auth.landingRoute : '/onboarding';
    Navigator.of(context).pushReplacementNamed(target);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 96,
                width: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                alignment: Alignment.center,
                child: const Text('🥗', style: TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: AppDimensions.paddingMd),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSm),
              Text(
                AppConstants.appTagline,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
