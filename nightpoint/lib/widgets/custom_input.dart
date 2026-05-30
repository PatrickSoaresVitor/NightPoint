import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';

class CustomInput extends StatelessWidget {
  final String hint;
  final IconData? icon;
  final int maxLines;
  final bool obscureText;
  final TextEditingController? controller;

  const CustomInput({
    super.key,
    required this.hint,
    this.icon,
    this.maxLines = 1,
    this.obscureText = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      style: const TextStyle(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
        ),
        prefixIcon: icon == null
            ? null
            : Icon(
                icon,
                color: AppColors.primary,
              ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}