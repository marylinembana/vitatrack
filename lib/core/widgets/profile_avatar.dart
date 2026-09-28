import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'app_image.dart';

/// Calcule les initiales d'un nom complet (ex. « Afiwa Kossi » → « AK »).
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  final list = parts.toList();
  if (list.length == 1) return list.first[0].toUpperCase();
  return (list.first[0] + list.last[0]).toUpperCase();
}

/// Avatar circulaire affichant la photo de profil si elle existe,
/// sinon les initiales sur fond doux.
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final double? fontSize;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 28,
    this.backgroundColor = AppColors.primarySoft,
    this.foregroundColor = AppColors.primaryDark,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: AppImage(
        url: photoUrl,
        width: size,
        height: size,
        fallback: Center(
          child: Text(
            initialsOf(name),
            style: TextStyle(
              fontSize: fontSize ?? radius * 0.8,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}
