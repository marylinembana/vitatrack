import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'app_button.dart';

/// Affichage d'une erreur avec possibilité de réessayer.
class ErrorWidgetView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorWidgetView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Oups !',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(
                label: 'Réessayer',
                icon: Icons.refresh,
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
