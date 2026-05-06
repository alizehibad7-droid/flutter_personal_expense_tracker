import 'package:flutter/material.dart';

class AppTheme {
  // ─── Colors ───────────────────────────────────────────────────────────────
  static const Color primary     = Color(0xFF6C63FF);
  static const Color incomeGreen = Color(0xFF06D6A0);
  static const Color expenseRed  = Color(0xFFFF6B6B);
  static const Color bgDark      = Color(0xFF0F0F1A);
  static const Color surface     = Color(0xFF1A1A2E);
  static const Color card        = Color(0xFF22223B);
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecond  = Color(0xFF8E8EA0);
  static const Color divider     = Color(0xFF2E2E4A);

  // ─── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      surface: surface,
      onPrimary: Colors.white,
      onSurface: textPrimary,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: expenseRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: expenseRed, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecond),
      hintStyle: const TextStyle(color: textSecond),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
  );
}