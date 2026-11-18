import 'package:flutter/material.dart';

/// App theme for Agri Mitra tailored for small and marginal farmers.
/// Features high-contrast colors, large touch targets, legible fonts (NotoSans),
/// and bold visual hierarchies optimized for low-literacy users.
class AppTheme {
  AppTheme._();

  // Color Palette
  static const Color primaryGreen = Color(0xFF2E7D32); // ICAR Green
  static const Color primaryGreenDark = Color(0xFF1B5E20);
  static const Color primaryGreenLight = Color(0xFF81C784);

  static const Color accentAmber = Color(0xFFF9A825); // Harvest Amber
  static const Color accentAmberLight = Color(0xFFFFF59D);
  static const Color accentAmberDark = Color(0xFFF57F17);

  static const Color backgroundLight = Color(0xFFF4F7F4);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1B2E1D);
  static const Color textMedium = Color(0xFF424242);
  static const Color textLight = Color(0xFF757575);

  // Status & Confidence Colors
  static const Color statusHighConfidence = Color(0xFF2E7D32); // Green
  static const Color statusMediumConfidence = Color(0xFFE65100); // Deep Orange / Amber
  static const Color statusLowConfidence = Color(0xFFC62828); // Red
  static const Color statusQueued = Color(0xFF0277BD); // Blue
  static const Color statusCloud = Color(0xFF6A1B9A); // Purple

  // Font Family
  static const String fontFamily = 'NotoSans';

  /// Text Theme specifying required farmer-friendly text sizes:
  /// Heading = 28, Title = 22, Body = 18.
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: textDark,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28.0, // Heading = 28
      fontWeight: FontWeight.bold,
      color: textDark,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24.0,
      fontWeight: FontWeight.w700,
      color: textDark,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22.0, // Title = 22
      fontWeight: FontWeight.w600,
      color: textDark,
      letterSpacing: 0.1,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      color: textDark,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18.0, // Body = 18
      fontWeight: FontWeight.normal,
      color: textDark,
      height: 1.45,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
      color: textMedium,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      color: surfaceWhite,
    ),
  );

  /// Complete Light ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryGreen,
        onPrimary: surfaceWhite,
        secondary: accentAmber,
        onSecondary: textDark,
        error: statusLowConfidence,
        onError: surfaceWhite,
        surface: surfaceWhite,
        onSurface: textDark,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: surfaceWhite,
        elevation: 2.0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: surfaceWhite,
        ),
        iconTheme: IconThemeData(color: surfaceWhite, size: 28.0),
      ),

      // Card Theme with prominent elevation and rounded edges for low-literacy users
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 3.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),

      // Large Touch-Target Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: surfaceWhite,
          minimumSize: const Size(64.0, 48.0),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          elevation: 3.0,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size(64.0, 48.0),
          side: const BorderSide(color: primaryGreen, width: 2.0),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentAmber,
        foregroundColor: textDark,
        elevation: 5.0,
        iconSize: 32.0,
        shape: CircleBorder(),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: const BorderSide(color: Color(0xFFC8E6C9), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: const BorderSide(color: Color(0xFFC8E6C9), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: const BorderSide(color: primaryGreen, width: 2.5),
        ),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 18.0,
          color: textLight,
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 18.0,
          color: primaryGreenDark,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE8F5E9),
        disabledColor: Colors.grey.shade200,
        selectedColor: primaryGreenLight,
        secondarySelectedColor: accentAmber,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: primaryGreenDark,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1.2,
        space: 24.0,
      ),

      textTheme: textTheme,
    );
  }
}
