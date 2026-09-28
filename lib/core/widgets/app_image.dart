import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';

/// Affiche une image distante (URL http) ou un fichier local (photo choisie
/// depuis la galerie / capturée par la caméra), avec repli gracieux sur un
/// contenu local (emoji, initiales, icône) tant que l'image n'est pas dispo.
///
/// Ce widget est le point d'entrée unique pour toutes les images de l'app :
/// aujourd'hui des URL publiques et des fichiers locaux, demain les URL issues
/// de l'API backend — aucun écran à modifier.
class AppImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget fallback;

  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    required this.fallback,
  });

  bool get hasImage => url != null && url!.trim().isNotEmpty;

  /// Vrai si l'URL désigne un fichier local (chemin absolu ou file://).
  bool get isLocalFile {
    if (!hasImage || kIsWeb) return false;
    final u = url!.trim();
    return !u.startsWith('http://') && !u.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (isLocalFile) {
      final path = url!.trim().replaceFirst('file://', '');
      child = Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (hasImage) {
      child = Image.network(
        url!.trim(),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (context, built, progress) {
          if (progress == null) return built;
          return Container(
            width: width,
            height: height,
            color: AppColors.primarySoft,
            alignment: Alignment.center,
            child: const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryLight,
              ),
            ),
          );
        },
      );
    } else {
      child = fallback;
    }
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

/// Vignette carrée arrondie d'un aliment : image réelle si disponible,
/// sinon l'emoji sur fond doux.
class FoodThumb extends StatelessWidget {
  final String? imageUrl;
  final String? emoji;
  final double size;

  const FoodThumb({
    super.key,
    required this.imageUrl,
    this.emoji,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimensions.radiusMd);
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: AppImage(
        url: imageUrl,
        width: size,
        height: size,
        borderRadius: radius,
        fallback: Center(
          child: Text(
            emoji ?? '🍽️',
            style: TextStyle(fontSize: size * 0.46),
          ),
        ),
      ),
    );
  }
}
