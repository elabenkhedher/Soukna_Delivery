import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

/// Palette de couleurs fidèle à l'application Livreur Dokan Delivery.
/// Couleurs d'origine 100% préservées.
class AppColors {
  AppColors._();

  // ── Palette claire ─────────────────────────────────────────
  static const Color primary = Color(0xFF1F7A7A);
  static const Color primaryDark = Color(0xFF155B5E);
  static const Color primarySoft = Color(0xFFE3F1F0);
  static const Color primaryMid = Color(0xFF2A9494);

  static const Color accent = Color(0xFFF2A65A);
  static const Color accentSoft = Color(0xFFFDEFDD);

  static const Color text = Color(0xFF1E2B2F);
  static const Color mutedText = Color(0xFF5B6B70);
  static const Color hintText = Color(0xFF8A979B);
  static const Color border = Color(0xFFE4E1DA);
  static const Color background = Color(0xFFF7F5F0);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFEFEDE8);

  static const Color error = Color(0xFFD64545);
  static const Color errorSoft = Color(0xFFFCE8E8);
  static const Color success = Color(0xFF2E9E6B);
  static const Color successSoft = Color(0xFFE8F6EF);
  static const Color warning = Color(0xFF9A5B14);
  static const Color warningSoft = Color(0xFFFAF0E6);

  // ── Palette sombre ─────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F1A1A);
  static const Color darkSurface = Color(0xFF1A2626);
  static const Color darkSurfaceAlt = Color(0xFF222E2E);
  static const Color darkBorder = Color(0xFF2E3D3D);
  static const Color darkText = Color(0xFFE8F0F0);
  static const Color darkMuted = Color(0xFF8AABAB);
}

/// Constantes de rayons de courbure ergonomiques (Capsules & Cartes modernes).
class AppRadius {
  AppRadius._();

  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 22.0;
  static const double xl = 28.0;
  static const double pill = 100.0;
}

/// Durées pour les animations et micro-interactions 60fps.
class AppDurations {
  AppDurations._();

  static const Duration micro = Duration(milliseconds: 100);
  static const Duration quick = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration hero = Duration(milliseconds: 650);
  static const Duration pageTransition = Duration(milliseconds: 350);
}

/// Courbes d'animation fluides et dynamiques.
class AppCurves {
  AppCurves._();

  static const Curve spring = Curves.easeOutBack;
  static const Curve smooth = Curves.easeOutCubic;
  static const Curve heroCurve = Curves.easeInOutCubicEmphasized;
}

/// Ombres douces et diffuses pour un aspect tactile premium.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft({Color? color}) => [
        BoxShadow(
          color: (color ?? Colors.black).withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> card({Color? color}) => [
        BoxShadow(
          color: (color ?? Colors.black).withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> primary({Color? color}) => [
        BoxShadow(
          color: (color ?? AppColors.primary).withValues(alpha: 0.28),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  static const _primary = AppColors.primary;
  static const _primaryDark = AppColors.primaryDark;
  static const _primarySoft = AppColors.primarySoft;
  static const _primaryMid = AppColors.primaryMid;
  static const _accent = AppColors.accent;
  static const _accentSoft = AppColors.accentSoft;
  static const _text = AppColors.text;
  static const _mutedText = AppColors.mutedText;
  static const _hintText = AppColors.hintText;
  static const _border = AppColors.border;
  static const _background = AppColors.background;
  static const _surfaceAlt = AppColors.surfaceAlt;
  static const _error = AppColors.error;

  static const _darkBackground = AppColors.darkBackground;
  static const _darkSurface = AppColors.darkSurface;
  static const _darkSurfaceAlt = AppColors.darkSurfaceAlt;
  static const _darkBorder = AppColors.darkBorder;
  static const _darkText = AppColors.darkText;
  static const _darkMuted = AppColors.darkMuted;

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: brightness,
    ).copyWith(
      primary: _primary,
      onPrimary: Colors.white,
      primaryContainer: isDark ? const Color(0xFF1A3535) : _primarySoft,
      onPrimaryContainer: isDark ? const Color(0xFF9ADADA) : _primaryDark,
      secondary: _accent,
      onSecondary: const Color(0xFF3D2A14),
      secondaryContainer: isDark ? const Color(0xFF3D2A14) : _accentSoft,
      onSecondaryContainer:
          isDark ? const Color(0xFFFFD9B0) : const Color(0xFF3D2A14),
      surface: isDark ? _darkSurface : Colors.white,
      onSurface: isDark ? _darkText : _text,
      surfaceContainerHighest: isDark ? _darkSurfaceAlt : _surfaceAlt,
      error: _error,
      outline: isDark ? _darkBorder : _border,
    );

    final scaffoldBg = isDark ? _darkBackground : _background;
    final cardColor = isDark ? _darkSurface : Colors.white;
    final borderColor = isDark ? _darkBorder : _border;
    final textColor = isDark ? _darkText : _text;
    final mutedColor = isDark ? _darkMuted : _mutedText;
    final hintColor = isDark ? const Color(0xFF5A7070) : _hintText;
    final inputFill = isDark ? _darkSurfaceAlt : Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      visualDensity: VisualDensity.standard,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textColor,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textColor,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        titleMedium: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: mutedColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: textColor, fontSize: 15, height: 1.5),
        bodyMedium: TextStyle(color: textColor, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(color: mutedColor, fontSize: 12, height: 1.4),
        labelLarge: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          color: mutedColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: hintColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? _darkSurface : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textColor, size: 24),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: borderColor.withValues(alpha: 0.6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: TextStyle(color: hintColor, fontSize: 14),
        labelStyle: TextStyle(color: mutedColor, fontSize: 14),
        floatingLabelStyle: TextStyle(
          color: _primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: mutedColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: _error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: _error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 54),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primary.withValues(alpha: 0.5),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: _primary, width: 1.5),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? _darkSurface : Colors.white,
        indicatorColor: isDark ? const Color(0xFF1A3535) : _primarySoft,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? (isDark ? const Color(0xFF9ADADA) : _primaryDark)
                : mutedColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? _primary
                : mutedColor,
            size: 23,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF2A3A3A) : const Color(0xFF1E2B2F),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(
        color: borderColor.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? _darkSurfaceAlt : _surfaceAlt,
        selectedColor: _primarySoft,
        labelStyle: TextStyle(color: textColor, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        side: BorderSide(color: borderColor.withValues(alpha: 0.5)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? _darkMuted : _mutedText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primary;
          return isDark ? _darkBorder : _border;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primary,
        linearTrackColor: _primarySoft,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ── Gradient helpers ──────────────────────────────────────
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primary, _primaryMid],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_primary, _primaryDark],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_accent, Color(0xFFE08540)],
  );
}
