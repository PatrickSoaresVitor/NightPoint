import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AppSnackbar {
  static void show(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        elevation: 8,
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).size.height - 150,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}