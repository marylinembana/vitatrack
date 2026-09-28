import 'package:flutter/material.dart';

import '../../app/theme/app_dimensions.dart';

/// Champ de texte standardisé pour tous les formulaires.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final VoidCallback? onSubmitted;
  final int maxLines;
  final Widget? prefixWidget;
  final String? initialValue;
  final FocusNode? focusNode;
  final bool enabled;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.onSubmitted,
    this.maxLines = 1,
    this.prefixWidget,
    this.initialValue,
    this.focusNode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMd),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        validator: validator,
        onFieldSubmitted: onSubmitted == null
            ? null
            : (_) => onSubmitted!(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixWidget ??
              (icon != null
                  ? Padding(
                      padding: const EdgeInsets.only(
                          left: AppDimensions.paddingMd,
                          right: AppDimensions.paddingSm),
                      child: Icon(icon, size: AppDimensions.iconMd),
                    )
                  : null),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
