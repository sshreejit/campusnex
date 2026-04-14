import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData buildTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.charcoalSteel,
      primary: AppColors.charcoalSteel,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,

      // Squeezes the entire app's component spacing
      visualDensity: VisualDensity.compact,

      // --- TYPOGRAPHY (Squeezed sizes) ---
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        displayMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        headlineLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineSmall: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
        bodySmall: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        labelLarge: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),

      // --- APP BAR (Remains Bold & Heavy) ---
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.charcoalSteel,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 50, // Squeezed height from 56
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16, // Squeezed from 18
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 20),
      ),

      // --- BUTTONS (Lower Height) ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.charcoalSteel,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44), // Squeezed from 54
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Sharper for SaaS feel
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.charcoalSteel,
          minimumSize: const Size(double.infinity, 44), // Squeezed from 54
          side: const BorderSide(color: AppColors.charcoalSteel, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // --- INPUT FIELDS (Compact & Dense) ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true, // IMPORTANT: Reduces height significantly
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Reduced padding
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.charcoalSteel, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 13),
      ),

      // --- CARDS (Tightened margins) ---
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Smaller radius for compact look
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // --- LIST TILES (Ensures lists are compact) ---
      listTileTheme: const ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        visualDensity: VisualDensity.compact,
      ),

      // --- CHIPS ---
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.charcoalSteel),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide.none,
      ),
    );
  }
}