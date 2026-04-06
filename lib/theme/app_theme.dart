// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary         = Color(0xFFB8860B);
  static const Color primaryLight    = Color(0xFFD4A017);
  static const Color background      = Color(0xFF1A1512);
  static const Color card            = Color(0xFF221E1A);
  static const Color cardLight       = Color(0xFF2A2520);
  static const Color surface         = Color(0xFF2E2924);
  static const Color border          = Color(0xFF3A3530);
  static const Color foreground      = Color(0xFFEDE4D4);
  static const Color mutedForeground = Color(0xFF8A7A6A);
  static const Color success         = Color(0xFF4CAF50);
  static const Color destructive     = Color(0xFFE53935);
  static const Color accent          = Color(0xFFD4A017);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryLight,
        surface: card,
        error: destructive,
        onPrimary: Colors.white,
        onSurface: foreground,
        onError: Colors.white,
      ),
      // Use google_fonts — no local font files needed
      textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge:  GoogleFonts.playfairDisplay(color: foreground),
        displayMedium: GoogleFonts.playfairDisplay(color: foreground),
        displaySmall:  GoogleFonts.playfairDisplay(color: foreground),
        headlineLarge: GoogleFonts.playfairDisplay(color: foreground),
        headlineMedium:GoogleFonts.playfairDisplay(color: foreground),
        headlineSmall: GoogleFonts.playfairDisplay(color: foreground),
        titleLarge:    GoogleFonts.playfairDisplay(color: foreground),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.bold, color: foreground),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border.withValues(alpha: 0.5)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.lato(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
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
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: TextStyle(color: mutedForeground),
        hintStyle:  TextStyle(color: mutedForeground),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary,
        labelStyle: TextStyle(color: mutedForeground),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primary : mutedForeground),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? primary.withValues(alpha: 0.4) : surface),
      ),
    );
  }
}
