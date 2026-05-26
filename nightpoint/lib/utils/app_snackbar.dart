import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AppSnackbar {

  static void show(
    BuildContext context,
    String message,
  ) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(
        content: Text(message),

        backgroundColor: AppColors.surface,

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}