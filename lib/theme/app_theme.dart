import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Couleurs Samsung Easy Mode : neutre, sobre
  static const Color primary = Color(0xFF37474F); // bleu-gris foncé
  static const Color primaryDark = Color(0xFF263238);
  static const Color primaryLight = Color(0xFFECEFF1);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceAlt = Color(0xFFF0F0F0);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF616161);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color sosRed = Color(0xFFD32F2F);
  static const Color sosRedDark = Color(0xFF9A0007);
  static const Color callGreen = Color(0xFF2E7D32);
  static const Color messageBlue = Color(0xFF1565C0);
  static const Color whatsappGreen = Color(0xFF25D366);

  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFD0D0D0);

  // Tailles texte
  static const double fs14 = 14.0;
  static const double fs16 = 16.0;
  static const double fs18 = 18.0;
  static const double fs20 = 20.0;
  static const double fs22 = 22.0;
  static const double fs24 = 24.0;
  static const double fs26 = 26.0;
  static const double fs28 = 28.0;
  static const double fs30 = 30.0;
  static const double fs36 = 36.0;
  static const double fs48 = 48.0;

  // Tactile
  static const double touchMin = 56.0;
  static const double buttonH = 68.0;
  static const double buttonHLg = 80.0;
  static const double iconSm = 24.0;
  static const double iconMd = 32.0;
  static const double iconLg = 44.0;
  static const double iconXl = 56.0;
  static const double avatarR = 42.0;

  // Rayons
  static const double radius = 16.0;
  static const double radiusSm = 12.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 28.0;
  static const double pad = 20.0;
  static const double padSm = 12.0;

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: surface,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      secondary: callGreen,
      onSecondary: onPrimary,
      surface: card,
      onSurface: textDark,
      error: sosRed,
      onError: onPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 56,
      titleTextStyle: TextStyle(
        fontSize: fs24,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
      iconTheme: IconThemeData(size: iconMd, color: textDark),
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: fs26,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
      titleLarge: TextStyle(
        fontSize: fs22,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      bodyLarge: TextStyle(
        fontSize: fs22,
        fontWeight: FontWeight.w400,
        color: textDark,
      ),
      bodyMedium: TextStyle(
        fontSize: fs20,
        fontWeight: FontWeight.w400,
        color: textMedium,
      ),
      bodySmall: TextStyle(
        fontSize: fs18,
        fontWeight: FontWeight.w400,
        color: textMedium,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        minimumSize: const Size(double.infinity, buttonH),
        textStyle: const TextStyle(fontSize: fs22, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(double.infinity, buttonH),
        textStyle: const TextStyle(fontSize: fs22, fontWeight: FontWeight.w600),
        side: const BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: sosRed, width: 2),
      ),
      hintStyle: const TextStyle(fontSize: fs20, color: textLight),
      labelStyle: const TextStyle(fontSize: fs20, color: textMedium),
      errorStyle: const TextStyle(fontSize: fs18, color: sosRed),
      prefixIconColor: textMedium,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? callGreen : border,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? callGreen.withValues(alpha: 0.3)
            : border.withValues(alpha: 0.3),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textDark,
      contentTextStyle: const TextStyle(fontSize: fs18, color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXl),
      ),
      titleTextStyle: const TextStyle(
        fontSize: fs24,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
      contentTextStyle: const TextStyle(fontSize: fs20, color: textMedium),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
    ),
  );
}
