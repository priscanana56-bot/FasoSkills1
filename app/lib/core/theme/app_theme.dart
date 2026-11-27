import 'package:flutter/material.dart';

/// Charte graphique FasoSkills — palette indigo premium.
class AppTheme {
  AppTheme._();

  // ── Couleurs de marque ──────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color secondaryColor = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color accentColor = Color(0xFFFFA726);
  static const Color backgroundColor = Color(0xFFF8FAFF);
  static const Color textColor = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE0E7FF);
  static const Color inputFillColor = Color(0xFFEEF2FF);

  // ── Couleurs sémantiques ────────────────────────────────────────────────
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color ratingColor = Color(0xFFFFA726);
  static const Color destructiveColor = Color(0xFFEF4444);
  static const Color notificationBadgeColor = Color(0xFFFFA726);

  /// Alias conservé pour compatibilité.
  static const Color lightGray = inputFillColor;

  // ── Statuts ─────────────────────────────────────────────────────────────
  static const Color statusPending = Color(0xFFFFA726);
  static const Color statusAccepted = Color(0xFF4F46E5);
  static const Color statusCompleted = Color(0xFF3730A3);
  static const Color statusUnavailable = Color(0xFF94A3B8);

  // ── Palette Admin (Maquettes & §13) ──────────────────────────────────────
  static const Color adminIndigo = Color(0xFF1E1B4B);
  static const Color adminIndigoDeep = Color(0xFF312E81);
  static const Color adminOrange = Color(0xFFF97316);
  static const Color adminAmberSoft = Color(0xFFFEF3C7);
  static const Color adminCream = Color(0xFFFFF6EE);
  static const Color adminPeach = Color(0xFFFDE8D7);
  static const Color adminEmerald = Color(0xFF10B981);
  static const Color adminSuccess = Color(0xFF16A34A);
  static const Color adminMintButton = Color(0xFF5EEAD4);
  static const Color adminMintSoft = Color(0xFFDCFCE7);
  static const Color adminDanger = Color(0xFFDC2626);
  static const Color adminDangerSoft = Color(0xFFFEE2E2);
  static const Color adminBackground = Color(0xFFF8FAFC);
  static const Color adminCardBorder = Color(0xFFE2E8F0);

  // ── Glassmorphism ───────────────────────────────────────────────────────
  static Color glassBackground = Colors.white.withValues(alpha: 0.12);
  static Color glassBorder = Colors.white.withValues(alpha: 0.20);
  static Color glassInactiveFill = Colors.white.withValues(alpha: 0.08);

  // ── Dégradés ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFFF8FAFF), Color(0xFFEEF2FF), Color(0xFFF8FAFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roleCardGradient = LinearGradient(
    colors: [Color(0xFFEEF2FF), Color(0xFFC7D2FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, Color(0xFFFFB74D)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Ombres ──────────────────────────────────────────────────────────────
  static Color shadowLight = textColor.withValues(alpha: 0.06);
  static Color shadowMedium = textColor.withValues(alpha: 0.10);
  static Color shadowPrimary = primaryColor.withValues(alpha: 0.18);

  static Color primaryTint(double opacity) =>
      primaryColor.withValues(alpha: opacity);
  static Color textTint(double opacity) => textColor.withValues(alpha: opacity);

  static Color statusBackground(Color status) => status.withValues(alpha: 0.12);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
            color: shadowLight, blurRadius: 16, offset: const Offset(0, 4)),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
            color: shadowMedium, blurRadius: 24, offset: const Offset(0, 8)),
      ];

  // ── Rayons & espacements ────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 24;
  static const double radiusFull = 40;

  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadius2xl => BorderRadius.circular(radius2xl);

  // ── ThemeData Material 3 ─────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: onPrimary,
      primaryContainer: inputFillColor,
      onPrimaryContainer: primaryDark,
      secondary: secondaryColor,
      onSecondary: onPrimary,
      secondaryContainer: borderColor,
      onSecondaryContainer: textColor,
      tertiary: accentColor,
      onTertiary: textColor,
      error: destructiveColor,
      onError: onPrimary,
      surface: surfaceColor,
      onSurface: textColor,
      onSurfaceVariant: textSecondary,
      outline: borderColor,
      outlineVariant: borderColor,
      shadow: shadowMedium,
      scrim: textColor.withValues(alpha: 0.32),
      inverseSurface: textColor,
      onInverseSurface: surfaceColor,
      inversePrimary: secondaryColor,
      surfaceTint: primaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      dividerColor: borderColor,
      splashColor: primaryTint(0.12),
      highlightColor: primaryTint(0.08),
      fontFamily: 'Roboto',
      // Pages appear instantly: no right-to-left slide on any platform.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: NoTransitionsBuilder(),
          TargetPlatform.iOS: NoTransitionsBuilder(),
          TargetPlatform.macOS: NoTransitionsBuilder(),
          TargetPlatform.windows: NoTransitionsBuilder(),
          TargetPlatform.linux: NoTransitionsBuilder(),
          TargetPlatform.fuchsia: NoTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
        bodySmall: TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: borderColor, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        errorStyle: const TextStyle(color: destructiveColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: destructiveColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: destructiveColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderColor, width: 0.5),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inputFillColor,
        selectedColor: primaryColor,
        disabledColor: inputFillColor,
        labelStyle: const TextStyle(color: textColor),
        secondaryLabelStyle: const TextStyle(color: onPrimary),
        checkmarkColor: onPrimary,
        side: const BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        titleTextStyle: const TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textColor,
        contentTextStyle: const TextStyle(color: onPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(color: borderColor, thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textColor,
        textColor: textColor,
      ),
      iconTheme: const IconThemeData(color: textSecondary),
    );
  }
}

/// Page transition that shows the new page immediately, without animation.
class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}
