import 'package:flutter/material.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';

/// Geriye dönük isimler; gerçek değerlerin tek kaynağı [KtColors]'dır.
abstract final class AppColors {
  static const brandBlue900 = KtColors.brandBlue900;
  static const brandBlue800 = KtColors.brandBlue800;
  static const brandBlue700 = KtColors.brandBlue700;
  static const brandBlue100 = KtColors.brandBlue100;
  static const brandBlue050 = KtColors.brandBlue050;
  static const magenta600 = KtColors.magenta600;
  static const page = KtColors.page;
  static const subtle = KtColors.subtle;
  static const textStrong = KtColors.textStrong;
  static const textDefault = KtColors.textDefault;
  static const textMuted = KtColors.textMuted;
  static const border = KtColors.border;
  static const success = KtColors.success;
  static const successSurface = KtColors.successSurface;
  static const active = KtColors.active;
  static const planned = KtColors.planned;
  static const plannedInk = KtColors.plannedInk;
  static const pending = KtColors.pending;
  static const critical = KtColors.critical;
  static const warningSurface = KtColors.warningSurface;
}

abstract final class AppTheme {
  static ThemeData light({bool highContrast = false}) {
    final scheme = ColorScheme.light(
      primary: highContrast ? KtColors.brandBlue900 : KtColors.brandBlue800,
      onPrimary: KtColors.white,
      primaryContainer: KtColors.brandBlue100,
      onPrimaryContainer: KtColors.brandBlue900,
      secondary: highContrast ? KtColors.magenta700 : KtColors.magenta600,
      surface: KtColors.white,
      onSurface: KtColors.textStrong,
      error: KtColors.activeDark,
      outline: highContrast ? KtColors.textStrong : KtColors.border,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: KtColors.page,
      focusColor: KtColors.magenta600,
      visualDensity: VisualDensity.standard,
      fontFamily: KtTypography.bodyFamily,
      fontFamilyFallback: KtTypography.fallback,
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          color: KtColors.textStrong,
          fontSize: 32,
          height: 1.2,
          fontWeight: FontWeight.w700,
          fontFamily: KtTypography.displayFamily,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: KtColors.textStrong,
          fontSize: 24,
          height: 1.25,
          fontWeight: FontWeight.w700,
          fontFamily: KtTypography.displayFamily,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: KtColors.textStrong,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: KtColors.textDefault,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: KtColors.textDefault,
          fontSize: 14,
          height: 1.43,
        ),
      ),
      cardTheme: CardThemeData(
        color: KtColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(KtRadius.card)),
          side: BorderSide(
            color: highContrast ? KtColors.textStrong : KtColors.border,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KtColors.white,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(KtRadius.control)),
          borderSide: BorderSide(color: KtColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(KtRadius.control)),
          borderSide: BorderSide(color: KtColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(KtRadius.control)),
          borderSide: BorderSide(color: KtColors.magenta600, width: 3),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KtSpacing.x4,
          vertical: KtSpacing.x4,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KtRadius.control),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KtRadius.control),
          ),
          side: const BorderSide(color: KtColors.brandBlue800),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      navigationBarTheme: const NavigationBarThemeData(
        height: 72,
        backgroundColor: KtColors.white,
        indicatorColor: KtColors.brandBlue100,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData highContrast() => light(highContrast: true);
}
