import 'package:flutter/material.dart';

/// "Hisob" brand palette — mirrors the web app's ledger-green design system.
class AppColors {
  AppColors._();

  static const brand = Color(0xFF0F6B4C);
  static const brandStrong = Color(0xFF0A4E38);
  static const brandSoft = Color(0xFFDCEEE4);
  static const income = Color(0xFF1E9C6B);
  static const expense = Color(0xFFC4573B);
  static const accent = Color(0xFFE8A33D);
  static const accentSoft = Color(0xFFFBEBD2);
  static const paper = Color(0xFFF3F6F4);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFDFE6E1);
  static const ink = Color(0xFF12231C);
  static const inkMuted = Color(0xFF5C6B63);

  static const paperDark = Color(0xFF0E1712);
  static const surfaceDark = Color(0xFF16211B);
  static const lineDark = Color(0xFF263229);
  static const inkDark = Color(0xFFE9F1EC);
  static const inkDarkMuted = Color(0xFF93A69B);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand, brandStrong],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.brand,
      secondary: AppColors.income,
      tertiary: AppColors.accent,
      error: AppColors.expense,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      outline: AppColors.line,
    );

    return _base(colorScheme).copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
        shadowColor: AppColors.ink.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.income,
      secondary: AppColors.brandSoft,
      tertiary: AppColors.accent,
      error: AppColors.expense,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.inkDark,
      outline: AppColors.lineDark,
    );

    return _base(colorScheme).copyWith(
      scaffoldBackgroundColor: AppColors.paperDark,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.inkDark,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.inkDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lineDark),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData _base(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final fill = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.lineDark : AppColors.line;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      splashFactory: InkSparkle.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.expense),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: colorScheme.primary,
          foregroundColor: isDark ? AppColors.paperDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 2,
          shadowColor: AppColors.brandStrong.withValues(alpha: 0.35),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: isDark ? AppColors.paperDark : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: border,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
