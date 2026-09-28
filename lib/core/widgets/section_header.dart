import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';

/// En-tête de section réutilisable (titre + action facultative à droite).
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: AppDimensions.paddingSm),
  });

  @override
  Widget build(BuildContext context) {
    if (actionLabel == null || onAction == null) {
      return Padding(
        padding: padding,
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );
    }
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          TextButton.icon(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.chevron_right, size: 18),
            label: Text(actionLabel!),
          ),
        ],
      ),
    );
  }
}
