import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════
/// SpeakWise Strict Design System Tokens
/// ═══════════════════════════════════════════════════════════════
class AppTheme {
  // 1. Core Background & Scaffold Tokens
  static const Color bgDark = Color(0xFF060501); // Deep obsidian warm-black
  static const Color surfaceDark = Color(0xFF12130E); // Elevated dark container
  static const Color surfaceBorder = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color surfaceBorderActive = Color(0x33AAD900); // Subtle active lime border

  // 2. Primary Accent & Button Tokens
  static const Color primaryAccent = Color(0xFFAAD900); // Electric neon acid-lime
  static const Color primaryGlow = Color(0x33AAD900); // 20% opacity lime glow
  static const Color buttonDark = Color(0xFF1A1D13); // Secondary dark button / inactive chip
  static const Color buttonLight = Color(0xFFFFFFFF); // High-contrast crisp white pill
  static const Color buttonLightPressed = Color(0xFFE2E2DC);

  // 3. Typography & Contrast Tokens
  static const Color textPrimary = Color(0xFFFFFFFF); // Headlines, titles, active labels
  static const Color textMuted = Color(0xFF9B9C94); // Subtitles, metadata, timestamps
  static const Color textOnPrimary = Color(0xFF060501); // Bold dark text for WCAG AAA contrast
  static const Color textOnDark = Color(0xFFFFFFFF);

  // 4. Auxiliary & Status Tokens
  static const Color starGold = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFFF4D4D);
  static const Color successGreen = Color(0xFF00E575);

  // 5. Radii & Geometry
  static const double radiusCard = 20.0;
  static const double radiusCardLarge = 24.0;
  static const double radiusPill = 50.0;

  // 6. Typography Tokens (Visby CF with geometric round fallbacks)
  static const String fontFamily = 'Visby CF';
  static const List<String> fontFallbacks = ['Plus Jakarta Sans', 'Inter', 'sans-serif'];

  /// Unified typography helper that applies Visby CF with graceful fallbacks
  static TextStyle font({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    TextOverflow? overflow,
  }) {
    return GoogleFonts.plusJakartaSans(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    ).copyWith(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallbacks,
      overflow: overflow,
    );
  }

  /// Global Dark Theme Data
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).apply(
      fontFamily: fontFamily,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallbacks,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryAccent,
      canvasColor: surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        onPrimary: textOnPrimary,
        surface: surfaceDark,
        onSurface: textPrimary,
        error: errorRed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: font(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: font(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.15,
        ),
        displayMedium: font(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          height: 1.2,
        ),
        titleLarge: font(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleMedium: font(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        bodyLarge: font(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodyMedium: font(
          color: textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        labelLarge: font(
          color: textOnPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// BuildContext Semantic Palette Extension
/// ═══════════════════════════════════════════════════════════════
extension AppColors on BuildContext {
  Color get appBg => AppTheme.bgDark;
  Color get appSurface => AppTheme.surfaceDark;
  Color get appBorder => AppTheme.surfaceBorder;
  Color get appBorderActive => AppTheme.surfaceBorderActive;

  Color get primaryAccent => AppTheme.primaryAccent;
  Color get primaryGlow => AppTheme.primaryGlow;
  Color get buttonDark => AppTheme.buttonDark;
  Color get buttonLight => AppTheme.buttonLight;

  Color get textPrimary => AppTheme.textPrimary;
  Color get textMuted => AppTheme.textMuted;
  Color get textOnPrimary => AppTheme.textOnPrimary;

  Color get starGold => AppTheme.starGold;
  Color get successGreen => AppTheme.successGreen;
  Color get errorRed => AppTheme.errorRed;

  TextTheme get textTheme => Theme.of(this).textTheme;
  Size get screenSize => MediaQuery.sizeOf(this);
}
