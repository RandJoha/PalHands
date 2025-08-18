import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

enum AppToastType { success, error, info, warning }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Brand-aligned colors (close to website theme)
    // All non-error states use a soft light red tone to blend with site theme.
    final Color bg = switch (type) {
      AppToastType.success => AppColors.primaryLight,
      AppToastType.error => AppColors.primary,
      AppToastType.warning => AppColors.primaryLight,
      AppToastType.info => AppColors.primaryLight,
    };
    final snackBar = SnackBar(
      content: Text(
        message,
        style: GoogleFonts.cairo(color: AppColors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              textColor: AppColors.white,
              onPressed: onAction,
            )
          : null,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
