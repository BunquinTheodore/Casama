import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../constants/dimensions.dart';

class CasamaTheme {
  static ThemeData get lightTheme {
    final baseText = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: CasamaColors.warmCream,
      colorScheme: const ColorScheme.light(
        primary: CasamaColors.primaryCoral,
        secondary: CasamaColors.deepTeal,
        surface: CasamaColors.warmCream,
        error: CasamaColors.errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: CasamaColors.ink,
      ),
      textTheme: baseText.copyWith(
        displayLarge: baseText.displayLarge?.copyWith(
          color: CasamaColors.ink,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          color: CasamaColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          color: CasamaColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          color: CasamaColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(
          color: CasamaColors.ink,
          fontSize: 15,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          color: CasamaColors.textSecondary,
          fontSize: 14,
        ),
        bodySmall: baseText.bodySmall?.copyWith(
          color: CasamaColors.textSecondary,
          fontSize: 12,
        ),
        labelLarge: baseText.labelLarge?.copyWith(
          color: CasamaColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: CasamaColors.ink),
        titleTextStyle: TextStyle(
          color: CasamaColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: CasamaColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: CasamaSpacing.roundedLg,
          side: const BorderSide(color: CasamaColors.borderGray, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CasamaColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: CasamaSpacing.roundedMd,
          borderSide: const BorderSide(
            color: CasamaColors.borderGray,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: CasamaSpacing.roundedMd,
          borderSide: const BorderSide(
            color: CasamaColors.borderGray,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: CasamaSpacing.roundedMd,
          borderSide: const BorderSide(
            color: CasamaColors.primaryCoral,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: CasamaSpacing.roundedMd,
          borderSide: const BorderSide(
            color: CasamaColors.errorRed,
            width: 1.5,
          ),
        ),
        hintStyle: const TextStyle(color: CasamaColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(
          color: CasamaColors.textSecondary,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CasamaColors.primaryCoral,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: CasamaSpacing.roundedMd),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CasamaColors.ink,
          side: const BorderSide(color: CasamaColors.borderGray, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: CasamaSpacing.roundedMd),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseText = GoogleFonts.interTextTheme();
    const darkBg = CasamaColors.darkBackground;
    const darkSurface = CasamaColors.darkSurface;
    const darkBorder = CasamaColors.darkBorder;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: CasamaColors.primaryCoral,
        secondary: CasamaColors.dustyBlue,
        surface: darkSurface,
        error: Color(0xFFE57373),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: baseText.copyWith(
        displayLarge: baseText.displayLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(
          color: Colors.white,
          fontSize: 15,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          color: CasamaColors.ivory,
          fontSize: 14,
        ),
        bodySmall: baseText.bodySmall?.copyWith(
          color: CasamaColors.ivory,
          fontSize: 12,
        ),
        labelLarge: baseText.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: CasamaSpacing.roundedLg,
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: CasamaSpacing.roundedMd,
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: CasamaSpacing.roundedMd,
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: CasamaSpacing.roundedMd,
          borderSide: const BorderSide(
            color: CasamaColors.primaryCoral,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: CasamaSpacing.roundedMd,
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.5),
        ),
        hintStyle: const TextStyle(color: CasamaColors.ivory, fontSize: 14),
        labelStyle: const TextStyle(color: CasamaColors.ivory, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CasamaColors.primaryCoral,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: CasamaSpacing.roundedMd),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: darkBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: CasamaSpacing.roundedMd),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
