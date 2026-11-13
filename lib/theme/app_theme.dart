import 'package:flutter/material.dart';

/// Brand palette taken from the Mahsouli design file.
class AppColors {
  static const brown = Color(0xFF6C3C0C); // primary text & buttons
  static const peach = Color(0xFFFFCC99); // accent surfaces
  static const cream = Color(0xFFFFF1E3); // search fields, soft cards
  static const border = Color(0xFFF1D9BF); // card borders
  static const inputBorder = Color(0xFFE8CBA9); // inputs, dividers
  static const muted = Color(0xFF8A5A2B); // secondary text
  static const white = Color(0xFFFFFFFF);
  static const danger = Color(0xFFB3261E);
  static const success = Color(0xFF2E7D32);
  static const star = Color(0xFFE59A2F);

  static const roastLight = Color(0xFFFFCC99);
  static const roastMedium = Color(0xFFF0B27A);
  static const roastDark = Color(0xFFD8915A);
}

class AppTheme {
  static ThemeData get light {
    const font = 'Tajawal';
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: font,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brown,
        primary: AppColors.brown,
        onPrimary: AppColors.white,
        secondary: AppColors.peach,
        onSecondary: AppColors.brown,
        surface: AppColors.white,
        onSurface: AppColors.brown,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.white,
    );
    return base.copyWith(
      iconTheme: const IconThemeData(color: AppColors.brown),
      textTheme: base.textTheme.apply(bodyColor: AppColors.brown, displayColor: AppColors.brown, fontFamily: font),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.brown,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontFamily: font, fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.brown),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brown, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brown,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: font, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brown,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.brown, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: font, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brown,
          textStyle: const TextStyle(fontFamily: font, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.brown,
        contentTextStyle: TextStyle(fontFamily: font, color: AppColors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.white : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.brown : null),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.brown,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.brown,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: AppColors.white, surfaceTintColor: Colors.transparent),
    );
  }
}
