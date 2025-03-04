import 'package:flutter/cupertino.dart';

class AppTheme {
  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // Colors - Modern Professional Theme
  static const Color primary = Color(0xFF007AFF); // iOS Blue
  static const Color secondary = Color(0xFF5856D6); // Rich Purple
  static const Color accent = Color(0xFF34C759); // Success Green
  static const Color tertiary = Color(0xFFFF2D55); // Vibrant Pink
  static const Color neutral = Color(0xFF8E8E93); // Neutral Gray
  
  // Legacy Colors - For Backward Compatibility
  static const Color primaryNeon = Color(0xFF00FF9C); // Bright neon green
  static const Color primaryBlue = Color(0xFF0066FF); // Bright blue
  static const Color primaryTeal = Color(0xFF00F0FF); // Cyan
  static const Color primaryLavender = Color(0xFF8E8EF3); // Custom lavender
  static const Color primaryPink = Color(0xFFFF00FF); // Neon pink
  
  // Background Colors
  static const Color backgroundDark = Color(0xFF000000); // True Black
  static const Color surfaceDark = Color(0xFF1C1C1E); // Dark Surface
  static const Color backgroundLight = CupertinoColors.systemBackground;
  static const Color surfaceLight = CupertinoColors.secondarySystemBackground;
  
  // Text Colors
  static const Color textPrimary = CupertinoColors.label;
  static const Color textSecondary = CupertinoColors.secondaryLabel;
  static const Color textAccent = primary;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 28.0;

  // Shadows - Refined
  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: CupertinoColors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: CupertinoColors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  // Legacy Neon Shadow
  static List<BoxShadow> neonShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.5),
      blurRadius: 10,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: color.withOpacity(0.2),
      blurRadius: 20,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: CupertinoColors.black.withOpacity(0.06),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: CupertinoColors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Text Styles - Modern & Clean
  static TextStyle get headingLarge => const TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
    color: textPrimary,
  );

  static TextStyle get headingMedium => const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.34,
    color: textPrimary,
  );

  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    color: textPrimary,
    height: 1.3,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
    color: textPrimary,
    height: 1.3,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    color: textPrimary,
  );

  static TextStyle get buttonText => const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    color: CupertinoColors.white,
  );

  // Theme Data
  static CupertinoThemeData get theme => const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryNeon,
    primaryContrastingColor: CupertinoColors.white,
    scaffoldBackgroundColor: backgroundDark,
    barBackgroundColor: surfaceDark,
    textTheme: CupertinoTextThemeData(
      primaryColor: primaryNeon,
      textStyle: TextStyle(
        fontSize: 17,
        color: CupertinoColors.white,
        letterSpacing: -0.41,
        height: 1.3,
      ),
      actionTextStyle: TextStyle(
        fontSize: 17,
        color: primaryNeon,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.41,
      ),
      navTitleTextStyle: TextStyle(
        fontSize: 17,
        color: CupertinoColors.white,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.41,
      ),
      navLargeTitleTextStyle: TextStyle(
        fontSize: 34,
        color: CupertinoColors.white,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.37,
      ),
      navActionTextStyle: TextStyle(
        fontSize: 17,
        color: primaryNeon,
        letterSpacing: -0.41,
      ),
      pickerTextStyle: TextStyle(
        fontSize: 21,
        color: CupertinoColors.white,
        letterSpacing: -0.41,
      ),
      dateTimePickerTextStyle: TextStyle(
        fontSize: 21,
        color: CupertinoColors.white,
        letterSpacing: -0.41,
      ),
      tabLabelTextStyle: TextStyle(
        fontSize: 10,
        color: CupertinoColors.white,
        letterSpacing: -0.24,
      ),
    ),
  );
} 